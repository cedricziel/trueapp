import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/models/app_config.dart';
import 'package:truehub/models/connection_error.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/app_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';

import '../helpers/fake_api_client.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';

App _sampleApp({
  String name = 'plex',
  bool installed = true,
  Map<String, String> portals = const {'web': 'http://localhost:32400'},
}) {
  return App(
    name: name,
    title: 'Plex Media Server',
    description: 'Media server',
    installed: installed,
    healthy: true,
    latestVersion: '1.0.0',
    latestAppVersion: '1.0.0',
    latestHumanVersion: '1.0.0',
    categories: const ['media'],
    tags: const [],
    screenshots: const [],
    sources: const [],
    maintainers: const [],
    recommended: false,
    catalog: 'community',
    train: 'community',
    usedPorts: const [],
    portals: portals,
  );
}

/// A [FakeApiClient] whose installed-apps call fails the way the real
/// client fails: with a classified [ConnectionException], not a bare
/// [Exception].
class _ClassifiedFailureClient extends FakeApiClient {
  ConnectionError failure = ConnectionError.permissionDenied(
    details: 'Not authorized',
  );

  @override
  Future<List<App>> getInstalledApps() async {
    calls.add('getInstalledApps');
    throw ConnectionException(failure);
  }
}

void main() {
  late AppDatabase database;
  late UnifiedServerService serverService;
  late AppProvider appProvider;
  late FakeApiClient fakeClient;
  late NasServer testServer;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();

    database = createTestDatabase();
    serverService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    appProvider = AppProvider(database: database, serverService: serverService);
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
    appProvider.dispose();
    await fakeClient.dispose();
    await serverService.dispose();
    await TestProviders.cleanupTestEnvironment();
  });

  group('AppProvider - initial state', () {
    test('starts empty and not loading', () {
      expect(appProvider.appConfigs, isEmpty);
      expect(appProvider.categories, isEmpty);
      expect(appProvider.isLoading, isFalse);
      expect(appProvider.connectionError, isNull);
      expect(appProvider.error, isNull);
      expect(appProvider.installedApps, isEmpty);
      expect(appProvider.availableApps, isEmpty);
      expect(appProvider.enabledApps, isEmpty);
      expect(appProvider.favoriteApps, isEmpty);
      expect(appProvider.apps, isEmpty);
    });
  });

  group('AppProvider - setServer', () {
    test('with a known server obtains an API client and notifies', () async {
      var notifications = 0;
      appProvider.addListener(() => notifications++);

      await appProvider.setServer(testServer);

      expect(notifications, greaterThan(0));
      expect(appProvider.connectionError, isNull);
    });

    test('with null clears loaded state', () async {
      await appProvider.setServer(testServer);
      await appProvider.setServer(null);

      expect(appProvider.appConfigs, isEmpty);
      expect(appProvider.categories, isEmpty);
    });

    test('missing credentials still loads persisted configs', () async {
      final orphanServer = NasServer.create(
        name: 'No Credentials Server',
        host: '192.168.1.200',
        username: 'admin',
        password: 'password',
      );

      await appProvider.setServer(orphanServer);

      // loadApps should now run in offline mode (no exception, no apiClient).
      await appProvider.loadApps();
      expect(appProvider.appConfigs, isEmpty);
      expect(appProvider.connectionError, isNull);
    });

    test('swallows a getClient failure and still loads offline data', () async {
      TestProviders.mockApiClientManager.shouldFailConnection = true;

      await appProvider.setServer(testServer);

      expect(appProvider.appConfigs, isEmpty);
    });

    test('releases the previous client when switching servers', () async {
      await appProvider.setServer(testServer);

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

      await appProvider.setServer(secondServer);

      expect(
        TestProviders.mockApiClientManager.wasMethodCalled(
          'releaseClient:${testServer.id}',
        ),
        isTrue,
      );
    });
  });

  group('AppProvider - setApiClient', () {
    test('loads a client directly and persisted configs', () async {
      await appProvider.setApiClient(testServer);
      expect(appProvider.appConfigs, isEmpty);
    });
  });

  group('AppProvider - loadApps (online)', () {
    test('syncs available and installed apps to the database', () async {
      await appProvider.setServer(testServer);

      fakeClient.availableApps = [
        _sampleApp(name: 'plex', installed: false, portals: const {}),
        _sampleApp(name: 'sonarr', installed: false, portals: const {}),
      ];
      fakeClient.installedApps = [_sampleApp(name: 'plex', installed: true)];
      fakeClient.appCategories = ['media', 'downloads'];

      final loadingStates = <bool>[];
      appProvider.addListener(() => loadingStates.add(appProvider.isLoading));

      await appProvider.loadApps();

      expect(appProvider.appConfigs, hasLength(2));
      expect(appProvider.categories, ['media', 'downloads']);
      expect(appProvider.isLoading, isFalse);
      expect(appProvider.connectionError, isNull);
      expect(loadingStates, contains(true));
      expect(loadingStates.last, isFalse);

      // Installed data should win over the available-only entry.
      final plex = appProvider.getAppConfig('plex');
      expect(plex, isNotNull);
      expect(plex!.installed, isTrue);

      expect(appProvider.installedApps, hasLength(1));
      expect(appProvider.availableApps, hasLength(1));
    });

    test('subscribes to app stats after an online load', () async {
      await appProvider.setServer(testServer);
      fakeClient.availableApps = [_sampleApp()];
      fakeClient.installedApps = [_sampleApp()];
      fakeClient.appCategories = [];

      await appProvider.loadApps();
      // _subscribeToAppStats() is fire-and-forget, so give its first await
      // point a turn of the event loop before asserting on it.
      await Future<void>.delayed(Duration.zero);

      expect(fakeClient.calls, contains('subscribeToAppStats'));
    });

    test('an installed-apps failure falls back to persisted (empty) data with '
        'an error that keeps the cause', () async {
      await appProvider.setServer(testServer);
      fakeClient.failingMethods.add('getInstalledApps');

      await appProvider.loadApps();

      expect(appProvider.connectionError, isNotNull);
      expect(appProvider.error, appProvider.connectionError!.shortMessage);
      expect(
        appProvider.errorDetails,
        contains('getInstalledApps configured to fail'),
      );
      expect(appProvider.catalogError, isNull);
      expect(appProvider.appConfigs, isEmpty);
      expect(appProvider.isLoading, isFalse);
    });

    test(
      'a classified failure from the client is surfaced as-is, type and '
      'details included, instead of being flattened to "Connection error"',
      () async {
        final client = _ClassifiedFailureClient();
        TestProviders.mockApiClientManager.addMockClient(testServer.id, client);
        await appProvider.setServer(testServer);

        await appProvider.loadApps();

        expect(
          appProvider.connectionError?.type,
          ConnectionErrorType.permissionDenied,
        );
        expect(appProvider.error, 'Permission denied');
        expect(appProvider.errorDetails, 'Not authorized');
      },
    );

    test('a catalog failure degrades to installed apps instead of failing the '
        'whole load', () async {
      await appProvider.setServer(testServer);
      fakeClient.failingMethods.add('getAvailableApps');
      fakeClient.installedApps = [_sampleApp(name: 'plex', installed: true)];
      fakeClient.appCategories = ['media'];

      await appProvider.loadApps();

      expect(appProvider.connectionError, isNull);
      expect(appProvider.error, isNull);
      expect(appProvider.installedApps, hasLength(1));
      expect(appProvider.categories, ['media']);
      expect(appProvider.catalogError, isNotNull);
      expect(
        appProvider.catalogError!.technicalDetails,
        contains('getAvailableApps configured to fail'),
      );
      expect(appProvider.isLoading, isFalse);
    });

    test('a categories failure is a catalog failure too', () async {
      await appProvider.setServer(testServer);
      fakeClient.failingMethods.add('getAppCategories');
      fakeClient.installedApps = [_sampleApp(name: 'plex', installed: true)];
      fakeClient.availableApps = [
        _sampleApp(name: 'sonarr', installed: false, portals: const {}),
      ];

      await appProvider.loadApps();

      expect(appProvider.connectionError, isNull);
      expect(appProvider.catalogError, isNotNull);
      expect(appProvider.installedApps, hasLength(1));
      // The available list itself still came through.
      expect(appProvider.availableApps, hasLength(1));
      expect(appProvider.categories, isEmpty);
    });

    test(
      'a catalog failure keeps the previously synced catalog entries',
      () async {
        await appProvider.setServer(testServer);
        fakeClient.installedApps = [_sampleApp(name: 'plex', installed: true)];
        fakeClient.availableApps = [
          _sampleApp(name: 'sonarr', installed: false, portals: const {}),
        ];
        await appProvider.loadApps();
        expect(appProvider.availableApps, hasLength(1));

        fakeClient.failingMethods.add('getAvailableApps');
        await appProvider.loadApps();

        expect(appProvider.catalogError, isNotNull);
        expect(appProvider.availableApps, hasLength(1));
        expect(appProvider.installedApps, hasLength(1));
      },
    );

    test('a successful reload clears a previous catalog error', () async {
      await appProvider.setServer(testServer);
      fakeClient.failingMethods.add('getAvailableApps');
      await appProvider.loadApps();
      expect(appProvider.catalogError, isNotNull);

      fakeClient.failingMethods.remove('getAvailableApps');
      await appProvider.loadApps();

      expect(appProvider.catalogError, isNull);
    });

    test('an installed-apps failure wins over a simultaneous catalog failure '
        'and leaves no unhandled error behind', () async {
      await appProvider.setServer(testServer);
      fakeClient.failingMethods
        ..add('getInstalledApps')
        ..add('getAvailableApps')
        ..add('getAppCategories');

      await appProvider.loadApps();

      expect(appProvider.connectionError, isNotNull);
      expect(appProvider.catalogError, isNull);
      expect(appProvider.isLoading, isFalse);
    });

    test('is a no-op without a current server', () async {
      await appProvider.loadApps();
      expect(appProvider.appConfigs, isEmpty);
      expect(appProvider.isLoading, isFalse);
    });
  });

  group('AppProvider - loadApps (offline)', () {
    test('loads from the database when there is no API client', () async {
      final orphanServer = NasServer.create(
        name: 'No Credentials Server 2',
        host: '192.168.1.201',
        username: 'admin',
        password: 'password',
      );
      // Persists the server row itself (app_configs.server_id is a foreign
      // key), but deliberately never stores credentials via
      // serverService.saveServerConfig - that's what keeps this server
      // "orphaned" for setServer()'s offline-fallback path below.
      await database.insertServer(orphanServer);
      await appProvider.setServer(orphanServer);

      await database.insertFullAppConfig(
        AppConfig(
          serverId: orphanServer.id,
          appName: 'nextcloud',
          title: 'Nextcloud',
          installed: true,
        ),
      );

      await appProvider.loadApps();

      expect(appProvider.appConfigs, hasLength(1));
      expect(appProvider.appConfigs.first.appName, 'nextcloud');
    });
  });

  group('AppProvider - refreshApps', () {
    test('delegates to loadApps', () async {
      await appProvider.setServer(testServer);
      fakeClient.availableApps = [_sampleApp()];
      fakeClient.installedApps = [];
      fakeClient.appCategories = [];

      await appProvider.refreshApps();

      expect(appProvider.appConfigs, hasLength(1));
    });
  });

  group('AppProvider - getAppsByCategory', () {
    test('filters configs by category membership', () async {
      await appProvider.setServer(testServer);
      fakeClient.availableApps = [
        _sampleApp(name: 'plex'),
        App(
          name: 'sabnzbd',
          title: 'SABnzbd',
          description: '',
          installed: false,
          healthy: true,
          latestVersion: '1.0.0',
          latestAppVersion: '1.0.0',
          latestHumanVersion: '1.0.0',
          categories: const ['downloads'],
          tags: const [],
          screenshots: const [],
          sources: const [],
          maintainers: const [],
          recommended: false,
          catalog: 'community',
          train: 'community',
          usedPorts: const [],
          portals: const {},
        ),
      ];
      fakeClient.installedApps = [];
      fakeClient.appCategories = [];

      await appProvider.loadApps();

      expect(appProvider.getAppsByCategory('media'), isNotEmpty);
      expect(appProvider.getAppsByCategory('nonexistent'), isEmpty);
    });
  });

  group('AppProvider - app control (upgrade/start/stop/restart)', () {
    Future<void> loadOneApp() async {
      await appProvider.setServer(testServer);
      fakeClient.availableApps = [_sampleApp()];
      fakeClient.installedApps = [_sampleApp()];
      fakeClient.appCategories = [];
      await appProvider.loadApps();
      // Let the fire-and-forget app-stats subscription settle so call
      // counts are deterministic for the rest of the test.
      await Future<void>.delayed(Duration.zero);
    }

    test('upgradeApp succeeds and reloads apps', () async {
      await loadOneApp();
      fakeClient.upgradeAppResult = true;

      final result = await appProvider.upgradeApp('plex', version: '2.0.0');

      expect(result, isTrue);
      expect(fakeClient.calls, contains('upgradeApp'));
    });

    test('upgradeApp returns false without a client', () async {
      final result = await appProvider.upgradeApp('plex');
      expect(result, isFalse);
    });

    test('upgradeApp returns false and does not throw on failure', () async {
      await loadOneApp();
      fakeClient.failingMethods.add('upgradeApp');

      final result = await appProvider.upgradeApp('plex');

      expect(result, isFalse);
    });

    test('upgradeApp does not reload when the API reports failure', () async {
      await loadOneApp();
      fakeClient.upgradeAppResult = false;
      final callsBefore = fakeClient.calls.length;

      final result = await appProvider.upgradeApp('plex');

      expect(result, isFalse);
      // Only the upgradeApp call itself, no follow-up loadApps calls.
      expect(fakeClient.calls.length, callsBefore + 1);
    });

    test('startApp succeeds and reloads apps', () async {
      await loadOneApp();
      fakeClient.startAppResult = true;

      final result = await appProvider.startApp('plex');

      expect(result, isTrue);
      expect(fakeClient.calls, contains('startApp'));
    });

    test('startApp returns false without a client', () async {
      final result = await appProvider.startApp('plex');
      expect(result, isFalse);
    });

    test('startApp returns false and does not throw on failure', () async {
      await loadOneApp();
      fakeClient.failingMethods.add('startApp');

      final result = await appProvider.startApp('plex');

      expect(result, isFalse);
    });

    test('stopApp succeeds and reloads apps', () async {
      await loadOneApp();
      fakeClient.stopAppResult = true;

      final result = await appProvider.stopApp('plex');

      expect(result, isTrue);
      expect(fakeClient.calls, contains('stopApp'));
    });

    test('stopApp returns false without a client', () async {
      final result = await appProvider.stopApp('plex');
      expect(result, isFalse);
    });

    test('stopApp returns false and does not throw on failure', () async {
      await loadOneApp();
      fakeClient.failingMethods.add('stopApp');

      final result = await appProvider.stopApp('plex');

      expect(result, isFalse);
    });

    test('restartApp succeeds and reloads apps', () async {
      await loadOneApp();
      fakeClient.restartAppResult = true;

      final result = await appProvider.restartApp('plex');

      expect(result, isTrue);
      expect(fakeClient.calls, contains('restartApp'));
    });

    test('restartApp returns false without a client', () async {
      final result = await appProvider.restartApp('plex');
      expect(result, isFalse);
    });

    test('restartApp returns false and does not throw on failure', () async {
      await loadOneApp();
      fakeClient.failingMethods.add('restartApp');

      final result = await appProvider.restartApp('plex');

      expect(result, isFalse);
    });
  });

  group('AppProvider - app stats subscription', () {
    test('resource usage updates flow into apps and notify', () async {
      await appProvider.setServer(testServer);
      fakeClient.availableApps = [_sampleApp()];
      fakeClient.installedApps = [_sampleApp()];
      fakeClient.appCategories = [];
      await appProvider.loadApps();
      // Let the fire-and-forget app-stats subscription attach before we
      // start counting notifications and emit stats.
      await Future<void>.delayed(Duration.zero);

      var notifications = 0;
      appProvider.addListener(() => notifications++);

      fakeClient.emitAppStats({
        'plex': const AppResourceUsage(
          cpuUsage: 12.5,
          memoryUsage: 1024,
          memoryLimit: 2048,
          networkRxBytes: 10,
          networkTxBytes: 5,
        ),
      });
      await Future<void>.delayed(Duration.zero);

      expect(notifications, greaterThan(0));
      final app = appProvider.apps.firstWhere((a) => a.name == 'plex');
      expect(app.resourceUsage, isNotNull);
      expect(app.resourceUsage!.cpuUsage, 12.5);
    });
  });

  group('AppProvider - app configuration management', () {
    test('updateAppConfig persists and reloads', () async {
      await appProvider.setServer(testServer);
      final inserted = await database.getFullAppConfigs(testServer.id);
      expect(inserted, isEmpty);

      final id = await database.insertFullAppConfig(
        AppConfig(serverId: testServer.id, appName: 'plex', title: 'Plex'),
      );
      await appProvider.loadApps();
      final config = appProvider.getAppConfig('plex')!;
      expect(config.id, id);

      await appProvider.updateAppConfig(
        config.copyWith(displayName: 'My Plex'),
      );

      expect(appProvider.getAppConfig('plex')!.displayName, 'My Plex');
    });

    test('setAppFavorite toggles favorite state', () async {
      await appProvider.setServer(testServer);
      await database.insertFullAppConfig(
        AppConfig(serverId: testServer.id, appName: 'plex', title: 'Plex'),
      );
      await appProvider.loadApps();
      expect(appProvider.isAppFavorite('plex'), isFalse);

      await appProvider.setAppFavorite('plex', true);

      expect(appProvider.isAppFavorite('plex'), isTrue);
      expect(appProvider.favoriteApps, hasLength(1));
    });

    test('setAppFavorite is a no-op without a current server', () async {
      await appProvider.setAppFavorite('plex', true);
      expect(appProvider.appConfigs, isEmpty);
    });

    test('getAppConfig returns null for an unknown app', () {
      expect(appProvider.getAppConfig('unknown'), isNull);
    });

    test('getPrimaryUrl and getAppUrls reflect port configuration', () async {
      await appProvider.setServer(testServer);
      await database.insertFullAppConfig(
        AppConfig(
          serverId: testServer.id,
          appName: 'plex',
          title: 'Plex',
          ports: const [
            AppPortConfig(
              portNumber: 32400,
              serviceName: 'web',
              apiUrl: 'http://localhost:32400',
              isPrimary: true,
            ),
          ],
        ),
      );
      await appProvider.loadApps();

      expect(appProvider.getPrimaryUrl('plex'), contains('32400'));
      expect(appProvider.getAppUrls('plex'), isNotEmpty);
      expect(appProvider.getPrimaryUrl('unknown'), isNull);
      expect(appProvider.getAppUrls('unknown'), isEmpty);
    });

    test('getAppsWithPortals only returns configs with usable ports', () async {
      await appProvider.setServer(testServer);
      await database.insertFullAppConfig(
        AppConfig(serverId: testServer.id, appName: 'no-ports', title: 'x'),
      );
      await database.insertFullAppConfig(
        AppConfig(
          serverId: testServer.id,
          appName: 'with-port',
          title: 'y',
          ports: const [AppPortConfig(portNumber: 80, isPrimary: true)],
        ),
      );
      await appProvider.loadApps();

      final withPortals = appProvider.getAppsWithPortals();
      expect(withPortals.map((c) => c.appName), ['with-port']);
    });
  });

  group('AppProvider - dispose', () {
    test('releases the active client', () async {
      final scopedProvider = AppProvider(
        database: database,
        serverService: serverService,
      );
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
