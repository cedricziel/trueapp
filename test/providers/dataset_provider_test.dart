import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/dataset_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';

import '../helpers/fake_api_client.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';

void main() {
  late AppDatabase database;
  late UnifiedServerService serverService;
  late DatasetProvider datasetProvider;
  late FakeApiClient fakeClient;
  late NasServer testServer;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();

    database = createTestDatabase();
    serverService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    datasetProvider = DatasetProvider(serverService);
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
    datasetProvider.dispose();
    await fakeClient.dispose();
    await serverService.dispose();
    await TestProviders.cleanupTestEnvironment();
  });

  group('DatasetProvider - initial state', () {
    test('starts empty and not loading', () {
      expect(datasetProvider.datasets, isEmpty);
      expect(datasetProvider.isLoading, isFalse);
      expect(datasetProvider.error, isNull);
    });
  });

  group('DatasetProvider - setServer', () {
    test('with a known server obtains an API client and notifies', () async {
      var notifications = 0;
      datasetProvider.addListener(() => notifications++);

      await datasetProvider.setServer(testServer);

      expect(notifications, greaterThan(0));
      expect(datasetProvider.datasets, isEmpty);
      expect(datasetProvider.error, isNull);
    });

    test('with null clears any previously loaded state', () async {
      fakeClient.datasets = [
        {'id': 'tank/data', 'name': 'tank/data'},
      ];
      await datasetProvider.setServer(testServer);
      await datasetProvider.loadDatasets();
      expect(datasetProvider.datasets, isNotEmpty);

      await datasetProvider.setServer(null);

      expect(datasetProvider.datasets, isEmpty);
      expect(datasetProvider.error, isNull);
      await datasetProvider.loadDatasets();
      expect(datasetProvider.datasets, isEmpty);
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

        await datasetProvider.setServer(orphanServer);

        await datasetProvider.loadDatasets();
        expect(datasetProvider.datasets, isEmpty);
        expect(datasetProvider.isLoading, isFalse);
      },
    );

    test('swallows a getClient failure and leaves state usable', () async {
      TestProviders.mockApiClientManager.shouldFailConnection = true;

      await datasetProvider.setServer(testServer);

      expect(datasetProvider.datasets, isEmpty);
      await datasetProvider.loadDatasets();
      expect(datasetProvider.datasets, isEmpty);
    });

    test('a null getClient result leaves the client unset', () async {
      TestProviders.mockApiClientManager.shouldReturnNull = true;

      await datasetProvider.setServer(testServer);
      await datasetProvider.loadDatasets();

      expect(datasetProvider.datasets, isEmpty);
    });

    test('releases the previous client when switching servers', () async {
      await datasetProvider.setServer(testServer);

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

      await datasetProvider.setServer(secondServer);

      expect(
        TestProviders.mockApiClientManager.wasMethodCalled(
          'releaseClient:${testServer.id}',
        ),
        isTrue,
      );
    });
  });

  group('DatasetProvider - setApiClient', () {
    test('loads a client directly from a server', () async {
      await datasetProvider.setApiClient(testServer);

      fakeClient.datasets = [
        {'id': 'tank/data', 'name': 'tank/data'},
      ];
      await datasetProvider.loadDatasets();

      expect(datasetProvider.datasets, hasLength(1));
    });

    test('missing credentials leaves the client unset', () async {
      final orphanServer = NasServer.create(
        name: 'No Credentials Server 2',
        host: '192.168.1.201',
        username: 'admin',
        password: 'password',
      );

      await datasetProvider.setApiClient(orphanServer);
      await datasetProvider.loadDatasets();

      expect(datasetProvider.datasets, isEmpty);
    });
  });

  group('DatasetProvider - loadDatasets', () {
    test('populates datasets on success and toggles isLoading', () async {
      await datasetProvider.setServer(testServer);
      fakeClient.datasets = [
        {'id': 'tank/data', 'name': 'tank/data'},
        {'id': 'tank/backup', 'name': 'tank/backup'},
      ];

      final loadingStates = <bool>[];
      datasetProvider.addListener(
        () => loadingStates.add(datasetProvider.isLoading),
      );

      await datasetProvider.loadDatasets();

      expect(datasetProvider.datasets, hasLength(2));
      expect(datasetProvider.isLoading, isFalse);
      expect(datasetProvider.error, isNull);
      expect(loadingStates, contains(true));
      expect(loadingStates.last, isFalse);
    });

    test('sets an error message and clears loading on failure', () async {
      await datasetProvider.setServer(testServer);
      fakeClient.failingMethods.add('getDatasets');

      await datasetProvider.loadDatasets();

      expect(datasetProvider.datasets, isEmpty);
      expect(datasetProvider.isLoading, isFalse);
      expect(datasetProvider.error, isNotNull);
      expect(datasetProvider.error, contains('getDatasets'));
    });

    test('is a no-op without a client', () async {
      await datasetProvider.loadDatasets();
      expect(datasetProvider.datasets, isEmpty);
      expect(datasetProvider.isLoading, isFalse);
    });
  });

  group('DatasetProvider - refreshDatasets', () {
    test('delegates to loadDatasets', () async {
      await datasetProvider.setServer(testServer);
      fakeClient.datasets = [
        {'id': 'tank/data', 'name': 'tank/data'},
      ];

      await datasetProvider.refreshDatasets();

      expect(datasetProvider.datasets, hasLength(1));
    });
  });

  group('DatasetProvider - dispose', () {
    test('releases the active client', () async {
      final scopedProvider = DatasetProvider(serverService);
      await scopedProvider.setServer(testServer);
      scopedProvider.dispose();

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
