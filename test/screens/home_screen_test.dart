import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/fleet_server_status.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/fleet_status_provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/screens/home_screen.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/layout_assertions.dart';
import '../helpers/provider_scope.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_providers.dart';
import '../helpers/test_surfaces.dart';

/// Coverage for ticket: proper loading and empty states on HomeScreen, and
/// for fleet-aware sorting/banner behavior.
void main() {
  late AppDatabase database;
  late ServerProvider serverProvider;
  late FleetStatusProvider fleetStatusProvider;
  late UnifiedServerService unifiedServerService;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    unifiedServerService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    serverProvider = ServerProvider(unifiedServerService);
    // HomeScreen kicks off its own real refreshAll() on mount; against the
    // mock API client manager that resolves every server to "offline",
    // racing whatever this test seeds directly. Overriding it to a no-op
    // makes debugSetStatus the only writer.
    fleetStatusProvider = _FakeFleetStatusProvider(unifiedServerService);

    // Two servers - not one - so ServerProvider's single-server
    // auto-navigation never fires and this test never needs a real router.
    await serverProvider.addServer(
      NasServer.create(
        name: 'vault.local',
        host: 'vault.local',
        port: 443,
        username: 'admin',
        password: 'password',
      ),
      'password',
    );
    await serverProvider.addServer(
      NasServer.create(
        name: 'backup-nas.local',
        host: 'backup-nas.local',
        port: 443,
        username: 'admin',
        password: 'password',
      ),
      'password',
    );
  });

  tearDown(() async {
    await TestProviders.disposeTestStack(
      providers: [serverProvider, fleetStatusProvider],
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
          ChangeNotifierProvider<FleetStatusProvider>.value(
            value: fleetStatusProvider,
          ),
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
    final emptyServerProvider = ServerProvider(unifiedServerService);
    addTearDown(emptyServerProvider.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerProvider>.value(
            value: emptyServerProvider,
          ),
          ChangeNotifierProvider<FleetStatusProvider>.value(
            value: fleetStatusProvider,
          ),
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

  Widget createTestApp() {
    return provideAppProviders(
      database: database,
      service: unifiedServerService,
      serverProvider: serverProvider,
      fleetStatusProvider: fleetStatusProvider,
      child: const CupertinoApp(home: HomeScreen()),
    );
  }

  testWidgets('lists both servers with no fleet banner by default', (
    WidgetTester tester,
  ) async {
    useCompactSurface(tester);
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    expectNoLayoutOverflow(tester);
    expect(find.text('vault.local'), findsOneWidget);
    expect(find.text('backup-nas.local'), findsOneWidget);
    expect(find.textContaining('needs attention'), findsNothing);
  });

  testWidgets(
    'sorts a server needing attention first and shows a fleet banner',
    (WidgetTester tester) async {
      useCompactSurface(tester);
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final backupServerId = serverProvider.servers
          .firstWhere((server) => server.name == 'backup-nas.local')
          .id;
      fleetStatusProvider.debugSetStatus(
        FleetServerStatus(
          serverId: backupServerId,
          connectivity: FleetServerConnectivity.offline,
        ),
      );
      await tester.pump();

      expectNoLayoutOverflow(tester);
      expect(find.text('backup-nas.local needs attention'), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);

      // The server needing attention is sorted first in the list.
      final vaultY = tester.getTopLeft(find.text('vault.local')).dy;
      final backupY = tester.getTopLeft(find.text('backup-nas.local')).dy;
      expect(backupY, lessThan(vaultY));
    },
  );
}

/// A [ServerProvider] whose [isLoadingServers] is pinned to `true`, so a
/// widget test can render `HomeScreen`'s loading branch deterministically
/// instead of racing the real async server load.
class _AlwaysLoadingServerProvider extends ServerProvider {
  _AlwaysLoadingServerProvider(super.service);

  @override
  bool get isLoadingServers => true;
}

/// A [FleetStatusProvider] whose [refreshAll] is a no-op, so a test's own
/// [FleetStatusProvider.debugSetStatus] calls are the only writer -
/// `HomeScreen` otherwise kicks off a real (mocked-null) refresh on mount
/// that would race a test's seeded status.
class _FakeFleetStatusProvider extends FleetStatusProvider {
  _FakeFleetStatusProvider(super.service);

  @override
  Future<void> refreshAll(
    List<NasServer> servers, {
    Duration timeout = FleetStatusProvider.defaultTimeout,
  }) async {}
}
