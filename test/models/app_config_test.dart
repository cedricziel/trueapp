import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/models/app_config.dart';

void main() {
  group('AppPortConfig', () {
    test('defaults apply when optional fields are omitted', () {
      const port = AppPortConfig(portNumber: 8080);
      expect(port.id, isNull);
      expect(port.protocol, equals('http'));
      expect(port.serviceName, isNull);
      expect(port.customUrl, isNull);
      expect(port.apiUrl, isNull);
      expect(port.isPrimary, isFalse);
      expect(port.isEnabled, isTrue);
    });

    test('defaultUrl builds from protocol and port number', () {
      const port = AppPortConfig(portNumber: 9000, protocol: 'https');
      expect(port.defaultUrl, equals('https://localhost:9000'));
    });

    test('effectiveUrl prefers customUrl, then apiUrl, then defaultUrl', () {
      const withCustom = AppPortConfig(
        portNumber: 80,
        customUrl: 'https://custom.example.com',
        apiUrl: 'https://api.example.com',
      );
      expect(withCustom.effectiveUrl, equals('https://custom.example.com'));

      const withApiOnly = AppPortConfig(
        portNumber: 80,
        apiUrl: 'https://api.example.com',
      );
      expect(withApiOnly.effectiveUrl, equals('https://api.example.com'));

      const withNeither = AppPortConfig(portNumber: 80);
      expect(withNeither.effectiveUrl, equals('http://localhost:80'));
    });

    test('displayName falls back to Port N when serviceName is null', () {
      const named = AppPortConfig(portNumber: 80, serviceName: 'Web UI');
      expect(named.displayName, equals('Web UI'));

      const unnamed = AppPortConfig(portNumber: 80);
      expect(unnamed.displayName, equals('Port 80'));
    });

    test('copyWith overrides only provided fields', () {
      const original = AppPortConfig(
        id: 1,
        portNumber: 80,
        protocol: 'http',
        serviceName: 'svc',
        customUrl: 'url',
        apiUrl: 'api',
        isPrimary: false,
        isEnabled: true,
      );

      final updated = original.copyWith(portNumber: 443, isPrimary: true);

      expect(updated.id, equals(1));
      expect(updated.portNumber, equals(443));
      expect(updated.protocol, equals('http'));
      expect(updated.serviceName, equals('svc'));
      expect(updated.customUrl, equals('url'));
      expect(updated.apiUrl, equals('api'));
      expect(updated.isPrimary, isTrue);
      expect(updated.isEnabled, isTrue);
    });

    test('equality holds for equal instances and differs on change', () {
      const a = AppPortConfig(portNumber: 80);
      const b = AppPortConfig(portNumber: 80);
      const c = AppPortConfig(portNumber: 81);
      expect(a, equals(b));
      expect(a == c, isFalse);
    });
  });

  group('AppConfig', () {
    AppConfig buildMinimal() =>
        const AppConfig(serverId: 'server-1', appName: 'plex');

    test('defaults apply for a minimal construction', () {
      final config = buildMinimal();
      expect(config.id, isNull);
      expect(config.displayName, isNull);
      expect(config.isEnabled, isTrue);
      expect(config.isFavorite, isFalse);
      expect(config.ports, isEmpty);
      expect(config.createdAt, isNull);
      expect(config.updatedAt, isNull);
      expect(config.maintainers, isEmpty);
      expect(config.upgradeInfo, isNull);
      expect(config.usedPorts, isEmpty);
    });

    test('effectiveDisplayName prefers displayName, then title, then appName', () {
      const withDisplayName = AppConfig(
        serverId: 's',
        appName: 'app',
        displayName: 'Custom',
        title: 'Title',
      );
      expect(withDisplayName.effectiveDisplayName, equals('Custom'));

      const withTitleOnly = AppConfig(
        serverId: 's',
        appName: 'app',
        title: 'Title',
      );
      expect(withTitleOnly.effectiveDisplayName, equals('Title'));

      const withNeither = AppConfig(serverId: 's', appName: 'app');
      expect(withNeither.effectiveDisplayName, equals('app'));
    });

    test('primaryPort returns the primary enabled port when present', () {
      const primary = AppPortConfig(
        portNumber: 443,
        isPrimary: true,
        isEnabled: true,
      );
      const secondary = AppPortConfig(portNumber: 80, isEnabled: true);
      final config = AppConfig(
        serverId: 's',
        appName: 'app',
        ports: [secondary, primary],
      );

      expect(config.primaryPort, equals(primary));
    });

    test(
      'primaryPort falls back to the first port when no port is primary+enabled',
      () {
        const first = AppPortConfig(portNumber: 80, isEnabled: true);
        const second = AppPortConfig(portNumber: 81, isEnabled: true);
        final config = AppConfig(
          serverId: 's',
          appName: 'app',
          ports: [first, second],
        );

        expect(config.primaryPort, equals(first));
      },
    );

    test('primaryPort returns null when there are no ports at all', () {
      final config = buildMinimal();
      expect(config.primaryPort, isNull);
    });

    test('enabledPorts filters out disabled ports', () {
      const enabled = AppPortConfig(portNumber: 80, isEnabled: true);
      const disabled = AppPortConfig(portNumber: 81, isEnabled: false);
      final config = AppConfig(
        serverId: 's',
        appName: 'app',
        ports: [enabled, disabled],
      );

      expect(config.enabledPorts, equals([enabled]));
    });

    test('maintainers decodes a valid maintainersJson', () {
      final json = jsonEncode([
        {'name': 'Dev', 'email': 'dev@example.com', 'url': 'https://x.com'},
      ]);
      final config = AppConfig(
        serverId: 's',
        appName: 'app',
        maintainersJson: json,
      );

      expect(config.maintainers.length, equals(1));
      expect(config.maintainers.first.name, equals('Dev'));
    });

    test('maintainers returns empty list when maintainersJson is null', () {
      final config = buildMinimal();
      expect(config.maintainers, isEmpty);
    });

    test('maintainers returns empty list when maintainersJson is malformed', () {
      final config = AppConfig(
        serverId: 's',
        appName: 'app',
        maintainersJson: 'not-json',
      );
      expect(config.maintainers, isEmpty);
    });

    test('upgradeInfo decodes a valid upgradeInfoJson', () {
      final json = jsonEncode({
        'upgrade_available': true,
        'available_version': '2.0',
        'current_version': '1.0',
        'upgrade_notes': 'notes',
        'can_upgrade': true,
      });
      final config = AppConfig(
        serverId: 's',
        appName: 'app',
        upgradeInfoJson: json,
      );

      expect(config.upgradeInfo, isNotNull);
      expect(config.upgradeInfo!.upgradeAvailable, isTrue);
      expect(config.upgradeInfo!.availableVersion, equals('2.0'));
    });

    test('upgradeInfo returns null when upgradeInfoJson is null', () {
      final config = buildMinimal();
      expect(config.upgradeInfo, isNull);
    });

    test('upgradeInfo returns null when upgradeInfoJson is malformed', () {
      final config = AppConfig(
        serverId: 's',
        appName: 'app',
        upgradeInfoJson: '{invalid',
      );
      expect(config.upgradeInfo, isNull);
    });

    test('usedPorts decodes a valid usedPortsJson', () {
      final json = jsonEncode([
        {
          'container_port': 80,
          'protocol': 'tcp',
          'host_ports': [
            {'host_port': 8080, 'host_ip': '0.0.0.0'},
          ],
        },
      ]);
      final config = AppConfig(
        serverId: 's',
        appName: 'app',
        usedPortsJson: json,
      );

      expect(config.usedPorts.length, equals(1));
      expect(config.usedPorts.first.containerPort, equals(80));
      expect(config.usedPorts.first.hostPorts.first.hostPort, equals(8080));
    });

    test('usedPorts returns empty list when usedPortsJson is null', () {
      final config = buildMinimal();
      expect(config.usedPorts, isEmpty);
    });

    test('usedPorts returns empty list when usedPortsJson is malformed', () {
      final config = AppConfig(
        serverId: 's',
        appName: 'app',
        usedPortsJson: 'nope',
      );
      expect(config.usedPorts, isEmpty);
    });

    App buildApp() => const App(
      name: 'plex',
      title: 'Plex',
      description: 'Media server',
      installed: true,
      healthy: true,
      latestVersion: '1.0.0',
      latestAppVersion: '1.0.0',
      latestHumanVersion: '1.0.0',
      iconUrl: 'https://example.com/icon.png',
      categories: ['media'],
      tags: ['media'],
      screenshots: [],
      sources: [],
      maintainers: [
        AppMaintainer(name: 'Dev', email: 'dev@example.com', url: 'https://x.com'),
      ],
      recommended: true,
      catalog: 'TRUENAS',
      train: 'stable',
      upgradeInfo: AppUpgradeInfo(upgradeAvailable: true, canUpgrade: true),
      usedPorts: [
        AppPortInfo(containerPort: 32400, protocol: 'tcp', hostPorts: []),
      ],
      portals: {},
    );

    test('fromApp copies fields from an App and encodes JSON helper fields', () {
      final config = AppConfig.fromApp(serverId: 'server-1', app: buildApp());

      expect(config.serverId, equals('server-1'));
      expect(config.appName, equals('plex'));
      expect(config.iconUrl, equals('https://example.com/icon.png'));
      expect(config.title, equals('Plex'));
      expect(config.installed, isTrue);
      expect(config.healthy, isTrue);
      expect(config.version, equals('1.0.0'));
      expect(config.categories, equals(['media']));
      expect(config.recommended, isTrue);
      expect(config.catalog, equals('TRUENAS'));
      expect(config.train, equals('stable'));
      expect(config.maintainersJson, isNotNull);
      expect(config.maintainers.first.name, equals('Dev'));
      expect(config.upgradeInfoJson, isNotNull);
      expect(config.upgradeInfo!.upgradeAvailable, isTrue);
      expect(config.usedPortsJson, isNotNull);
      expect(config.usedPorts.first.containerPort, equals(32400));
      expect(config.createdAt, isNotNull);
      expect(config.updatedAt, isNotNull);
    });

    test('fromApp leaves JSON helper fields null when App has empty lists', () {
      const emptyApp = App(
        name: 'app',
        title: 'App',
        description: '',
        installed: false,
        healthy: true,
        latestVersion: '',
        latestAppVersion: '',
        latestHumanVersion: '',
        categories: [],
        tags: [],
        screenshots: [],
        sources: [],
        maintainers: [],
        recommended: false,
        catalog: '',
        train: '',
        usedPorts: [],
        portals: {},
      );

      final config = AppConfig.fromApp(serverId: 's', app: emptyApp);

      expect(config.maintainersJson, isNull);
      expect(config.upgradeInfoJson, isNull);
      expect(config.usedPortsJson, isNull);
    });

    test('updateFromApp refreshes metadata while keeping identity fields', () {
      final original = AppConfig.fromApp(serverId: 'server-1', app: buildApp());
      final baseApp = buildApp();

      final updatedApp = App(
        name: baseApp.name,
        title: 'Plex Updated',
        description: baseApp.description,
        installed: baseApp.installed,
        healthy: false,
        healthyError: 'crashed',
        latestVersion: '2.0.0',
        latestAppVersion: '2.0.0',
        latestHumanVersion: '2.0.0',
        iconUrl: baseApp.iconUrl,
        categories: baseApp.categories,
        tags: baseApp.tags,
        screenshots: baseApp.screenshots,
        sources: baseApp.sources,
        maintainers: baseApp.maintainers,
        recommended: baseApp.recommended,
        catalog: baseApp.catalog,
        train: baseApp.train,
        upgradeInfo: baseApp.upgradeInfo,
        usedPorts: baseApp.usedPorts,
        portals: baseApp.portals,
      );

      final updated = original.updateFromApp(updatedApp);

      expect(updated.serverId, equals(original.serverId));
      expect(updated.appName, equals(original.appName));
      expect(updated.title, equals('Plex Updated'));
      expect(updated.healthy, isFalse);
      expect(updated.healthyError, equals('crashed'));
      expect(updated.version, equals('2.0.0'));
    });

    test('copyWith overrides only provided fields', () {
      final original = buildMinimal();
      final createdAt = DateTime(2024, 1, 1);

      final updated = original.copyWith(
        displayName: 'Custom',
        isFavorite: true,
        createdAt: createdAt,
      );

      expect(updated.serverId, equals(original.serverId));
      expect(updated.appName, equals(original.appName));
      expect(updated.displayName, equals('Custom'));
      expect(updated.isFavorite, isTrue);
      expect(updated.createdAt, equals(createdAt));
      expect(updated.isEnabled, equals(original.isEnabled));
    });

    test('equality holds for equal instances and differs on change', () {
      const a = AppConfig(serverId: 's', appName: 'app');
      const b = AppConfig(serverId: 's', appName: 'app');
      const c = AppConfig(serverId: 's', appName: 'other');
      expect(a, equals(b));
      expect(a == c, isFalse);
    });
  });
}
