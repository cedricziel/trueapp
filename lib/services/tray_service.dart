import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:truehub/models/app_config.dart';
import 'package:truehub/services/app_logger.dart';
import 'package:truehub/services/tray/native_tray_host.dart';
import 'package:truehub/services/tray/tray_host.dart';

final _log = appLogger('platform.tray');

class TrayService {
  TrayService({TrayHost? Function()? createHost})
    : _createHost = createHost ?? NativeTrayHost.create;

  final TrayHost? Function() _createHost;
  TrayHost? _host;
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
    if (_host != null) return;

    try {
      final host = _createHost();
      if (host == null) {
        _log.warn('System tray is not available on this platform');
        return;
      }

      // Use the custom NAS icon for macOS (start with light icon for light mode)
      host.setIcon(
        Platform.isMacOS
            ? 'assets/icons/nasTemplate_light.png'
            : 'assets/icons/tray_icon.ico',
      );
      host.setMenu(const [
        TrayMenuEntry(key: 'show_window', label: 'Show TrueNAS Manager'),
        TrayMenuEntry.separator(),
        TrayMenuEntry(key: 'refresh', label: 'Refresh Servers'),
        TrayMenuEntry.separator(),
        TrayMenuEntry(key: 'quit', label: 'Quit'),
      ], onSelected: _onMenuSelected);
      host.setTooltip('TrueNAS Manager');

      _host = host;
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
    final host = _host;
    if (host == null) return;

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

      host.setTooltip(tooltip);

      // Build menu items
      final menuItems = <TrayMenuEntry>[
        const TrayMenuEntry(key: 'show_window', label: 'Show TrueNAS Manager'),
        const TrayMenuEntry.separator(),
        TrayMenuEntry(
          key: 'server_status',
          label: 'Servers: $connectedServers/$totalServers',
          enabled: false,
        ),
        if (alerts != null && alerts.isNotEmpty) ...[
          TrayMenuEntry(
            key: 'alerts_count',
            label: 'Alerts: ${alerts.length}',
            enabled: false,
          ),
        ],
      ];

      // Add app portals section
      if (appsWithPortals != null && appsWithPortals.isNotEmpty) {
        menuItems.addAll(const [
          TrayMenuEntry.separator(),
          TrayMenuEntry(
            key: 'apps_header',
            label: 'Quick Access',
            enabled: false,
          ),
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
              menuItems.add(
                TrayMenuEntry(
                  key: key,
                  label: displayName,
                  children: [
                    for (final port in app.enabledPorts)
                      TrayMenuEntry(
                        key: 'app_${app.appName}_port_${port.id}',
                        label: port.serviceName ?? 'Port ${port.portNumber}',
                      ),
                  ],
                ),
              );
            } else {
              // Single port, direct menu item
              menuItems.add(TrayMenuEntry(key: key, label: displayName));
            }
          }
        }
      }

      // Add bottom menu items
      menuItems.addAll(const [
        TrayMenuEntry.separator(),
        TrayMenuEntry(key: 'refresh', label: 'Refresh Servers'),
        TrayMenuEntry.separator(),
        TrayMenuEntry(key: 'quit', label: 'Quit'),
      ]);

      host.setMenu(menuItems, onSelected: _onMenuSelected);
    } catch (e) {
      _log.error('Failed to update system tray status', error: e);
    }
  }

  Future<void> updateTheme({required bool isDarkMode}) async {
    final host = _host;
    if (host == null) return;

    try {
      host.setIcon(
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
    _host?.dispose();
    _host = null;
  }

  void _onMenuSelected(String key) {
    switch (key) {
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
        if (key.startsWith('app_')) {
          _handleAppPortalClick(key);
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
