import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/screens/home_screen.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_providers.dart';

/// Coverage for ticket: proper loading and empty states on HomeScreen.
void main() {
  late AppDatabase database;
  late UnifiedServerService unifiedServerService;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    unifiedServerService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
  });

  tearDown(() async {
    await TestProviders.disposeTestStack(
      service: unifiedServerService,
      database: database,
    );
  });

  testWidgets('shows a loading indicator while servers are being fetched', (
    WidgetTester tester,
  ) async {
    final loadingProvider = _AlwaysLoadingServerProvider(unifiedServerService);
    addTearDown(loadingProvider.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerProvider>.value(value: loadingProvider),
        ],
        child: const CupertinoApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    expect(find.text('No servers added yet'), findsNothing);
  });

  testWidgets('shows the empty state once loading finishes with no servers', (
    WidgetTester tester,
  ) async {
    final serverProvider = ServerProvider(unifiedServerService);
    addTearDown(serverProvider.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerProvider>.value(value: serverProvider),
        ],
        child: const CupertinoApp(home: HomeScreen()),
      ),
    );
    await pumpUntilAsync(
      tester,
      () => find.text('No servers added yet').evaluate().isNotEmpty,
    );

    expect(find.text('No servers added yet'), findsOneWidget);
    expect(find.text('Tap + to add your first TrueNAS server'), findsOneWidget);
    expect(find.byType(CupertinoActivityIndicator), findsNothing);
  });
}

/// A [ServerProvider] whose [isLoadingServers] is pinned to `true`, so a
/// widget test can render `HomeScreen`'s loading branch deterministically
/// instead of racing the real async server load.
class _AlwaysLoadingServerProvider extends ServerProvider {
  _AlwaysLoadingServerProvider(super.service);

  @override
  bool get isLoadingServers => true;
}
