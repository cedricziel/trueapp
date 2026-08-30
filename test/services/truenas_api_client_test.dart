import 'package:flutter_otel/flutter_otel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/truenas_api_client.dart';

import '../helpers/fake_telemetry_service.dart';
import '../helpers/fake_truenas_server.dart';

void main() {
  group('TrueNasApiClient', () {
    late TrueNasApiClient client;
    late NasServer testServer;

    setUp(() {
      testServer = NasServer.create(
        name: 'Test Server',
        host: 'localhost',
        localUrl: 'http://192.168.1.100:8080',
        trustedWifiSsids: ['HomeWiFi', 'OfficeWiFi'],
        port: 8080,
        username: 'root',
        password: 'password',
        useHttps: false,
      );
      client = TrueNasApiClient(testServer);
    });

    // tearDown removed - no real connections to close in these tests

    test('should create client with server configuration', () {
      expect(client, isNotNull);
    });

    // Note: Network tests are skipped for now - we need a mock server for proper testing
    // TODO: Add mock WebSocket server tests for validateLogin and testConnection

    test('should construct WebSocket URL correctly', () {
      final httpServer = NasServer.create(
        name: 'HTTP Server',
        host: '192.168.1.100',
        port: 80,
        username: 'admin',
        password: 'pass',
        useHttps: false,
      );

      final httpsServer = NasServer.create(
        name: 'HTTPS Server',
        host: '192.168.1.100',
        port: 443,
        username: 'admin',
        password: 'pass',
        useHttps: true,
      );

      // We can't directly test the WebSocket URL construction without exposing it,
      // but we can verify the base URL is correct
      expect(httpServer.baseUrl, 'http://192.168.1.100:80');
      expect(httpsServer.baseUrl, 'https://192.168.1.100:443');
    });

    test('should handle local URL selection based on network context', () {
      final serverWithLocal = NasServer.create(
        name: 'Server with Local URL',
        host: '203.0.113.1', // Remote IP
        localUrl: 'http://192.168.1.100:80', // Local IP
        trustedWifiSsids: ['HomeWiFi'],
        username: 'admin',
        password: 'pass',
        useHttps: true,
      );

      // When on trusted network, should use local URL
      expect(
        serverWithLocal.getUrlForNetwork(isOnTrustedNetwork: true),
        'http://192.168.1.100:80',
      );

      // When not on trusted network, should use remote URL
      expect(
        serverWithLocal.getUrlForNetwork(isOnTrustedNetwork: false),
        'https://203.0.113.1:443',
      );
    });

    test('should handle default ports correctly', () {
      final serverWithoutPort = NasServer.create(
        name: 'Server without Port',
        host: '192.168.1.100',
        username: 'admin',
        password: 'pass',
        useHttps: true,
      );

      expect(serverWithoutPort.baseUrl, 'https://192.168.1.100:443');

      final httpServerWithoutPort = NasServer.create(
        name: 'HTTP Server without Port',
        host: '192.168.1.100',
        username: 'admin',
        password: 'pass',
        useHttps: false,
      );

      expect(httpServerWithoutPort.baseUrl, 'http://192.168.1.100:80');
    });
  });

  group('TrueNasApiClient against a fake JSON-RPC server', () {
    late FakeTrueNasServer server;
    late TrueNasApiClient client;
    late NasServer testServer;

    NasServer serverFor(FakeTrueNasServer s) => NasServer(
      id: 'fake-server',
      name: 'Fake Server',
      host: '127.0.0.1',
      port: s.port,
      useHttps: false,
      username: 'root',
      password: 'password',
      localUrl: null,
      // Empty list keeps NetworkService off the platform channels.
      trustedWifiSsids: const [],
      isDefault: false,
    );

    setUp(() async {
      server = await FakeTrueNasServer.start();
      testServer = serverFor(server);
      client = TrueNasApiClient(testServer);
    });

    tearDown(() async {
      await client.close();
      await server.stop();
    });

    test(
      'validateLogin succeeds when the server accepts the credentials',
      () async {
        final result = await client.validateLogin('root', 'password');
        expect(result, isTrue);
      },
    );

    test('validateLogin passes an OTP token through when supplied', () async {
      Object? capturedParams;
      server.onMethod('auth.login', (params) {
        capturedParams = params.asList;
        return true;
      });

      final result = await client.validateLogin('root', 'password', '123456');

      expect(result, isTrue);
      expect(capturedParams, ['root', 'password', '123456']);
    });

    test(
      'validateLogin returns false when the server rejects the login',
      () async {
        server.onMethod('auth.login', (_) => false);

        final result = await client.validateLogin('root', 'wrong');

        expect(result, isFalse);
      },
    );

    test('validateLogin returns false when the server errors', () async {
      server.onMethod(
        'auth.login',
        (_) => throw json_rpc.RpcException(401, 'nope'),
      );

      final result = await client.validateLogin('root', 'password');

      expect(result, isFalse);
    });

    test(
      'validateLogin returns false when nothing is listening on the port',
      () async {
        await server.stop();
        final deadClient = TrueNasApiClient(testServer);

        final result = await deadClient.validateLogin('root', 'password');

        expect(result, isFalse);
        await deadClient.close();
      },
    );

    test('getCurrentUser returns the parsed user', () async {
      server.onMethod(
        'auth.me',
        (_) => {
          'pw_name': 'root',
          'pw_gecos': 'Root User',
          'pw_dir': '/root',
          'pw_shell': '/bin/sh',
          'pw_uid': 0,
          'pw_gid': 0,
          'source': 'LOCAL',
          'local': true,
          'grouplist': [0, 1],
          'attributes': <String, dynamic>{},
          'two_factor_config': null,
          'privilege': <String, dynamic>{},
        },
      );

      final user = await client.getCurrentUser();

      expect(user.username, 'root');
      expect(user.fullName, 'Root User');
      expect(user.uid, 0);
      expect(user.isAdministrator, isTrue);
    });

    test('getCurrentUser throws when the server errors', () async {
      server.onMethod(
        'auth.me',
        (_) => throw json_rpc.RpcException(500, 'db is down'),
      );

      await expectLater(
        client.getCurrentUser(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Server error occurred'),
          ),
        ),
      );
    });

    test('a forbidden RPC error surfaces as permission denied', () async {
      server.onMethod(
        'system.info',
        (_) => throw json_rpc.RpcException(403, 'nope'),
      );

      await expectLater(
        client.getSystemInfo(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Permission denied'),
          ),
        ),
      );
    });

    test('queryPools returns the pool list', () async {
      server.onMethod(
        'pool.query',
        (_) => [
          {'id': 1, 'name': 'tank'},
          {'id': 2, 'name': 'boot-pool'},
        ],
      );

      final pools = await client.queryPools();

      expect(pools, hasLength(2));
      expect(pools.first['name'], 'tank');

      // getPools() is a thin wrapper around queryPools().
      final poolsAgain = await client.getPools();
      expect(poolsAgain, hasLength(2));
    });

    test('getPoolById returns a single pool', () async {
      server.onMethod('pool.query', (params) {
        expect(params.asMap, {'id': 'tank'});
        return {'id': 'tank', 'name': 'tank'};
      });

      final pool = await client.getPoolById('tank');

      expect(pool['name'], 'tank');
    });

    test('queryDatasets and getDatasetById', () async {
      server.onMethod(
        'pool.dataset.query',
        (params) => params.value == null
            ? [
                {'id': 'tank/data', 'name': 'tank/data'},
              ]
            : {'id': 'tank/data', 'name': 'tank/data'},
      );

      final datasets = await client.queryDatasets();
      expect(datasets, hasLength(1));

      final datasetsAgain = await client.getDatasets();
      expect(datasetsAgain, hasLength(1));

      final dataset = await client.getDatasetById('tank/data');
      expect(dataset['name'], 'tank/data');
    });

    test('system info methods return the raw maps', () async {
      server
        ..onMethod('system.info', (_) => {'version': 'TrueNAS-SCALE-24.10'})
        ..onMethod('system.cpu_info', (_) => {'cpu_count': 8})
        ..onMethod('system.memory_info', (_) => {'total': 1000})
        ..onMethod('system.temperature', (_) => 42.5)
        ..onMethod('system.general.config', (_) => {'hostname': 'truenas'})
        ..onMethod('system.advanced.config', (_) => {'consolemenu': false})
        ..onMethod('system.product_type', (_) => 'SCALE')
        ..onMethod('truenas.is_ix_hardware', (_) => false);

      expect((await client.getSystemInfo())['version'], 'TrueNAS-SCALE-24.10');
      expect((await client.getSystemCpuInfo())['cpu_count'], 8);
      expect((await client.getSystemMemoryInfo())['total'], 1000);
      expect(await client.getSystemTemperature(), 42.5);
      expect((await client.getSystemGeneralConfig())['hostname'], 'truenas');
      expect((await client.getSystemAdvancedConfig())['consolemenu'], false);
      expect(await client.getSystemProductType(), 'SCALE');
      expect(await client.isIxHardware(), isFalse);
    });

    test('listDirectory, getFileInfo and getDirectoryListing', () async {
      server
        ..onMethod(
          'filesystem.listdir',
          (params) => [
            {
              'name': 'file.txt',
              'path': '${params.asMap['path']}/file.txt',
              'type': 'FILE',
              'size': 123,
            },
          ],
        )
        ..onMethod('filesystem.stat', (_) => {'name': 'file.txt', 'size': 123});

      final entries = await client.listDirectory('/mnt/tank');
      expect(entries, hasLength(1));
      expect(entries.first['path'], '/mnt/tank/file.txt');

      final info = await client.getFileInfo('/mnt/tank/file.txt');
      expect(info['size'], 123);

      final listing = await client.getDirectoryListing('/mnt/tank');
      expect(listing, hasLength(1));
      expect(listing.first.name, 'file.txt');
    });

    test('queryDisks and getDiskById', () async {
      server.onMethod(
        'disk.query',
        (params) => params.value == null
            ? [
                {
                  'name': 'sda',
                  'model': 'WD',
                  'serial': 'ABC',
                  'size': 1000,
                  'used': 500,
                  'temperature': 30,
                  'health': 'OK',
                },
              ]
            : {'name': 'sda', 'id': params.asMap['id']},
      );

      final disks = await client.queryDisks();
      expect(disks, hasLength(1));

      final disk = await client.getDiskById('sda');
      expect(disk['name'], 'sda');
    });

    test('getNetworkInfo and getNetworkInterfaces', () async {
      server
        ..onMethod(
          'network.general.summary',
          (_) => {
            'download_speed': 100,
            'upload_speed': 50,
            'total_download': 1000,
            'total_upload': 500,
          },
        )
        ..onMethod(
          'interface.query',
          (_) => [
            {'name': 'eth0'},
          ],
        );

      final info = await client.getNetworkInfo();
      expect(info['download_speed'], 100);

      final interfaces = await client.getNetworkInterfaces();
      expect(interfaces, hasLength(1));
    });

    test('getServerHealth combines several RPCs into one summary', () async {
      server
        ..onMethod('system.info', (_) => <String, dynamic>{})
        ..onMethod('system.cpu_info', (_) => {'usage': 12.5})
        ..onMethod('system.memory_info', (_) => {'used': 50, 'total': 100})
        ..onMethod(
          'disk.query',
          (_) => [
            {
              'name': 'sda',
              'model': 'WD',
              'serial': 'ABC',
              'size': 1000,
              'used': 400,
              'temperature': 35,
              'health': 'OK',
            },
          ],
        )
        ..onMethod('system.temperature', (_) => 40.0)
        ..onMethod(
          'network.general.summary',
          (_) => {
            'download_speed': 10,
            'upload_speed': 5,
            'total_download': 100,
            'total_upload': 50,
          },
        );

      final health = await client.getServerHealth();

      expect(health.serverId, testServer.id);
      expect(health.cpuUsage, 12.5);
      expect(health.memoryUsage, 50.0);
      expect(health.diskUsage, 40.0);
      expect(health.temperature, 40);
      expect(health.isOnline, isTrue);
      expect(health.disks, hasLength(1));
      expect(health.network.downloadSpeed, 10);
    });

    test('testConnection returns true when the server responds', () async {
      server.onMethod('system.info', (_) => <String, dynamic>{});

      expect(await client.testConnection(), isTrue);
    });

    test('testConnection returns false when the server errors', () async {
      server.onMethod(
        'system.info',
        (_) => throw json_rpc.RpcException(500, 'boom'),
      );

      expect(await client.testConnection(), isFalse);
    });

    test('getAvailableApps and getAppCategories', () async {
      server
        ..onMethod(
          'app.available',
          (_) => [
            {
              'name': 'plex',
              'title': 'Plex',
              'description': 'Media server',
              'categories': ['media'],
            },
          ],
        )
        ..onMethod('app.categories', (_) => ['media', 'networking']);

      final apps = await client.getAvailableApps();
      expect(apps, hasLength(1));
      expect(apps.first.name, 'plex');

      final categories = await client.getAppCategories();
      expect(categories, ['media', 'networking']);
    });

    test('getInstalledApps converts the full TrueNAS app shape', () async {
      server.onMethod(
        'app.query',
        (_) => [
          {
            'name': 'plex',
            'state': 'RUNNING',
            'upgrade_available': true,
            'latest_version': '2.0.0',
            'version': '1.0.0',
            'human_version': '1.0.0_1',
            'resources': {
              'limits': {'memory': 512},
            },
            'active_workloads': {
              'used_ports': [
                {
                  'container_port': 80,
                  'protocol': 'tcp',
                  'host_ports': [
                    {'host_port': 8080, 'host_ip': '0.0.0.0'},
                  ],
                },
              ],
            },
            'portals': {'web': 'http://x/'},
            'metadata': {
              'title': 'Plex Media Server',
              'description': 'Stream your media',
              'app_version': '1.0.0',
              'icon': 'http://icon',
              'categories': ['media'],
              'home': 'https://plex.tv',
              'keywords': ['streaming'],
              'screenshots': ['http://shot'],
              'sources': ['http://src'],
              'maintainers': [
                {'name': 'truenas', 'email': 'a@b.c', 'url': 'http://x'},
              ],
              'train': 'stable',
            },
          },
          {'name': 'minimal-app', 'state': 'STOPPED'},
        ],
      );

      final apps = await client.getInstalledApps();

      expect(apps, hasLength(2));

      final plex = apps.firstWhere((a) => a.name == 'plex');
      expect(plex.title, 'Plex Media Server');
      expect(plex.healthy, isTrue);
      expect(plex.healthyError, isNull);
      expect(plex.upgradeInfo?.upgradeAvailable, isTrue);
      expect(plex.upgradeInfo?.canUpgrade, isTrue);
      expect(plex.resourceUsage?.memoryLimit, 512);
      expect(plex.usedPorts, hasLength(1));
      expect(plex.portals['web'], 'http://x/');
      expect(plex.categories, ['media']);
      expect(plex.maintainers, hasLength(1));
      expect(plex.train, 'stable');

      final minimal = apps.firstWhere((a) => a.name == 'minimal-app');
      expect(minimal.healthy, isFalse);
      expect(minimal.healthyError, 'App is stopped');
      expect(minimal.resourceUsage, isNull);
      expect(minimal.title, 'minimal-app');
      expect(minimal.train, 'community');
    });

    test('concurrent first calls share one connection and one login', () async {
      // AppProvider._loadAppsOnline issues these three calls in a single
      // Future.wait against a client that has never connected. Each call
      // funnels through _ensureAuthenticated/_ensureConnected, which must
      // coalesce into one WebSocket connection instead of racing and
      // clobbering each other's socket state.
      var loginCount = 0;
      server
        ..onMethod('auth.login', (_) {
          loginCount++;
          return true;
        })
        ..onMethod(
          'app.available',
          (_) => [
            {'name': 'plex', 'title': 'Plex'},
          ],
        )
        ..onMethod('app.categories', (_) => ['media'])
        ..onMethod(
          'app.query',
          (_) => [
            {'name': 'plex', 'state': 'RUNNING'},
          ],
        );

      final results = await Future.wait([
        client.getAvailableApps(),
        client.getInstalledApps(),
        client.getAppCategories(),
      ]);

      expect(results[0], hasLength(1));
      expect(results[1], hasLength(1));
      expect(results[2], ['media']);
      expect(server.connectionCount, 1);
      expect(loginCount, 1);
    });

    test('getDockerStatus returns the raw map', () async {
      server.onMethod('docker.status', (_) => {'status': 'RUNNING'});

      final status = await client.getDockerStatus();

      expect(status['status'], 'RUNNING');
    });

    test('getAppResourceUsage and getAppUpgradeInfo return stub data without '
        'a network call', () async {
      // These are documented as not backed by a TrueNAS RPC; verify they
      // resolve without ever talking to the (unconfigured) fake server.
      final usage = await client.getAppResourceUsage('plex');
      expect(usage['cpu_usage'], 0.0);

      final upgradeInfo = await client.getAppUpgradeInfo('plex');
      expect(upgradeInfo['upgrade_available'], false);
    });

    test(
      'upgradeApp, startApp, stopApp and restartApp report success',
      () async {
        server
          ..onMethod('app.upgrade', (_) => {'name': 'plex'})
          ..onMethod('app.start', (_) => {'name': 'plex'})
          ..onMethod('app.stop', (_) => {'name': 'plex'})
          ..onMethod('app.restart', (_) => {'name': 'plex'});

        expect(await client.upgradeApp('plex'), isTrue);
        expect(await client.startApp('plex'), isTrue);
        expect(await client.stopApp('plex'), isTrue);
        expect(await client.restartApp('plex'), isTrue);
      },
    );

    test(
      'upgradeApp, startApp, stopApp and restartApp report failure on error',
      () async {
        server
          ..onMethod(
            'app.upgrade',
            (_) => throw json_rpc.RpcException(500, 'boom'),
          )
          ..onMethod(
            'app.start',
            (_) => throw json_rpc.RpcException(500, 'boom'),
          )
          ..onMethod(
            'app.stop',
            (_) => throw json_rpc.RpcException(500, 'boom'),
          )
          ..onMethod(
            'app.restart',
            (_) => throw json_rpc.RpcException(500, 'boom'),
          );

        expect(await client.upgradeApp('plex'), isFalse);
        expect(await client.startApp('plex'), isFalse);
        expect(await client.stopApp('plex'), isFalse);
        expect(await client.restartApp('plex'), isFalse);
      },
    );

    test(
      'subscribeToSystemStats delivers realtime updates through the stream',
      () async {
        await client.subscribeToSystemStats();

        final statsFuture = client.systemStatsStream.first;

        server.lastPeer!.sendNotification('collection_update', {
          'collection': 'reporting.realtime',
          'fields': {
            'cpu': {
              'cpu': {'usage': 12.3, 'temp': 45.0},
            },
            'memory': {'physical_memory_total': 100},
            'zfs': <String, dynamic>{},
            'disks': <String, dynamic>{},
            'interfaces': <String, dynamic>{},
          },
        });

        final stats = await statsFuture.timeout(const Duration(seconds: 5));

        expect(stats.cpu.overall.usage, 12.3);
        expect(stats.memory.physicalMemoryTotal, 100);

        await client.unsubscribeFromSystemStats();
      },
    );

    test('subscribeToAppStats delivers per-app resource updates through the '
        'stream', () async {
      await client.subscribeToAppStats();

      final statsFuture = client.appStatsStream.first;

      server.lastPeer!.sendNotification('collection_update', {
        'collection': 'app.stats',
        'fields': [
          {
            'app_name': 'plex',
            'cpu_usage': 5.5,
            'memory': 2048,
            'networks': [
              {'rx_bytes': 10, 'tx_bytes': 20},
              {'rx_bytes': 5, 'tx_bytes': 5},
            ],
          },
        ],
      });

      final statsMap = await statsFuture.timeout(const Duration(seconds: 5));

      expect(statsMap['plex']!.cpuUsage, 5.5);
      expect(statsMap['plex']!.memoryUsage, 2048);
      expect(statsMap['plex']!.networkRxBytes, 15.0);
      expect(statsMap['plex']!.networkTxBytes, 25.0);

      await client.unsubscribeFromAppStats();
    });

    test('subscribeToSystemStats throws when the server refuses the '
        'subscription', () async {
      server.onMethod(
        'core.subscribe',
        (_) => throw json_rpc.RpcException(1, 'refused'),
      );

      await expectLater(
        client.subscribeToSystemStats(),
        throwsA(isA<Exception>()),
      );
    });

    test('keepalive starts once authenticated and stops on demand', () async {
      expect(client.isKeepaliveActive, isFalse);

      // Any authenticated call starts the keepalive timer.
      await client.getCurrentUser();
      expect(client.isKeepaliveActive, isTrue);

      // Changing the interval while active restarts the timer rather than
      // leaving it stopped.
      client.setKeepaliveInterval(const Duration(seconds: 5));
      expect(client.isKeepaliveActive, isTrue);

      client.enableKeepalive(false);
      expect(client.isKeepaliveActive, isFalse);

      client.enableKeepalive(true);
      expect(client.isKeepaliveActive, isTrue);
    });

    test(
      'ensureConnectionAlive bootstraps a connection from a fresh client',
      () async {
        // No prior connection exists yet, so ensureConnectionAlive has to
        // drive the full connect + authenticate flow itself rather than just
        // pinging an already-live socket.
        await client.ensureConnectionAlive();

        expect(client.isKeepaliveActive, isTrue);
      },
    );
  });

  group('TrueNasApiClient connection telemetry', () {
    late FakeTrueNasServer server;
    late NasServer testServer;

    NasServer serverFor(FakeTrueNasServer s) => NasServer(
      id: 'telemetry-fake-server',
      name: 'Telemetry Fake Server',
      host: '127.0.0.1',
      port: s.port,
      useHttps: false,
      username: 'root',
      password: 'password',
      localUrl: null,
      trustedWifiSsids: const [],
      isDefault: false,
    );

    setUp(() async {
      server = await FakeTrueNasServer.start();
      testServer = serverFor(server);
    });

    tearDown(() async {
      await server.stop();
    });

    test('a successful connect produces a truenas.connect span with '
        'StatusCode.ok and the expected attributes', () async {
      final telemetry = FakeTelemetryService();
      final client = TrueNasApiClient(testServer, null, telemetry);
      addTearDown(client.close);

      // getCurrentUser() drives _ensureAuthenticated -> _ensureConnected.
      await client.getCurrentUser();

      expect(telemetry.spans, hasLength(1));
      final span = telemetry.spans.single;
      expect(span.name, 'truenas.connect');
      expect(span.kind, SpanKind.client);
      expect(span.attributes['server.id'], testServer.id);
      expect(span.attributes['server.network.trusted'], isFalse);
      expect(span.status, StatusCode.ok);
      expect(span.isEnded, isTrue);
      expect(telemetry.tracerNames, isNotEmpty);
    });

    test(
      'a failed connect produces an error span and still calls the logger',
      () async {
        // Nothing listens on this server's port once it has been stopped,
        // so the connect attempt fails deterministically - same technique
        // the plain (non-telemetry) failure test above uses.
        await server.stop();

        final telemetry = FakeTelemetryService();
        final deadClient = TrueNasApiClient(testServer, null, telemetry);
        addTearDown(deadClient.close);

        final result = await deadClient.validateLogin('root', 'password');

        expect(result, isFalse);
        expect(telemetry.spans, hasLength(1));
        final span = telemetry.spans.single;
        expect(span.name, 'truenas.connect');
        expect(span.status, StatusCode.error);
        expect(span.exceptions, isNotEmpty);
        expect(span.isEnded, isTrue);
        // The catch block in _ensureConnectedTraced logs the failure too.
        expect(telemetry.loggerNames, isNotEmpty);
      },
    );

    test('passing telemetry: null behaves identically to the untraced client '
        '(no crash, same success/failure outcomes)', () async {
      final client = TrueNasApiClient(testServer);
      addTearDown(client.close);

      await client.getCurrentUser();
      expect(client.isKeepaliveActive, isTrue);
    });

    test('getAvailableApps produces a truenas.apps.available span with '
        'StatusCode.ok', () async {
      server.onMethod(
        'app.available',
        (_) => [
          {'name': 'plex', 'title': 'Plex'},
        ],
      );

      final telemetry = FakeTelemetryService();
      final client = TrueNasApiClient(testServer, null, telemetry);
      addTearDown(client.close);

      await client.getAvailableApps();

      final span = telemetry.spans.singleWhere(
        (s) => s.name == 'truenas.apps.available',
      );
      expect(span.kind, SpanKind.client);
      expect(span.attributes['server.id'], testServer.id);
      expect(span.status, StatusCode.ok);
      expect(span.isEnded, isTrue);
    });

    test(
      'a response that fails to parse produces an error span and logs the '
      'failure, instead of surfacing only as a generic connection error '
      'with no diagnostic trail - this is the gap that let two separate '
      "TrueNAS response-shape bugs (App.last_update, then "
      'AppResourceUsage.last_updated) go unnoticed by the connect-only span',
      () async {
        server.onMethod(
          'app.available',
          // 'maintainers' entries are expected to be maps (see
          // AppMaintainer.fromJson); a string here reproduces the same
          // "unexpected response shape" class of failure as the
          // last_update/last_updated bugs.
          (_) => [
            {
              'name': 'plex',
              'maintainers': ['not-a-map'],
            },
          ],
        );

        final telemetry = FakeTelemetryService();
        final client = TrueNasApiClient(testServer, null, telemetry);
        addTearDown(client.close);

        await expectLater(client.getAvailableApps(), throwsException);

        final span = telemetry.spans.singleWhere(
          (s) => s.name == 'truenas.apps.available',
        );
        expect(span.status, StatusCode.error);
        expect(span.exceptions, isNotEmpty);
        expect(span.isEnded, isTrue);
        expect(telemetry.loggerNames, isNotEmpty);
      },
    );
  });
}
