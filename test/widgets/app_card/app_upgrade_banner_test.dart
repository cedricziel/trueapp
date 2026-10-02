import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/providers/app_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/widgets/app_card/app_upgrade_banner.dart';

import '../../helpers/test_database.dart';
import '../../helpers/test_providers.dart';

class _GatedUpgradeAppProvider extends AppProvider {
  _GatedUpgradeAppProvider({
    required super.daoSource,
    required super.serverService,
  }) : super(clientManager: TestProviders.mockApiClientManager);

  final upgrade = Completer<bool>();
  final reload = Completer<void>();
  final showBanner = ValueNotifier<bool>(true);
  bool reloadsAfterUpgrade = false;

  @override
  Future<bool> upgradeApp(String appName, {String? version}) async {
    final success = await upgrade.future;
    if (reloadsAfterUpgrade) {
      showBanner.value = false;
      await reload.future;
    }
    return success;
  }
}

App _upgradableApp() => App(
  name: 'plex',
  title: 'Plex',
  description: 'Media server',
  installed: true,
  healthy: true,
  latestVersion: '2.0.0',
  latestAppVersion: '2.0.0',
  latestHumanVersion: '2.0.0',
  categories: const [],
  tags: const [],
  screenshots: const [],
  sources: const [],
  maintainers: const [],
  recommended: false,
  catalog: 'community',
  train: 'stable',
  usedPorts: const [],
  portals: const {},
  upgradeInfo: const AppUpgradeInfo(
    upgradeAvailable: true,
    availableVersion: '2.0.0',
    currentVersion: '1.0.0',
    canUpgrade: true,
  ),
);

void main() {
  late AppDatabase database;
  late UnifiedServerService serverService;
  late _GatedUpgradeAppProvider provider;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();
    database = createTestDatabase();
    serverService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    provider = _GatedUpgradeAppProvider(
      daoSource: database,
      serverService: serverService,
    );
  });

  tearDown(() async {
    await TestProviders.disposeTestStack(
      providers: [provider],
      service: serverService,
      database: database,
    );
  });

  Future<void> startUpgrade(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: CupertinoApp(
          home: CupertinoPageScaffold(
            child: ValueListenableBuilder<bool>(
              valueListenable: provider.showBanner,
              builder: (context, show, _) => show
                  ? AppUpgradeBanner(app: _upgradableApp())
                  : const SizedBox(),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Upgrade'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upgrade').last);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Upgrading...'), findsOneWidget);
  }

  testWidgets('closes the progress dialog and reports the upgrade result', (
    tester,
  ) async {
    await startUpgrade(tester);

    provider.upgrade.complete(true);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Upgrading...'), findsNothing);
    expect(find.text('Success'), findsOneWidget);
  });

  testWidgets('closes the progress dialog when the reload removes the banner', (
    tester,
  ) async {
    provider.reloadsAfterUpgrade = true;
    await startUpgrade(tester);

    provider.upgrade.complete(true);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(find.byType(AppUpgradeBanner), findsNothing);

    provider.reload.complete();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Upgrading...'), findsNothing);
    expect(find.text('Success'), findsOneWidget);
  });
}
