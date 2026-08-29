import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/app.dart';

void main() {
  group('App Model Tests', () {
    test('should create App from JSON correctly', () {
      final json = {
        'name': 'test-app',
        'title': 'Test App',
        'description': 'A test application',
        'installed': true,
        'healthy': true,
        'latest_version': '1.0.0',
        'latest_app_version': '1.0.0',
        'latest_human_version': '1.0.0',
        'icon_url': 'https://example.com/icon.png',
        'categories': ['test', 'demo'],
        'home': 'https://example.com',
        'tags': ['test', 'demo', 'sample'],
        'screenshots': ['https://example.com/screenshot1.png'],
        'sources': ['https://github.com/test/app'],
        'app_readme': '<h1>Test App</h1><p>A test application</p>',
        'maintainers': [
          {
            'name': 'Test Dev',
            'email': 'test@example.com',
            'url': 'https://example.com',
          },
        ],
        'recommended': false,
        'catalog': 'TEST',
        'train': 'stable',
      };

      final app = App.fromJson(json);

      expect(app.name, equals('test-app'));
      expect(app.title, equals('Test App'));
      expect(app.description, equals('A test application'));
      expect(app.installed, equals(true));
      expect(app.healthy, equals(true));
      expect(app.latestVersion, equals('1.0.0'));
      expect(app.latestAppVersion, equals('1.0.0'));
      expect(app.latestHumanVersion, equals('1.0.0'));
      expect(app.iconUrl, equals('https://example.com/icon.png'));
      expect(app.categories, equals(['test', 'demo']));
      expect(app.home, equals('https://example.com'));
      expect(app.tags, equals(['test', 'demo', 'sample']));
      expect(app.screenshots, equals(['https://example.com/screenshot1.png']));
      expect(app.sources, equals(['https://github.com/test/app']));
      expect(
        app.appReadme,
        equals('<h1>Test App</h1><p>A test application</p>'),
      );
      expect(app.maintainers.length, equals(1));
      expect(app.maintainers.first.name, equals('Test Dev'));
      expect(app.recommended, equals(false));
      expect(app.catalog, equals('TEST'));
      expect(app.train, equals('stable'));
    });

    test('should handle missing optional fields in JSON', () {
      final json = {
        'name': 'minimal-app',
        'title': 'Minimal App',
        'description': 'A minimal app',
        'latest_version': '1.0.0',
        'latest_app_version': '1.0.0',
        'latest_human_version': '1.0.0',
        'recommended': false,
        'catalog': 'TEST',
        'train': 'stable',
      };

      final app = App.fromJson(json);

      expect(app.name, equals('minimal-app'));
      expect(app.title, equals('Minimal App'));
      expect(app.installed, equals(false));
      expect(app.healthy, equals(true));
      expect(app.healthyError, isNull);
      expect(app.iconUrl, isNull);
      expect(app.categories, isEmpty);
      expect(app.home, isNull);
      expect(app.tags, isEmpty);
      expect(app.screenshots, isEmpty);
      expect(app.sources, isEmpty);
      expect(app.appReadme, isNull);
      expect(app.maintainers, isEmpty);
    });

    test('should convert App to JSON correctly', () {
      const app = App(
        name: 'test-app',
        title: 'Test App',
        description: 'A test application',
        installed: true,
        healthy: false,
        healthyError: 'Service unavailable',
        latestVersion: '1.0.0',
        latestAppVersion: '1.0.0',
        latestHumanVersion: '1.0.0',
        iconUrl: 'https://example.com/icon.png',
        categories: ['test', 'demo'],
        home: 'https://example.com',
        tags: ['test', 'demo', 'sample'],
        screenshots: ['https://example.com/screenshot1.png'],
        sources: ['https://github.com/test/app'],
        appReadme: '<h1>Test App</h1><p>A test application</p>',
        maintainers: [],
        recommended: false,
        catalog: 'TEST',
        train: 'stable',
        usedPorts: [],
        portals: {},
        customDisplayName: 'Custom Test App',
        customIconUrl: 'https://example.com/custom-icon.png',
        primaryCustomUrl: 'https://custom.example.com',
      );

      final json = app.toJson();

      expect(json['name'], equals('test-app'));
      expect(json['title'], equals('Test App'));
      expect(json['description'], equals('A test application'));
      expect(json['installed'], equals(true));
      expect(json['healthy'], equals(false));
      expect(json['healthy_error'], equals('Service unavailable'));
      expect(json['latest_version'], equals('1.0.0'));
      expect(json['latest_app_version'], equals('1.0.0'));
      expect(json['latest_human_version'], equals('1.0.0'));
      expect(json['icon_url'], equals('https://example.com/icon.png'));
      expect(json['categories'], equals(['test', 'demo']));
      expect(json['home'], equals('https://example.com'));
      expect(json['tags'], equals(['test', 'demo', 'sample']));
      expect(
        json['screenshots'],
        equals(['https://example.com/screenshot1.png']),
      );
      expect(json['sources'], equals(['https://github.com/test/app']));
      expect(
        json['app_readme'],
        equals('<h1>Test App</h1><p>A test application</p>'),
      );
      expect(json['recommended'], equals(false));
      expect(json['catalog'], equals('TEST'));
      expect(json['train'], equals('stable'));
    });

    test('equality holds for equal instances and differs on change', () {
      const a = App(
        name: 'app',
        title: 'App',
        description: 'desc',
        installed: false,
        healthy: true,
        latestVersion: '1.0',
        latestAppVersion: '1.0',
        latestHumanVersion: '1.0',
        categories: [],
        tags: [],
        screenshots: [],
        sources: [],
        maintainers: [],
        recommended: false,
        catalog: 'TEST',
        train: 'stable',
        usedPorts: [],
        portals: {},
      );
      const b = App(
        name: 'app',
        title: 'App',
        description: 'desc',
        installed: false,
        healthy: true,
        latestVersion: '1.0',
        latestAppVersion: '1.0',
        latestHumanVersion: '1.0',
        categories: [],
        tags: [],
        screenshots: [],
        sources: [],
        maintainers: [],
        recommended: false,
        catalog: 'TEST',
        train: 'stable',
        usedPorts: [],
        portals: {},
      );
      const c = App(
        name: 'other-app',
        title: 'App',
        description: 'desc',
        installed: false,
        healthy: true,
        latestVersion: '1.0',
        latestAppVersion: '1.0',
        latestHumanVersion: '1.0',
        categories: [],
        tags: [],
        screenshots: [],
        sources: [],
        maintainers: [],
        recommended: false,
        catalog: 'TEST',
        train: 'stable',
        usedPorts: [],
        portals: {},
      );

      expect(a, equals(b));
      expect(a == c, isFalse);
    });

    test('fromJson parses last_update from a Mongo-style \$date payload', () {
      final json = {
        'name': 'app',
        'title': 'App',
        'description': 'desc',
        'recommended': false,
        'catalog': 'TEST',
        'train': 'stable',
        'last_update': {'\$date': 1700000000000},
      };

      final app = App.fromJson(json);

      expect(
        app.lastUpdate,
        equals(DateTime.fromMillisecondsSinceEpoch(1700000000000)),
      );
    });

    test(
      'fromJson parses resource_usage, upgrade_info, used_ports and portals',
      () {
        final json = {
          'name': 'app',
          'title': 'App',
          'description': 'desc',
          'recommended': false,
          'catalog': 'TEST',
          'train': 'stable',
          'resource_usage': {
            'cpu_usage': 12.5,
            'memory_usage': 1024,
            'memory_limit': 2048,
            'network_rx_bytes': 100.0,
            'network_tx_bytes': 50.0,
            'last_updated': '2024-01-01T00:00:00.000Z',
          },
          'upgrade_info': {
            'upgrade_available': true,
            'available_version': '2.0',
            'current_version': '1.0',
            'upgrade_notes': 'fixes',
            'can_upgrade': true,
          },
          'used_ports': [
            {
              'container_port': 8080,
              'protocol': 'tcp',
              'host_ports': [
                {'host_port': 80, 'host_ip': '0.0.0.0'},
              ],
            },
          ],
          'portals': {'web': 'https://example.com'},
          'custom_display_name': 'My App',
          'custom_icon_url': 'https://example.com/custom.png',
          'primary_custom_url': 'https://custom.example.com',
        };

        final app = App.fromJson(json);

        expect(app.resourceUsage, isNotNull);
        expect(app.resourceUsage!.cpuUsage, equals(12.5));
        expect(app.resourceUsage!.memoryUsage, equals(1024));
        expect(app.upgradeInfo, isNotNull);
        expect(app.upgradeInfo!.upgradeAvailable, isTrue);
        expect(app.upgradeInfo!.availableVersion, equals('2.0'));
        expect(app.usedPorts, hasLength(1));
        expect(app.usedPorts.first.containerPort, equals(8080));
        expect(app.usedPorts.first.hostPorts.first.hostPort, equals(80));
        expect(app.portals, equals({'web': 'https://example.com'}));
        expect(app.customDisplayName, equals('My App'));
        expect(app.customIconUrl, equals('https://example.com/custom.png'));
        expect(app.primaryCustomUrl, equals('https://custom.example.com'));
      },
    );

    test(
      'fromJson defaults resource_usage/upgrade_info/last_update/ports to null/empty',
      () {
        final json = {
          'name': 'app',
          'title': 'App',
          'description': 'desc',
          'recommended': false,
          'catalog': 'TEST',
          'train': 'stable',
        };

        final app = App.fromJson(json);

        expect(app.resourceUsage, isNull);
        expect(app.upgradeInfo, isNull);
        expect(app.lastUpdate, isNull);
        expect(app.usedPorts, isEmpty);
        expect(app.portals, isEmpty);
        expect(app.customDisplayName, isNull);
        expect(app.customIconUrl, isNull);
        expect(app.primaryCustomUrl, isNull);
      },
    );

    test('toJson emits last_update using the Mongo-style \$date shape', () {
      final app = App(
        name: 'app',
        title: 'App',
        description: 'desc',
        installed: false,
        healthy: true,
        latestVersion: '1.0',
        latestAppVersion: '1.0',
        latestHumanVersion: '1.0',
        categories: const [],
        tags: const [],
        screenshots: const [],
        sources: const [],
        maintainers: const [],
        lastUpdate: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        recommended: false,
        catalog: 'TEST',
        train: 'stable',
        usedPorts: const [],
        portals: const {},
      );

      final json = app.toJson();

      expect(json['last_update'], equals({'\$date': 1700000000000}));
    });

    test('toJson emits null last_update when lastUpdate is null', () {
      const app = App(
        name: 'app',
        title: 'App',
        description: 'desc',
        installed: false,
        healthy: true,
        latestVersion: '1.0',
        latestAppVersion: '1.0',
        latestHumanVersion: '1.0',
        categories: [],
        tags: [],
        screenshots: [],
        sources: [],
        maintainers: [],
        recommended: false,
        catalog: 'TEST',
        train: 'stable',
        usedPorts: [],
        portals: {},
      );

      expect(app.toJson()['last_update'], isNull);
    });
  });

  group('App.effectiveDisplayName', () {
    App buildApp({
      bool installed = false,
      String? customDisplayName,
      String title = 'Title',
      String name = 'app-name',
    }) => App(
      name: name,
      title: title,
      description: '',
      installed: installed,
      healthy: true,
      latestVersion: '',
      latestAppVersion: '',
      latestHumanVersion: '',
      categories: const [],
      tags: const [],
      screenshots: const [],
      sources: const [],
      maintainers: const [],
      recommended: false,
      catalog: '',
      train: '',
      usedPorts: const [],
      portals: const {},
      customDisplayName: customDisplayName,
    );

    test('prefers customDisplayName when set', () {
      final app = buildApp(customDisplayName: 'Custom Name');
      expect(app.effectiveDisplayName, equals('Custom Name'));
    });

    test('uses the instance name when installed and no custom name', () {
      final app = buildApp(installed: true, name: 'instance-1');
      expect(app.effectiveDisplayName, equals('instance-1'));
    });

    test('uses title when not installed and no custom name', () {
      final app = buildApp(installed: false, title: 'Catalog Title');
      expect(app.effectiveDisplayName, equals('Catalog Title'));
    });
  });

  group('App.effectiveIconUrl', () {
    App buildApp({String? iconUrl, String? customIconUrl}) => App(
      name: 'app',
      title: 'App',
      description: '',
      installed: false,
      healthy: true,
      latestVersion: '',
      latestAppVersion: '',
      latestHumanVersion: '',
      iconUrl: iconUrl,
      categories: const [],
      tags: const [],
      screenshots: const [],
      sources: const [],
      maintainers: const [],
      recommended: false,
      catalog: '',
      train: '',
      usedPorts: const [],
      portals: const {},
      customIconUrl: customIconUrl,
    );

    test('prefers customIconUrl over iconUrl', () {
      final app = buildApp(
        iconUrl: 'https://example.com/icon.png',
        customIconUrl: 'https://example.com/custom.png',
      );
      expect(app.effectiveIconUrl, equals('https://example.com/custom.png'));
    });

    test('falls back to iconUrl when customIconUrl is null', () {
      final app = buildApp(iconUrl: 'https://example.com/icon.png');
      expect(app.effectiveIconUrl, equals('https://example.com/icon.png'));
    });

    test('is null when neither is set', () {
      final app = buildApp();
      expect(app.effectiveIconUrl, isNull);
    });
  });

  group('App.primaryUrl', () {
    App buildApp({
      String? primaryCustomUrl,
      Map<String, String> portals = const {},
    }) => App(
      name: 'app',
      title: 'App',
      description: '',
      installed: false,
      healthy: true,
      latestVersion: '',
      latestAppVersion: '',
      latestHumanVersion: '',
      categories: const [],
      tags: const [],
      screenshots: const [],
      sources: const [],
      maintainers: const [],
      recommended: false,
      catalog: '',
      train: '',
      usedPorts: const [],
      portals: portals,
      primaryCustomUrl: primaryCustomUrl,
    );

    test('prefers primaryCustomUrl when set', () {
      final app = buildApp(
        primaryCustomUrl: 'https://custom.example.com',
        portals: const {'web': 'https://portal.example.com'},
      );
      expect(app.primaryUrl, equals('https://custom.example.com'));
    });

    test('falls back to the first portal URL when no custom URL is set', () {
      final app = buildApp(
        portals: const {'web': 'https://portal.example.com'},
      );
      expect(app.primaryUrl, equals('https://portal.example.com'));
    });

    test('is null when there is no custom URL and no portals', () {
      final app = buildApp();
      expect(app.primaryUrl, isNull);
    });
  });

  group('AppMaintainer', () {
    test('fromJson parses a full payload', () {
      final maintainer = AppMaintainer.fromJson({
        'name': 'Dev',
        'email': 'dev@example.com',
        'url': 'https://example.com',
      });
      expect(maintainer.name, equals('Dev'));
      expect(maintainer.email, equals('dev@example.com'));
      expect(maintainer.url, equals('https://example.com'));
    });

    test('fromJson applies empty-string defaults for missing fields', () {
      final maintainer = AppMaintainer.fromJson({});
      expect(maintainer.name, equals(''));
      expect(maintainer.email, equals(''));
      expect(maintainer.url, equals(''));
    });

    test('toJson round-trips', () {
      const maintainer = AppMaintainer(
        name: 'Dev',
        email: 'dev@example.com',
        url: 'https://example.com',
      );
      final roundTripped = AppMaintainer.fromJson(maintainer.toJson());
      expect(roundTripped, equals(maintainer));
    });

    test('equality holds for equal instances and differs on change', () {
      const a = AppMaintainer(
        name: 'Dev',
        email: 'a@x.com',
        url: 'https://x.com',
      );
      const b = AppMaintainer(
        name: 'Dev',
        email: 'a@x.com',
        url: 'https://x.com',
      );
      const c = AppMaintainer(
        name: 'Other',
        email: 'a@x.com',
        url: 'https://x.com',
      );
      expect(a, equals(b));
      expect(a == c, isFalse);
    });
  });

  group('AppResourceUsage', () {
    test('fromJson parses a full payload', () {
      final usage = AppResourceUsage.fromJson({
        'cpu_usage': 25.5,
        'memory_usage': 512,
        'memory_limit': 1024,
        'network_rx_bytes': 100.0,
        'network_tx_bytes': 50.0,
        'last_updated': '2024-01-01T00:00:00.000Z',
      });

      expect(usage.cpuUsage, equals(25.5));
      expect(usage.memoryUsage, equals(512));
      expect(usage.memoryLimit, equals(1024));
      expect(usage.networkRxBytes, equals(100.0));
      expect(usage.networkTxBytes, equals(50.0));
      expect(
        usage.lastUpdated,
        equals(DateTime.parse('2024-01-01T00:00:00.000Z')),
      );
    });

    test('fromJson applies defaults for missing fields', () {
      final usage = AppResourceUsage.fromJson({});
      expect(usage.cpuUsage, equals(0.0));
      expect(usage.memoryUsage, equals(0));
      expect(usage.memoryLimit, equals(0));
      expect(usage.networkRxBytes, equals(0.0));
      expect(usage.networkTxBytes, equals(0.0));
      expect(usage.lastUpdated, isNull);
    });

    test('toJson round-trips', () {
      final usage = AppResourceUsage.fromJson({
        'cpu_usage': 1.0,
        'memory_usage': 2,
        'memory_limit': 3,
        'network_rx_bytes': 4.0,
        'network_tx_bytes': 5.0,
      });
      final roundTripped = AppResourceUsage.fromJson(usage.toJson());
      expect(roundTripped, equals(usage));
    });

    test('equality holds for equal instances and differs on change', () {
      const a = AppResourceUsage(
        cpuUsage: 1,
        memoryUsage: 2,
        memoryLimit: 3,
        networkRxBytes: 4,
        networkTxBytes: 5,
      );
      const b = AppResourceUsage(
        cpuUsage: 1,
        memoryUsage: 2,
        memoryLimit: 3,
        networkRxBytes: 4,
        networkTxBytes: 5,
      );
      const c = AppResourceUsage(
        cpuUsage: 9,
        memoryUsage: 2,
        memoryLimit: 3,
        networkRxBytes: 4,
        networkTxBytes: 5,
      );
      expect(a, equals(b));
      expect(a == c, isFalse);
    });
  });

  group('AppHostPort', () {
    test('fromJson parses a full payload', () {
      final port = AppHostPort.fromJson({
        'host_port': 8080,
        'host_ip': '1.2.3.4',
      });
      expect(port.hostPort, equals(8080));
      expect(port.hostIp, equals('1.2.3.4'));
    });

    test('fromJson applies defaults for missing fields', () {
      final port = AppHostPort.fromJson({});
      expect(port.hostPort, equals(0));
      expect(port.hostIp, equals('0.0.0.0'));
    });

    test('toJson round-trips', () {
      const port = AppHostPort(hostPort: 80, hostIp: '0.0.0.0');
      final roundTripped = AppHostPort.fromJson(port.toJson());
      expect(roundTripped, equals(port));
    });

    test('equality holds for equal instances and differs on change', () {
      const a = AppHostPort(hostPort: 80, hostIp: '0.0.0.0');
      const b = AppHostPort(hostPort: 80, hostIp: '0.0.0.0');
      const c = AppHostPort(hostPort: 81, hostIp: '0.0.0.0');
      expect(a, equals(b));
      expect(a == c, isFalse);
    });
  });

  group('AppPortInfo', () {
    test('fromJson parses a full payload with nested host ports', () {
      final port = AppPortInfo.fromJson({
        'container_port': 8080,
        'protocol': 'udp',
        'host_ports': [
          {'host_port': 80, 'host_ip': '0.0.0.0'},
          {'host_port': 443, 'host_ip': '::'},
        ],
      });
      expect(port.containerPort, equals(8080));
      expect(port.protocol, equals('udp'));
      expect(port.hostPorts, hasLength(2));
      expect(port.hostPorts.first.hostPort, equals(80));
    });

    test('fromJson applies defaults for missing fields', () {
      final port = AppPortInfo.fromJson({});
      expect(port.containerPort, equals(0));
      expect(port.protocol, equals('tcp'));
      expect(port.hostPorts, isEmpty);
    });

    test('toJson round-trips', () {
      final port = AppPortInfo.fromJson({
        'container_port': 80,
        'protocol': 'tcp',
        'host_ports': [
          {'host_port': 80, 'host_ip': '0.0.0.0'},
        ],
      });
      final roundTripped = AppPortInfo.fromJson(port.toJson());
      expect(roundTripped, equals(port));
    });

    test('equality holds for equal instances and differs on change', () {
      const a = AppPortInfo(containerPort: 80, protocol: 'tcp', hostPorts: []);
      const b = AppPortInfo(containerPort: 80, protocol: 'tcp', hostPorts: []);
      const c = AppPortInfo(containerPort: 81, protocol: 'tcp', hostPorts: []);
      expect(a, equals(b));
      expect(a == c, isFalse);
    });
  });

  group('AppUpgradeInfo', () {
    test('fromJson parses a full payload', () {
      final info = AppUpgradeInfo.fromJson({
        'upgrade_available': true,
        'available_version': '2.0',
        'current_version': '1.0',
        'upgrade_notes': 'notes',
        'can_upgrade': true,
      });
      expect(info.upgradeAvailable, isTrue);
      expect(info.availableVersion, equals('2.0'));
      expect(info.currentVersion, equals('1.0'));
      expect(info.upgradeNotes, equals('notes'));
      expect(info.canUpgrade, isTrue);
    });

    test('fromJson applies defaults for missing fields', () {
      final info = AppUpgradeInfo.fromJson({});
      expect(info.upgradeAvailable, isFalse);
      expect(info.availableVersion, isNull);
      expect(info.currentVersion, isNull);
      expect(info.upgradeNotes, isNull);
      expect(info.canUpgrade, isFalse);
    });

    test('toJson round-trips', () {
      const info = AppUpgradeInfo(
        upgradeAvailable: true,
        availableVersion: '2.0',
        currentVersion: '1.0',
        upgradeNotes: 'notes',
        canUpgrade: true,
      );
      final roundTripped = AppUpgradeInfo.fromJson(info.toJson());
      expect(roundTripped, equals(info));
    });

    test('equality holds for equal instances and differs on change', () {
      const a = AppUpgradeInfo(upgradeAvailable: true, canUpgrade: true);
      const b = AppUpgradeInfo(upgradeAvailable: true, canUpgrade: true);
      const c = AppUpgradeInfo(upgradeAvailable: false, canUpgrade: true);
      expect(a, equals(b));
      expect(a == c, isFalse);
    });
  });
}
