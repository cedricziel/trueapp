import 'dart:io';
import 'package:tray_manager/tray_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:truehub/models/app_config.dart';
import 'package:truehub/services/app_logger.dart';

final _log = appLogger('platform.tray');

class TrayService with TrayListener {
  static final TrayService _instance = TrayService._internal();
  factory TrayService() => _instance;
  TrayService._internal();

  bool _isInitialized = false;
  Function()? _onShowWindow;
  Function()? _onQuitApp;
  Function()? _onRefresh;
  List<AppConfig> _appsWithPortals = [];

  void setCallbacks({
    Function()? onShowWindow,
    Function()? onQuitApp,
    Function()? onRefresh,
  }) {
    _onShowWindow = onShowWindow;
    _onQuitApp = onQuitApp;
    _onRefresh = onRefresh;
  }

  Future<void> initSystemTray() async {
    // Only initialize on platforms that support system tray (macOS, Windows, Linux)
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) return;
    if (_isInitialized) return;

    try {
      // Use the custom NAS icon for macOS (start with light icon for light mode)
      await trayManager.setIcon(
        Platform.isMacOS
            ? 'assets/icons/nasTemplate_light.png'
            : 'assets/icons/tray_icon.ico',
      );

      Menu menu = Menu(
        items: [
          MenuItem(key: 'show_window', label: 'Show TrueNAS Manager'),
          MenuItem.separator(),
          MenuItem(key: 'refresh', label: 'Refresh Servers'),
          MenuItem.separator(),
          MenuItem(key: 'quit', label: 'Quit'),
        ],
      );

      await trayManager.setContextMenu(menu);
      await trayManager.setToolTip('TrueNAS Manager');

      trayManager.addListener(this);
      _isInitialized = true;

      _log.info('System tray initialized successfully');
    } catch (e) {
      _log.error('Failed to initialize system tray', error: e);
    }
  }

  Future<void> updateServerStatus({
    required int connectedServers,
    required int totalServers,
    List<String>? alerts,
    List<AppConfig>? appsWithPortals,
  }) async {
    if (!_isInitialized) return;

    try {
      String tooltip =
          'TrueNAS Manager\n'
          'Servers: $connectedServers/$totalServers connected';

      if (alerts != null && alerts.isNotEmpty) {
        tooltip += '\nAlerts: ${alerts.length}';
      }

      if (appsWithPortals != null && appsWithPortals.isNotEmpty) {
        tooltip += '\nApps: ${appsWithPortals.length} with portals';
        _appsWithPortals = appsWithPortals; // Store for click handling
      }

      await trayManager.setToolTip(tooltip);

      // Build menu items
      List<MenuItem> menuItems = [
        MenuItem(key: 'show_window', label: 'Show TrueNAS Manager'),
        MenuItem.separator(),
        MenuItem(
          key: 'server_status',
          label: 'Servers: $connectedServers/$totalServers',
          disabled: true,
        ),
        if (alerts != null && alerts.isNotEmpty) ...[
          MenuItem(
            key: 'alerts_count',
            label: 'Alerts: ${alerts.length}',
            disabled: true,
          ),
        ],
      ];

      // Add app portals section
      if (appsWithPortals != null && appsWithPortals.isNotEmpty) {
        menuItems.addAll([
          MenuItem.separator(),
          MenuItem(key: 'apps_header', label: 'Quick Access', disabled: true),
        ]);

        // Add each app with its portal URLs
        for (final app in appsWithPortals.take(10)) {
          // Limit to 10 apps to avoid menu overflow
          final primaryPort = app.primaryPort;
          if (primaryPort != null) {
            final displayName = app.effectiveDisplayName;
            final key = 'app_${app.appName}';

            // If app has multiple ports, create a submenu
            if (app.enabledPorts.length > 1) {
              final subMenuItems = <MenuItem>[];
              for (final port in app.enabledPorts) {
                final portKey = 'app_${app.appName}_port_${port.id}';
                final portLabel = port.serviceName ?? 'Port ${port.portNumber}';
                subMenuItems.add(MenuItem(key: portKey, label: portLabel));
              }

              menuItems.add(
                MenuItem(
                  key: key,
                  label: displayName,
                  submenu: Menu(items: subMenuItems),
                ),
              );
            } else {
              // Single port, direct menu item
              menuItems.add(MenuItem(key: key, label: displayName));
            }
          }
        }
      }

      // Add bottom menu items
      menuItems.addAll([
        MenuItem.separator(),
        MenuItem(key: 'refresh', label: 'Refresh Servers'),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: 'Quit'),
      ]);

      Menu menu = Menu(items: menuItems);
      await trayManager.setContextMenu(menu);
    } catch (e) {
      _log.error('Failed to update system tray status', error: e);
    }
  }

  Future<void> updateTheme({required bool isDarkMode}) async {
    if (!_isInitialized) return;

    try {
      await trayManager.setIcon(
        Platform.isMacOS
            ? isDarkMode
                  ? 'assets/icons/nasTemplate_dark.png' // Dark icon for dark mode
                  : 'assets/icons/nasTemplate_light.png' // Light icon for light mode
            : 'assets/icons/tray_icon.ico',
      );

      _log.debug('Updated tray icon for ${isDarkMode ? 'dark' : 'light'} mode');
    } catch (e) {
      _log.error('Failed to update tray icon theme', error: e);
    }
  }

  Future<void> dispose() async {
    if (_isInitialized) {
      trayManager.removeListener(this);
      await trayManager.destroy();
      _isInitialized = false;
    }
  }

  @override
  void onTrayIconMouseDown() {
    // On macOS, left click should show the context menu
    if (Platform.isMacOS) {
      trayManager.popUpContextMenu();
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    // Right click should also show context menu
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
        _onShowWindow?.call();
        break;
      case 'refresh':
        _onRefresh?.call();
        break;
      case 'quit':
        _onQuitApp?.call();
        break;
      default:
        // Handle app portal clicks
        if (menuItem.key?.startsWith('app_') == true) {
          _handleAppPortalClick(menuItem.key!);
        }
        break;
    }
  }

  void _handleAppPortalClick(String menuKey) async {
    try {
      if (menuKey.contains('_port_')) {
        // Handle specific port click (app_name_port_id)
        final parts = menuKey.split('_');
        if (parts.length >= 4) {
          final portId = int.tryParse(parts.last);
          if (portId != null) {
            // Find the app and port
            for (final app in _appsWithPortals) {
              try {
                final port = app.ports.firstWhere((p) => p.id == portId);
                await _openPortalUrl(port.effectiveUrl);
                return;
              } catch (e) {
                // Continue searching
              }
            }
          }
        }
      } else {
        // Handle primary app click (app_name)
        final appName = menuKey.substring(4); // Remove 'app_' prefix
        try {
          final app = _appsWithPortals.firstWhere((a) => a.appName == appName);
          if (app.primaryPort != null) {
            await _openPortalUrl(app.primaryPort!.effectiveUrl);
          }
        } catch (e) {
          // App not found
        }
      }
    } catch (e) {
      _log.error('Failed to handle app portal click', error: e);
    }
  }

  Future<void> _openPortalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _log.warn('Cannot launch portal URL');
      }
    } catch (e) {
      _log.error('Failed to open portal URL', error: e);
    }
  }
}
