import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:truehub/models/app_config.dart';
import 'package:truehub/services/tray_service.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // `TrayService` is a singleton - every test in this file shares one
  // underlying instance and its private `_isInitialized`/`_appsWithPortals`
  // state, exactly like the real app does. Tests below are therefore
  // ordered deliberately (declaration order is execution order within a
  // single `flutter test` file): the "before init" behaviour is asserted
  // before `initSystemTray()` ever runs, and everything after that assumes
  // the tray is initialized.
  final service = TrayService();

  // tray_manager talks to the native side over this MethodChannel; url
  // launches go through url_launcher's. Neither has a handler in the
  // `flutter test` VM by default (that's what would throw
  // MissingPluginException), so both are mocked the same way
  // `test/providers/tray_provider_test.dart` mocks WindowManager's channel -
  // recording every call so the test can assert on what TrayService asked
  // the plugin to do, without needing a real tray or browser.
  const trayChannel = MethodChannel('tray_manager');
  const urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');

  final trayCalls = <MethodCall>[];
  final urlCalls = <MethodCall>[];
  var canLaunchResult = true;

  setUp(() {
    trayCalls.clear();
    urlCalls.clear();
    canLaunchResult = true;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(trayChannel, (call) async {
          trayCalls.add(call);
          return null;
        });

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
        .setMockMethodCallHandler(trayChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncherChannel, null);
  });

  group('TrayService - singleton', () {
    test('the factory constructor always returns the same instance', () {
      expect(identical(TrayService(), TrayService()), isTrue);
      expect(identical(TrayService(), service), isTrue);
    });
  });

  group('TrayService - setCallbacks and menu-item dispatch', () {
    test('routes show_window/refresh/quit clicks to their callbacks', () {
      var showCalled = false;
      var refreshCalled = false;
      var quitCalled = false;

      service.setCallbacks(
        onShowWindow: () => showCalled = true,
        onRefresh: () => refreshCalled = true,
        onQuitApp: () => quitCalled = true,
      );

      service.onTrayMenuItemClick(MenuItem(key: 'show_window'));
      expect(showCalled, isTrue);
      expect(refreshCalled, isFalse);
      expect(quitCalled, isFalse);

      service.onTrayMenuItemClick(MenuItem(key: 'refresh'));
      expect(refreshCalled, isTrue);
      expect(quitCalled, isFalse);

      service.onTrayMenuItemClick(MenuItem(key: 'quit'));
      expect(quitCalled, isTrue);
    });

    test('an unmatched, non-app_ key dispatches to nothing', () {
      expect(
        () => service.onTrayMenuItemClick(MenuItem(key: 'server_status')),
        returnsNormally,
      );
      expect(
        () => service.onTrayMenuItemClick(MenuItem()), // key == null
        returnsNormally,
      );
      // Neither the tray nor url_launcher channel should have been touched.
      expect(trayCalls, isEmpty);
      expect(urlCalls, isEmpty);
    });

    test('accepts being called with no callbacks at all, and clicks no-op', () {
      service.setCallbacks();
      expect(
        () => service.onTrayMenuItemClick(MenuItem(key: 'show_window')),
        returnsNormally,
      );
    });
  });

  group('TrayService - before initSystemTray', () {
    test('updateServerStatus is a no-op', () async {
      await service.updateServerStatus(connectedServers: 1, totalServers: 2);
      expect(trayCalls, isEmpty);
    });

    test('updateTheme is a no-op', () async {
      await service.updateTheme(isDarkMode: true);
      expect(trayCalls, isEmpty);
    });
  });

  group('TrayService - initSystemTray', () {
    test('sets the icon, the base context menu and the tooltip', () async {
      await service.initSystemTray();

      final methods = trayCalls.map((c) => c.method).toList();
      expect(
        methods,
        containsAllInOrder(['setIcon', 'setContextMenu', 'setToolTip']),
      );

      final setIconCall = trayCalls.firstWhere((c) => c.method == 'setIcon');
      // Non-macOS (this test VM is Linux) always uses the .ico asset.
      expect(
        (setIconCall.arguments as Map)['iconPath'],
        contains('tray_icon.ico'),
      );

      final setContextMenuCall = trayCalls.firstWhere(
        (c) => c.method == 'setContextMenu',
      );
      final menuJson = (setContextMenuCall.arguments as Map)['menu'] as Map;
      final items = menuJson['items'] as List;
      // show_window, separator, refresh, separator, quit.
      expect(items, hasLength(5));
      expect(items.first['key'], 'show_window');
      expect(items.last['key'], 'quit');

      final setToolTipCall = trayCalls.firstWhere(
        (c) => c.method == 'setToolTip',
      );
      expect((setToolTipCall.arguments as Map)['toolTip'], 'TrueNAS Manager');
    });

    test('is idempotent on a second call', () async {
      trayCalls.clear();
      await service.initSystemTray();
      expect(trayCalls, isEmpty);
    });
  });

  group('TrayService - updateServerStatus after init', () {
    test('sets a tooltip and a basic menu with no alerts or apps', () async {
      await service.updateServerStatus(connectedServers: 2, totalServers: 3);

      final setToolTipCall = trayCalls.firstWhere(
        (c) => c.method == 'setToolTip',
      );
      expect(
        (setToolTipCall.arguments as Map)['toolTip'],
        'TrueNAS Manager\nServers: 2/3 connected',
      );

      final menuJson =
          (trayCalls.firstWhere((c) => c.method == 'setContextMenu').arguments
                  as Map)['menu']
              as Map;
      final items = (menuJson['items'] as List).cast<Map>();
      // show_window, separator, server_status (disabled), separator, refresh,
      // separator, quit - no alerts/apps sections.
      expect(items.map((i) => i['key']), [
        'show_window',
        null, // separator
        'server_status',
        null, // separator
        'refresh',
        null, // separator
        'quit',
      ]);
      expect(
        items.firstWhere((i) => i['key'] == 'server_status')['disabled'],
        isTrue,
      );
    });

    test('adds an alerts line to the tooltip and menu', () async {
      await service.updateServerStatus(
        connectedServers: 1,
        totalServers: 3,
        alerts: const ['disk full', 'pool degraded'],
      );

      final setToolTipCall = trayCalls.firstWhere(
        (c) => c.method == 'setToolTip',
      );
      expect(
        (setToolTipCall.arguments as Map)['toolTip'],
        contains('Alerts: 2'),
      );

      final menuJson =
          (trayCalls.firstWhere((c) => c.method == 'setContextMenu').arguments
                  as Map)['menu']
              as Map;
      final items = (menuJson['items'] as List).cast<Map>();
      final alertsItem = items.firstWhere((i) => i['key'] == 'alerts_count');
      expect(alertsItem['label'], 'Alerts: 2');
      expect(alertsItem['disabled'], isTrue);
    });

    test('builds a Quick Access section: single port apps get a direct item, '
        'multi-port apps get a submenu, and apps without a usable port are '
        'skipped', () async {
      final apps = [
        _appWithSinglePort('plex', id: 10, serviceName: 'Web UI'),
        _appWithMultiplePorts('sonarr'),
        _appWithNoPorts('radarr'),
      ];

      await service.updateServerStatus(
        connectedServers: 1,
        totalServers: 1,
        appsWithPortals: apps,
      );

      final setToolTipCall = trayCalls.firstWhere(
        (c) => c.method == 'setToolTip',
      );
      expect(
        (setToolTipCall.arguments as Map)['toolTip'],
        contains('Apps: 3 with portals'),
      );

      final menuJson =
          (trayCalls.firstWhere((c) => c.method == 'setContextMenu').arguments
                  as Map)['menu']
              as Map;
      final items = (menuJson['items'] as List).cast<Map>();

      expect(
        items.any((i) => i['key'] == 'apps_header'),
        isTrue,
        reason: 'Quick Access header should be present',
      );

      final plexItem = items.firstWhere((i) => i['key'] == 'app_plex');
      expect(plexItem['label'], 'plex');
      expect(plexItem.containsKey('submenu'), isFalse);

      final sonarrItem = items.firstWhere((i) => i['key'] == 'app_sonarr');
      expect(sonarrItem['submenu'], isNotNull);
      final subItems = (sonarrItem['submenu'] as Map)['items'] as List;
      expect(subItems, hasLength(2));
      expect(
        subItems.map((i) => (i as Map)['key']),
        containsAll(['app_sonarr_port_1', 'app_sonarr_port_2']),
      );

      // radarr has no ports at all, so primaryPort is null and it is
      // skipped entirely - never added as a menu item.
      expect(items.any((i) => i['key'] == 'app_radarr'), isFalse);
    });

    test('limits the Quick Access section to the first 10 apps', () async {
      final apps = List.generate(11, (i) => _appWithSinglePort('app$i', id: i));

      await service.updateServerStatus(
        connectedServers: 1,
        totalServers: 1,
        appsWithPortals: apps,
      );

      final menuJson =
          (trayCalls.firstWhere((c) => c.method == 'setContextMenu').arguments
                  as Map)['menu']
              as Map;
      final items = (menuJson['items'] as List).cast<Map>();
      final appItems = items.where(
        (i) => (i['key'] as String?)?.startsWith('app_') == true,
      );
      expect(appItems, hasLength(10));
      expect(items.any((i) => i['key'] == 'app_app10'), isFalse);
    });
  });

  group('TrayService - updateTheme after init', () {
    test('sets the icon (non-macOS path) without throwing', () async {
      await service.updateTheme(isDarkMode: true);
      expect(trayCalls.map((c) => c.method), contains('setIcon'));

      trayCalls.clear();
      await service.updateTheme(isDarkMode: false);
      expect(trayCalls.map((c) => c.method), contains('setIcon'));
    });
  });

  group('TrayService - tray icon click handlers', () {
    test('right mouse down always pops up the context menu', () {
      service.onTrayIconRightMouseDown();
      expect(trayCalls.map((c) => c.method), contains('popUpContextMenu'));
    });

    test('left mouse down only pops up the menu on macOS', () {
      // This test VM reports Platform.isMacOS == false, so
      // onTrayIconMouseDown's early-return branch is what actually runs
      // here; the macOS branch is unreachable from a Linux test run.
      service.onTrayIconMouseDown();
      expect(
        trayCalls.map((c) => c.method),
        isNot(contains('popUpContextMenu')),
      );
    });
  });

  group('TrayService - app portal clicks', () {
    setUp(() async {
      // Give _appsWithPortals a known, deterministic value for this group
      // regardless of what an earlier test in the file left behind.
      await service.updateServerStatus(
        connectedServers: 1,
        totalServers: 1,
        appsWithPortals: [
          _appWithSinglePort('plex', id: 10, port: 32400),
          _appWithMultiplePorts('sonarr'),
        ],
      );
      trayCalls.clear();
      urlCalls.clear();
    });

    test('a primary-port click opens that app\'s effective URL', () async {
      service.onTrayMenuItemClick(MenuItem(key: 'app_plex'));
      // _handleAppPortalClick is fire-and-forget (not awaited by the
      // caller), so let its internal awaits complete.
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
        service.onTrayMenuItemClick(MenuItem(key: 'app_sonarr_port_2'));
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
        service.onTrayMenuItemClick(MenuItem(key: 'app_does_not_exist'));
        await Future<void>.delayed(Duration.zero);

        expect(urlCalls, isEmpty);
      },
    );

    test('does not launch when canLaunchUrl reports false', () async {
      canLaunchResult = false;

      service.onTrayMenuItemClick(MenuItem(key: 'app_plex'));
      await Future<void>.delayed(Duration.zero);

      expect(urlCalls.map((c) => c.method), ['canLaunch']);
    });
  });

  group('TrayService - dispose', () {
    test('destroys the tray and can be re-initialized afterwards', () async {
      await service.dispose();
      expect(trayCalls.map((c) => c.method), contains('destroy'));

      // Once disposed, the service reverts to its pre-init behaviour.
      trayCalls.clear();
      await service.updateServerStatus(connectedServers: 0, totalServers: 0);
      expect(trayCalls, isEmpty);

      // And initSystemTray works again rather than being permanently
      // idempotent-locked.
      await service.initSystemTray();
      expect(trayCalls.map((c) => c.method), contains('setIcon'));
    });
  });
}
