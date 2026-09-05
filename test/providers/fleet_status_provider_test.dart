import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/fleet_server_status.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/fleet_status_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/fake_api_client.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';

void main() {
  late AppDatabase database;
  late UnifiedServerService service;
  late FleetStatusProvider provider;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();
    database = createTestDatabase();
    service = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    provider = FleetStatusProvider(service);
  });

  tearDown(() async {
    await TestProviders.disposeTestStack(
      providers: [provider],
      service: service,
      database: database,
    );
  });

  group('FleetStatusProvider', () {
    test('returns an unknown-connectivity status for an unseen server', () {
      final status = provider.statusFor('server-1');

      expect(status.connectivity, FleetServerConnectivity.unknown);
      expect(status.needsAttention, isFalse);
    });

    test('debugSetStatus seeds a status and notifies listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.debugSetStatus(
        const FleetServerStatus(
          serverId: 'server-1',
          connectivity: FleetServerConnectivity.online,
          cpuUsage: 42,
          storageUsage: 60,
        ),
      );

      expect(notified, isTrue);
      final status = provider.statusFor('server-1');
      expect(status.connectivity, FleetServerConnectivity.online);
      expect(status.cpuUsage, 42);
      expect(status.needsAttention, isFalse);
    });
  });

  group('FleetServerStatus.needsAttention', () {
    test('is true when offline', () {
      const status = FleetServerStatus(
        serverId: 's',
        connectivity: FleetServerConnectivity.offline,
      );
      expect(status.needsAttention, isTrue);
    });

    test('is true when online but with active alerts', () {
      const status = FleetServerStatus(
        serverId: 's',
        connectivity: FleetServerConnectivity.online,
        activeAlertCount: 2,
      );
      expect(status.needsAttention, isTrue);
    });

    test('is false when online with no active alerts', () {
      const status = FleetServerStatus(
        serverId: 's',
        connectivity: FleetServerConnectivity.online,
        activeAlertCount: 0,
      );
      expect(status.needsAttention, isFalse);
    });

    test('is false while unknown or loading', () {
      expect(const FleetServerStatus(serverId: 's').needsAttention, isFalse);
      expect(
        const FleetServerStatus(
          serverId: 's',
          connectivity: FleetServerConnectivity.loading,
        ).needsAttention,
        isFalse,
      );
    });
  });

  group('FleetStatusProvider - refreshAll', () {
    late NasServer testServer;
    late FakeApiClient fakeClient;

    setUp(() async {
      testServer = NasServer.create(
        name: 'Test Server',
        host: '192.168.1.100',
        username: 'admin',
        password: 'password',
      );
      fakeClient = FakeApiClient();
      await service.saveServerConfig(server: testServer, password: 'password');
      TestProviders.mockApiClientManager.addMockClient(
        testServer.id,
        fakeClient,
      );
    });

    tearDown(() async {
      await fakeClient.dispose();
    });

    test(
      'marks a reachable server online with its health and alerts',
      () async {
        fakeClient.alerts = [
          {'id': '1', 'level': 'CRITICAL', 'formatted': 'Pool degraded'},
        ];

        await provider.refreshAll([testServer]);

        final status = provider.statusFor(testServer.id);
        expect(status.connectivity, FleetServerConnectivity.online);
        expect(status.activeAlertCount, 1);
        expect(status.needsAttention, isTrue);
      },
    );

    test('marks a server with no credentials offline', () async {
      final orphanServer = NasServer.create(
        name: 'No Credentials Server',
        host: '192.168.1.200',
        username: 'admin',
        password: 'password',
      );

      await provider.refreshAll([orphanServer]);

      expect(
        provider.statusFor(orphanServer.id).connectivity,
        FleetServerConnectivity.offline,
      );
    });

    test('marks a server offline when getClient fails', () async {
      TestProviders.mockApiClientManager.shouldFailConnection = true;

      await provider.refreshAll([testServer]);

      expect(
        provider.statusFor(testServer.id).connectivity,
        FleetServerConnectivity.offline,
      );
    });

    test('marks a server offline when getServerHealth throws', () async {
      fakeClient.failingMethods.add('getServerHealth');

      await provider.refreshAll([testServer]);

      expect(
        provider.statusFor(testServer.id).connectivity,
        FleetServerConnectivity.offline,
      );
    });

    test('still counts as online when getAlerts fails', () async {
      fakeClient.failingMethods.add('getAlerts');

      await provider.refreshAll([testServer]);

      final status = provider.statusFor(testServer.id);
      expect(status.connectivity, FleetServerConnectivity.online);
      expect(status.activeAlertCount, 0);
    });

    test('a superseded refresh does not overwrite the newer result', () async {
      // Two overlapping refreshAll() calls for the same server - only the
      // second (newer) one's result should stick, regardless of finishing
      // order.
      final first = provider.refreshAll([testServer]);
      final second = provider.refreshAll([testServer]);
      await Future.wait([first, second]);

      expect(
        provider.statusFor(testServer.id).connectivity,
        FleetServerConnectivity.online,
      );
    });
  });
}
