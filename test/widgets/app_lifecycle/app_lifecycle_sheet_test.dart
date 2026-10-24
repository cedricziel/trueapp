import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/providers/app_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/widgets/app_lifecycle/app_lifecycle_sheet.dart';

import '../../helpers/app_fixtures.dart';
import '../../helpers/fake_app_provider.dart';
import '../../helpers/pump_helpers.dart';
import '../../helpers/test_database.dart';
import '../../helpers/test_providers.dart';

const _upgradable = AppUpgradeInfo(
  upgradeAvailable: true,
  availableVersion: '2.0.0',
  currentVersion: '1.0.0',
  canUpgrade: true,
);

void main() {
  late AppDatabase database;
  late UnifiedServerService serverService;
  late FakeAppProvider provider;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();
    database = createTestDatabase();
    serverService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    provider = FakeAppProvider(
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

  Future<void> openSheet(WidgetTester tester, App app) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>.value(
        value: provider,
        child: CupertinoApp(
          home: Builder(
            builder: (context) => CupertinoButton(
              onPressed: () => showAppLifecycleSheet(context, app),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settleRouteTransition(tester);
  }

  Future<void> tapSheetAction(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await settleRouteTransition(tester);
  }

  Set<String> offeredActions() => {
    for (final label in ['Start', 'Stop', 'Restart', 'Upgrade'])
      if (find.text(label).evaluate().isNotEmpty) label,
  };

  group('available actions', () {
    final expectations = <AppState, Set<String>>{
      AppState.running: {'Stop', 'Restart'},
      AppState.deploying: {'Stop'},
      AppState.stopped: {'Start'},
      AppState.crashed: {'Start', 'Stop'},
    };

    for (final entry in expectations.entries) {
      testWidgets('offers ${entry.value} for a ${entry.key.name} app', (
        tester,
      ) async {
        await openSheet(tester, buildTestApp(state: entry.key));

        expect(offeredActions(), entry.value);
      });
    }

    for (final state in [AppState.stopping, AppState.unknown]) {
      testWidgets('opens no sheet for a ${state.name} app', (tester) async {
        await openSheet(tester, buildTestApp(state: state));

        expect(find.text('Cancel'), findsNothing);
      });
    }

    testWidgets('opens no sheet for a catalog app', (tester) async {
      await openSheet(
        tester,
        buildTestApp(installed: false, state: AppState.running),
      );

      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('offers Upgrade when an upgrade is available', (tester) async {
      await openSheet(
        tester,
        buildTestApp(state: AppState.running, upgradeInfo: _upgradable),
      );

      expect(offeredActions(), {'Stop', 'Restart', 'Upgrade'});
    });

    testWidgets('hides Upgrade when the upgrade cannot be applied', (
      tester,
    ) async {
      await openSheet(
        tester,
        buildTestApp(
          state: AppState.running,
          upgradeInfo: const AppUpgradeInfo(
            upgradeAvailable: true,
            canUpgrade: false,
          ),
        ),
      );

      expect(offeredActions(), {'Stop', 'Restart'});
    });
  });

  group('running an action', () {
    testWidgets('Start runs immediately without a confirmation', (
      tester,
    ) async {
      await openSheet(tester, buildTestApp(state: AppState.stopped));

      await tapSheetAction(tester, 'Start');

      expect(provider.calls, ['start:plex']);
      expect(find.byType(CupertinoAlertDialog), findsNothing);
    });

    for (final (label, verb) in [('Stop', 'stop'), ('Restart', 'restart')]) {
      testWidgets('$label asks for confirmation and cancel does not call the '
          'provider', (tester) async {
        await openSheet(tester, buildTestApp(state: AppState.running));

        await tapSheetAction(tester, label);
        expect(find.text('$label plex?'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await settleRouteTransition(tester);

        expect(provider.calls, isEmpty);
        expect(find.byType(CupertinoAlertDialog), findsNothing);
      });

      testWidgets('$label calls the provider once confirmed', (tester) async {
        await openSheet(tester, buildTestApp(state: AppState.running));

        await tapSheetAction(tester, label);
        await tapSheetAction(tester, label);

        expect(provider.calls, ['$verb:plex']);
        expect(find.byType(CupertinoAlertDialog), findsNothing);
      });
    }

    testWidgets('shows progress while the request is in flight', (
      tester,
    ) async {
      provider.gate = Completer<void>();
      await openSheet(tester, buildTestApp(state: AppState.stopped));

      await tapSheetAction(tester, 'Start');

      expect(find.text('Starting plex...'), findsOneWidget);
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

      provider.gate!.complete();
      await settleRouteTransition(tester);

      expect(find.text('Starting plex...'), findsNothing);
    });

    testWidgets("reports a failure with a Couldn't <verb> <name> alert", (
      tester,
    ) async {
      provider.actionResult = false;
      await openSheet(tester, buildTestApp(state: AppState.running));

      await tapSheetAction(tester, 'Stop');
      await tapSheetAction(tester, 'Stop');

      expect(find.text("Couldn't stop plex"), findsOneWidget);
      expect(find.text('Stopping plex...'), findsNothing);

      await tester.tap(find.text('OK'));
      await settleRouteTransition(tester);
      expect(find.byType(CupertinoAlertDialog), findsNothing);
    });

    testWidgets('Upgrade opens the upgrade confirmation', (tester) async {
      await openSheet(
        tester,
        buildTestApp(state: AppState.running, upgradeInfo: _upgradable),
      );

      await tapSheetAction(tester, 'Upgrade');

      expect(find.text('Upgrade Plex Media Server'), findsOneWidget);
      expect(provider.calls, isEmpty);
    });
  });
}
