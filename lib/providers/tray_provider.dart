import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:truehub/services/tray_service.dart';
import 'package:truehub/services/window_manager.dart';
import 'package:truehub/models/app_config.dart';

class TrayProvider with ChangeNotifier {
  final TrayService _trayService = TrayService();

  bool _minimizeToTray = true;
  bool _showInDock = true;
  bool _isInitialized = false;

  bool get minimizeToTray => _minimizeToTray;
  bool get showInDock => _showInDock;
  bool get isInitialized => _isInitialized;

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

  Future<void> initializeTray() async {
    // Only initialize on desktop platforms that support system tray
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) return;
    if (_isInitialized) return;

    _trayService.setCallbacks(
      onShowWindow: _onShowWindow,
      onQuitApp: _onQuitApp,
      onRefresh: _onRefresh,
    );

    await _trayService.initSystemTray();
    _isInitialized = true;
    notifyListeners();
  }

  void setMinimizeToTray(bool value) {
    _minimizeToTray = value;
    notifyListeners();
  }

  void setShowInDock(bool value) {
    _showInDock = value;
    _updateDockVisibility(value);
    notifyListeners();
  }

  void _updateDockVisibility(bool showInDock) {
    // Only update on desktop platforms
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) return;

    WindowManager.setDockVisibility(showInDock);
  }

  Future<void> updateServerStatus({
    required int connectedServers,
    required int totalServers,
    List<String>? alerts,
    List<AppConfig>? appsWithPortals,
  }) async {
    // Only update on desktop platforms
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) return;
    if (!_isInitialized) return;

    await _trayService.updateServerStatus(
      connectedServers: connectedServers,
      totalServers: totalServers,
      alerts: alerts,
      appsWithPortals: appsWithPortals,
    );
  }

  Future<void> updateTheme({required bool isDarkMode}) async {
    // Only update on desktop platforms
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) return;

    await _trayService.updateTheme(isDarkMode: isDarkMode);
  }

  @override
  void dispose() {
    _trayService.dispose();
    super.dispose();
  }
}
