import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/connection_error.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/pool_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';

import '../helpers/fake_api_client.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';

void main() {
  late AppDatabase database;
  late UnifiedServerService serverService;
  late PoolProvider poolProvider;
  late FakeApiClient fakeClient;
  late NasServer testServer;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();

    database = createTestDatabase();
    serverService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    poolProvider = PoolProvider(serverService);
    fakeClient = FakeApiClient();

    testServer = NasServer.create(
      name: 'Test Server',
      host: '192.168.1.100',
      username: 'admin',
      password: 'password',
    );

    // Store credentials so `ServerProvider.loadServerCredentials` succeeds,
    // and register the fake client so ApiClientManager.getClient() returns it.
    await serverService.saveServerConfig(
      server: testServer,
      password: 'password',
    );
    TestProviders.mockApiClientManager.addMockClient(testServer.id, fakeClient);
  });

  tearDown(() async {
    poolProvider.dispose();
    await fakeClient.dispose();
    await serverService.dispose();
    await TestProviders.cleanupTestEnvironment();
  });

  group('PoolProvider - initial state', () {
    test('starts empty and not loading', () {
      expect(poolProvider.pools, isEmpty);
      expect(poolProvider.isLoading, isFalse);
      expect(poolProvider.connectionError, isNull);
      expect(poolProvider.error, isNull);
    });
  });

  group('PoolProvider - setServer', () {
    test('with a known server obtains an API client and notifies', () async {
      var notifications = 0;
      poolProvider.addListener(() => notifications++);

      await poolProvider.setServer(testServer);

      expect(notifications, greaterThan(0));
      expect(poolProvider.pools, isEmpty);
      expect(poolProvider.connectionError, isNull);
    });

    test('with null clears any previously loaded state', () async {
      fakeClient.pools = [
        {'id': 1, 'name': 'tank'},
      ];
      await poolProvider.setServer(testServer);
      await poolProvider.loadPools();
      expect(poolProvider.pools, isNotEmpty);

      await poolProvider.setServer(null);

      expect(poolProvider.pools, isEmpty);
      expect(poolProvider.connectionError, isNull);
      // loadPools should now be a no-op since the client was cleared.
      await poolProvider.loadPools();
      expect(poolProvider.pools, isEmpty);
    });

    test(
      'with a server missing stored credentials leaves client unset',
      () async {
        final orphanServer = NasServer.create(
          name: 'No Credentials Server',
          host: '192.168.1.200',
          username: 'admin',
          password: 'password',
        );
        // Not saved via serverService, so getPassword() returns null.

        await poolProvider.setServer(orphanServer);

        // loadPools is a no-op without a client - proves the client never got set.
        await poolProvider.loadPools();
        expect(poolProvider.pools, isEmpty);
        expect(poolProvider.isLoading, isFalse);
      },
    );

    test('swallows a getClient failure and leaves state usable', () async {
      TestProviders.mockApiClientManager.shouldFailConnection = true;

      await poolProvider.setServer(testServer);

      expect(poolProvider.pools, isEmpty);
      await poolProvider.loadPools();
      expect(poolProvider.pools, isEmpty);
    });

    test('a null getClient result leaves the client unset', () async {
      TestProviders.mockApiClientManager.shouldReturnNull = true;

      await poolProvider.setServer(testServer);
      await poolProvider.loadPools();

      expect(poolProvider.pools, isEmpty);
    });

    test('releases the previous client when switching servers', () async {
      await poolProvider.setServer(testServer);

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

      await poolProvider.setServer(secondServer);

      expect(
        TestProviders.mockApiClientManager.wasMethodCalled(
          'releaseClient:${testServer.id}',
        ),
        isTrue,
      );
    });
  });

  group('PoolProvider - setApiClient', () {
    test('loads a client directly from a server', () async {
      await poolProvider.setApiClient(testServer);

      fakeClient.pools = [
        {'id': 1, 'name': 'tank'},
      ];
      await poolProvider.loadPools();

      expect(poolProvider.pools, hasLength(1));
    });

    test('missing credentials leaves the client unset', () async {
      final orphanServer = NasServer.create(
        name: 'No Credentials Server 2',
        host: '192.168.1.201',
        username: 'admin',
        password: 'password',
      );

      await poolProvider.setApiClient(orphanServer);
      await poolProvider.loadPools();

      expect(poolProvider.pools, isEmpty);
    });
  });

  group('PoolProvider - loadPools', () {
    test('populates pools on success and toggles isLoading', () async {
      await poolProvider.setServer(testServer);
      fakeClient.pools = [
        {'id': 1, 'name': 'tank'},
        {'id': 2, 'name': 'backup'},
      ];

      final loadingStates = <bool>[];
      poolProvider.addListener(() => loadingStates.add(poolProvider.isLoading));

      final future = poolProvider.loadPools();
      // isLoading should have flipped to true synchronously before the await
      // point inside loadPools runs its async body.
      await future;

      expect(poolProvider.pools, hasLength(2));
      expect(poolProvider.isLoading, isFalse);
      expect(poolProvider.connectionError, isNull);
      expect(loadingStates, contains(true));
      expect(loadingStates.last, isFalse);
    });

    test('sets a connection error and clears loading on failure', () async {
      await poolProvider.setServer(testServer);
      fakeClient.failingMethods.add('getPools');

      await poolProvider.loadPools();

      expect(poolProvider.pools, isEmpty);
      expect(poolProvider.isLoading, isFalse);
      expect(poolProvider.connectionError, isNotNull);
      expect(poolProvider.connectionError!.type, ConnectionErrorType.unknown);
      expect(poolProvider.error, poolProvider.connectionError!.shortMessage);
    });

    test('is a no-op without a client', () async {
      await poolProvider.loadPools();
      expect(poolProvider.pools, isEmpty);
      expect(poolProvider.isLoading, isFalse);
    });
  });

  group('PoolProvider - refreshPools', () {
    test('delegates to loadPools', () async {
      await poolProvider.setServer(testServer);
      fakeClient.pools = [
        {'id': 1, 'name': 'tank'},
      ];

      await poolProvider.refreshPools();

      expect(poolProvider.pools, hasLength(1));
    });
  });

  group('PoolProvider - dispose', () {
    test('releases the active client', () async {
      // Use a provider scoped to this test (rather than the shared
      // `poolProvider`) so this explicit dispose() doesn't collide with the
      // one `tearDown` issues for every test.
      final scopedProvider = PoolProvider(serverService);
      await scopedProvider.setServer(testServer);
      scopedProvider.dispose();

      // dispose() fires a fire-and-forget release; give the microtask a turn.
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
