import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';

class TrayService with TrayListener {
  static final TrayService _instance = TrayService._internal();
  factory TrayService() => _instance;
  TrayService._internal();

  bool _isInitialized = false;
  Function()? _onShowWindow;
  Function()? _onQuitApp;
  Function()? _onRefresh;

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
      await trayManager.setIcon(
        Platform.isMacOS
            ? 'assets/icons/tray_icon.png'
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

      if (kDebugMode) {
        print('System tray initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize system tray: $e');
      }
    }
  }

  Future<void> updateServerStatus({
    required int connectedServers,
    required int totalServers,
    List<String>? alerts,
  }) async {
    if (!_isInitialized) return;

    try {
      String tooltip =
          'TrueNAS Manager\n'
          'Servers: $connectedServers/$totalServers connected';

      if (alerts != null && alerts.isNotEmpty) {
        tooltip += '\nAlerts: ${alerts.length}';
      }

      await trayManager.setToolTip(tooltip);

      // Update menu with server status
      Menu menu = Menu(
        items: [
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
          MenuItem.separator(),
          MenuItem(key: 'refresh', label: 'Refresh Servers'),
          MenuItem.separator(),
          MenuItem(key: 'quit', label: 'Quit'),
        ],
      );

      await trayManager.setContextMenu(menu);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update system tray status: $e');
      }
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
    // Handle tray icon click if needed
  }

  @override
  void onTrayIconRightMouseDown() {
    // Show context menu (handled automatically by tray_manager)
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
    }
  }
}
