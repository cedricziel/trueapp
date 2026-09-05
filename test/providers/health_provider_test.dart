import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/server_health.dart';
import 'package:truehub/providers/health_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';

import '../helpers/fake_api_client.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';

void main() {
  late AppDatabase database;
  late UnifiedServerService serverService;
  late HealthProvider provider;
  late FakeApiClient fakeClient;
  late NasServer testServer;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();

    database = createTestDatabase();
    serverService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    provider = HealthProvider(serverService);
    fakeClient = FakeApiClient();

    testServer = NasServer.create(
      name: 'Test Server',
      host: '192.168.1.100',
      username: 'admin',
      password: 'password',
    );

    await serverService.saveServerConfig(
      server: testServer,
      password: 'password',
    );
    TestProviders.mockApiClientManager.addMockClient(testServer.id, fakeClient);
  });

  tearDown(() async {
    provider.dispose();
    await fakeClient.dispose();
    await serverService.dispose();
    await TestProviders.cleanupTestEnvironment();
  });

  group('HealthProvider - initial state', () {
    test('starts empty and not loading', () {
      expect(provider.alerts, isEmpty);
      expect(provider.activeAlerts, isEmpty);
      expect(provider.services, isEmpty);
      expect(provider.serverHealth, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.connectionError, isNull);
      expect(provider.error, isNull);
    });
  });

  group('HealthProvider - setApiClient', () {
    test('with a known server obtains an API client', () async {
      await provider.setApiClient(testServer);
      await provider.loadHealth();

      expect(provider.connectionError, isNull);
    });

    test('missing credentials leaves the client unset', () async {
      final orphanServer = NasServer.create(
        name: 'No Credentials Server',
        host: '192.168.1.200',
        username: 'admin',
        password: 'password',
      );

      await provider.setApiClient(orphanServer);
      await provider.loadHealth();

      // loadHealth is a no-op without a client.
      expect(provider.alerts, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('swallows a getClient failure', () async {
      TestProviders.mockApiClientManager.shouldFailConnection = true;

      await provider.setApiClient(testServer);
      await provider.loadHealth();

      expect(provider.alerts, isEmpty);
    });

    test('releases the previous client before switching', () async {
      await provider.setApiClient(testServer);

      final secondServer = NasServer.create(
        name: 'Second Server',
        host: '192.168.1.101',
        username: 'admin',
        password: 'password',
      );
      await serverService.saveServerConfig(
        server: secondServer,
        password: 'password',
      );
      TestProviders.mockApiClientManager.addMockClient(
        secondServer.id,
        FakeApiClient(),
      );

      await provider.setApiClient(secondServer);

      expect(
        TestProviders.mockApiClientManager.wasMethodCalled(
          'releaseClient:${testServer.id}',
        ),
        isTrue,
      );
    });

    test(
      'a superseded setApiClient call does not overwrite the newer one',
      () async {
        // Regression coverage: two setApiClient() calls in flight for the
        // same provider must settle on the second one's client rather than
        // racing to install whichever resolves last.
        final first = provider.setApiClient(testServer);
        final second = provider.setApiClient(testServer);
        await Future.wait([first, second]);

        await provider.loadHealth();

        expect(provider.connectionError, isNull);
      },
    );

    test('a call superseded while releasing the previous client does not '
        'overwrite the newer selection', () async {
      // Regression coverage: once a provider already has a current
      // server, switching to two different servers back-to-back races
      // both calls through the same releaseClient() await for that
      // shared previous server - the older one must recognize it has
      // been superseded there and never touch _currentServerId again.
      await provider.setApiClient(testServer);

      final secondServer = NasServer.create(
        name: 'Second Server',
        host: '192.168.1.101',
        username: 'admin',
        password: 'password',
      );
      final thirdServer = NasServer.create(
        name: 'Third Server',
        host: '192.168.1.102',
        username: 'admin',
        password: 'password',
      );
      await serverService.saveServerConfig(
        server: secondServer,
        password: 'password',
      );
      await serverService.saveServerConfig(
        server: thirdServer,
        password: 'password',
      );
      final olderClient = FakeApiClient()
        ..serverHealth = ServerHealth(
          serverId: secondServer.id,
          timestamp: DateTime(2026),
          cpuUsage: 11,
          memoryUsage: 0,
          diskUsage: 0,
          temperature: 0,
          isOnline: true,
          disks: const [],
          network: const NetworkInfo(
            downloadSpeed: 0,
            uploadSpeed: 0,
            totalDownload: 0,
            totalUpload: 0,
          ),
        );
      final newerClient = FakeApiClient()
        ..serverHealth = ServerHealth(
          serverId: thirdServer.id,
          timestamp: DateTime(2026),
          cpuUsage: 99,
          memoryUsage: 0,
          diskUsage: 0,
          temperature: 0,
          isOnline: true,
          disks: const [],
          network: const NetworkInfo(
            downloadSpeed: 0,
            uploadSpeed: 0,
            totalDownload: 0,
            totalUpload: 0,
          ),
        );
      TestProviders.mockApiClientManager.addMockClient(
        secondServer.id,
        olderClient,
      );
      TestProviders.mockApiClientManager.addMockClient(
        thirdServer.id,
        newerClient,
      );

      final older = provider.setApiClient(secondServer);
      final newer = provider.setApiClient(thirdServer);
      await Future.wait([older, newer]);

      await provider.loadHealth();

      expect(provider.connectionError, isNull);
      expect(provider.serverHealth?.cpuUsage, 99);

      await olderClient.dispose();
      await newerClient.dispose();
    });
  });

  group('HealthProvider - loadHealth', () {
    test('populates alerts, services and server health on success', () async {
      fakeClient.alerts = [
        {'id': '1', 'level': 'CRITICAL', 'formatted': 'Pool degraded'},
      ];
      fakeClient.services = [
        {'service': 'cifs', 'state': 'RUNNING'},
      ];

      await provider.setApiClient(testServer);
      await provider.loadHealth();

      expect(provider.alerts, hasLength(1));
      expect(provider.activeAlerts, hasLength(1));
      expect(provider.services, hasLength(1));
      expect(provider.serverHealth, isNotNull);
      expect(provider.connectionError, isNull);
    });

    test('without a client is a no-op', () async {
      await provider.loadHealth();

      expect(provider.isLoading, isFalse);
      expect(provider.connectionError, isNull);
    });

    test('a getAlerts failure surfaces a connection error', () async {
      fakeClient.failingMethods.add('getAlerts');

      await provider.setApiClient(testServer);
      await provider.loadHealth();

      expect(provider.isLoading, isFalse);
      expect(provider.connectionError, isNotNull);
    });

    test('refreshHealth re-runs loadHealth', () async {
      await provider.setApiClient(testServer);
      await provider.refreshHealth();

      expect(provider.connectionError, isNull);
      expect(fakeClient.calls, contains('getAlerts'));
    });
  });

  group('HealthProvider - dispose', () {
    test('releases the active client', () async {
      final scoped = HealthProvider(serverService);
      await scoped.setApiClient(testServer);

      scoped.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(
        TestProviders.mockApiClientManager.wasMethodCalled(
          'releaseClient:${testServer.id}',
        ),
        isTrue,
      );
    });
  });
}
