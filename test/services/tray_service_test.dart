import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/app_config.dart';
import 'package:truehub/services/tray/tray_host.dart';
import 'package:truehub/services/tray_service.dart';

import '../helpers/fake_tray_host.dart';

AppConfig _appWithSinglePort(
  String name, {
  int id = 1,
  int port = 8080,
  String? serviceName,
}) {
  return AppConfig(
    serverId: 'server-1',
    appName: name,
    ports: [
      AppPortConfig(
        id: id,
        portNumber: port,
        isPrimary: true,
        isEnabled: true,
        serviceName: serviceName,
      ),
    ],
  );
}

AppConfig _appWithMultiplePorts(String name) {
  return AppConfig(
    serverId: 'server-1',
    appName: name,
    ports: const [
      AppPortConfig(
        id: 1,
        portNumber: 8080,
        isPrimary: true,
        isEnabled: true,
        serviceName: 'Web UI',
      ),
      AppPortConfig(
        id: 2,
        portNumber: 9090,
        isEnabled: true,
        serviceName: 'API',
      ),
    ],
  );
}

AppConfig _appWithNoPorts(String name) =>
    AppConfig(serverId: 'server-1', appName: name);

Iterable<String?> _keys(Iterable<TrayMenuEntry> entries) =>
    entries.map((e) => e.key);

TrayMenuEntry _entry(FakeTrayHost host, String key) =>
    host.lastMenuEntries.firstWhere((e) => e.key == key);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');

  late FakeTrayHost host;
  late TrayService service;
  final urlCalls = <MethodCall>[];
  var canLaunchResult = true;

  setUp(() {
    host = FakeTrayHost();
    service = fakeTrayService(host);
    urlCalls.clear();
    canLaunchResult = true;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncherChannel, (call) async {
          urlCalls.add(call);
          switch (call.method) {
            case 'canLaunch':
              return canLaunchResult;
            case 'launch':
              return true;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncherChannel, null);
  });

  group('TrayService - before initSystemTray', () {
    test('updateServerStatus is a no-op', () async {
      await service.updateServerStatus(connectedServers: 1, totalServers: 2);
      expect(host.tooltips, isEmpty);
      expect(host.menus, isEmpty);
    });

    test('updateTheme is a no-op', () async {
      await service.updateTheme(isDarkMode: true);
      expect(host.icons, isEmpty);
    });
  });

  group('TrayService - initSystemTray', () {
    test('sets the icon, the base context menu and the tooltip', () async {
      await service.initSystemTray();

      expect(host.icons, [
        Platform.isMacOS
            ? 'assets/icons/nasTemplate_light.png'
            : 'assets/icons/tray_icon.ico',
      ]);
      expect(_keys(host.lastMenu), [
        'show_window',
        null,
        'refresh',
        null,
        'quit',
      ]);
      expect(host.tooltips, ['TrueNAS Manager']);
    });

    test('is idempotent on a second call', () async {
      var created = 0;
      final service = TrayService(
        createHost: () {
          created++;
          return host;
        },
      );

      await service.initSystemTray();
      await service.initSystemTray();

      expect(created, 1);
      expect(host.menus, hasLength(1));
    });

    test('stays uninitialized when no tray can be created', () async {
      final service = TrayService(createHost: () => null);

      await service.initSystemTray();
      await service.updateServerStatus(connectedServers: 1, totalServers: 1);

      expect(host.menus, isEmpty);
    });
  });

  group('TrayService - menu selection', () {
    setUp(() => service.initSystemTray());

    test('routes show_window/refresh/quit to their callbacks', () {
      final calls = <String>[];
      service.setCallbacks(
        onShowWindow: () => calls.add('show'),
        onRefresh: () => calls.add('refresh'),
        onQuitApp: () => calls.add('quit'),
      );

      host.select('show_window');
      host.select('refresh');
      host.select('quit');

      expect(calls, ['show', 'refresh', 'quit']);
    });

    test('an unmatched, non-app_ key dispatches to nothing', () async {
      service.setCallbacks(onShowWindow: () => fail('should not be called'));

      host.select('server_status');
      await Future<void>.delayed(Duration.zero);

      expect(urlCalls, isEmpty);
    });

    test('clicks no-op when no callbacks are set', () {
      service.setCallbacks();
      expect(() => host.select('show_window'), returnsNormally);
    });
  });

  group('TrayService - updateServerStatus after init', () {
    setUp(() => service.initSystemTray());

    test('sets a tooltip and a basic menu with no alerts or apps', () async {
      await service.updateServerStatus(connectedServers: 2, totalServers: 3);

      expect(host.tooltips.last, 'TrueNAS Manager\nServers: 2/3 connected');
      expect(_keys(host.lastMenu), [
        'show_window',
        null,
        'server_status',
        null,
        'refresh',
        null,
        'quit',
      ]);
      expect(_entry(host, 'server_status').enabled, isFalse);
    });

    test('adds an alerts line to the tooltip and menu', () async {
      await service.updateServerStatus(
        connectedServers: 1,
        totalServers: 3,
        alerts: const ['disk full', 'pool degraded'],
      );

      expect(host.tooltips.last, contains('Alerts: 2'));
      final alertsItem = _entry(host, 'alerts_count');
      expect(alertsItem.label, 'Alerts: 2');
      expect(alertsItem.enabled, isFalse);
    });

    test('builds a Quick Access section: single port apps get a direct item, '
        'multi-port apps get a submenu, and apps without a usable port are '
        'skipped', () async {
      await service.updateServerStatus(
        connectedServers: 1,
        totalServers: 1,
        appsWithPortals: [
          _appWithSinglePort('plex', id: 10, serviceName: 'Web UI'),
          _appWithMultiplePorts('sonarr'),
          _appWithNoPorts('radarr'),
        ],
      );

      expect(host.tooltips.last, contains('Apps: 3 with portals'));
      expect(_keys(host.lastMenu), contains('apps_header'));

      final plexItem = _entry(host, 'app_plex');
      expect(plexItem.label, 'plex');
      expect(plexItem.children, isEmpty);

      expect(_keys(_entry(host, 'app_sonarr').children), [
        'app_sonarr_port_1',
        'app_sonarr_port_2',
      ]);

      expect(_keys(host.lastMenuEntries), isNot(contains('app_radarr')));
    });

    test('limits the Quick Access section to the first 10 apps', () async {
      await service.updateServerStatus(
        connectedServers: 1,
        totalServers: 1,
        appsWithPortals: List.generate(
          11,
          (i) => _appWithSinglePort('app$i', id: i),
        ),
      );

      final appKeys = _keys(
        host.lastMenu,
      ).where((k) => k?.startsWith('app_') == true);
      expect(appKeys, hasLength(10));
      expect(appKeys, isNot(contains('app_app10')));
    });
  });

  group('TrayService - updateTheme after init', () {
    test('sets the icon for the requested mode', () async {
      await service.initSystemTray();
      host.icons.clear();

      await service.updateTheme(isDarkMode: true);
      await service.updateTheme(isDarkMode: false);

      expect(
        host.icons,
        Platform.isMacOS
            ? [
                'assets/icons/nasTemplate_dark.png',
                'assets/icons/nasTemplate_light.png',
              ]
            : ['assets/icons/tray_icon.ico', 'assets/icons/tray_icon.ico'],
      );
    });
  });

  group('TrayService - app portal clicks', () {
    setUp(() async {
      await service.initSystemTray();
      await service.updateServerStatus(
        connectedServers: 1,
        totalServers: 1,
        appsWithPortals: [
          _appWithSinglePort('plex', id: 10, port: 32400),
          _appWithMultiplePorts('sonarr'),
        ],
      );
      urlCalls.clear();
    });

    test('a primary-port click opens that app\'s effective URL', () async {
      host.select('app_plex');
      await Future<void>.delayed(Duration.zero);

      expect(
        urlCalls.map((c) => c.method),
        containsAllInOrder(['canLaunch', 'launch']),
      );
      expect(
        (urlCalls.first.arguments as Map)['url'],
        'http://localhost:32400',
      );
    });

    test(
      'a specific port click opens that port\'s URL, not the primary one',
      () async {
        host.select('app_sonarr_port_2');
        await Future<void>.delayed(Duration.zero);

        expect(
          urlCalls.map((c) => c.method),
          containsAllInOrder(['canLaunch', 'launch']),
        );
        expect(
          (urlCalls.first.arguments as Map)['url'],
          'http://localhost:9090',
        );
      },
    );

    test(
      'an unknown app name is swallowed without launching anything',
      () async {
        host.select('app_does_not_exist');
        await Future<void>.delayed(Duration.zero);

        expect(urlCalls, isEmpty);
      },
    );

    test('does not launch when canLaunchUrl reports false', () async {
      canLaunchResult = false;

      host.select('app_plex');
      await Future<void>.delayed(Duration.zero);

      expect(urlCalls.map((c) => c.method), ['canLaunch']);
    });
  });

  group('TrayService - dispose', () {
    test('disposes the tray and can be re-initialized afterwards', () async {
      await service.initSystemTray();
      await service.dispose();
      expect(host.disposed, isTrue);

      host.menus.clear();
      await service.updateServerStatus(connectedServers: 0, totalServers: 0);
      expect(host.menus, isEmpty);

      await service.initSystemTray();
      expect(host.menus, hasLength(1));
    });
  });
}
