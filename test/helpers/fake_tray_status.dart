import 'package:flutter/foundation.dart';
import 'package:truehub/models/app_config.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/tray_status_ports.dart';

class StatusUpdate {
  const StatusUpdate({
    required this.connectedServers,
    required this.totalServers,
    required this.alerts,
    required this.appsWithPortals,
  });

  final int connectedServers;
  final int totalServers;
  final List<String>? alerts;
  final List<AppConfig>? appsWithPortals;
}

class FakeTraySink implements TrayStatusSink {
  VoidCallback? onShowWindow;
  VoidCallback? onQuitApp;
  VoidCallback? onRefresh;
  int initializeCalls = 0;
  final List<StatusUpdate> updates = [];

  @override
  void setCallbacks({
    VoidCallback? onShowWindow,
    VoidCallback? onQuitApp,
    VoidCallback? onRefresh,
  }) {
    this.onShowWindow = onShowWindow;
    this.onQuitApp = onQuitApp;
    this.onRefresh = onRefresh;
  }

  @override
  Future<void> initializeTray() async => initializeCalls++;

  @override
  Future<void> updateServerStatus({
    required int connectedServers,
    required int totalServers,
    List<String>? alerts,
    List<AppConfig>? appsWithPortals,
  }) async {
    updates.add(
      StatusUpdate(
        connectedServers: connectedServers,
        totalServers: totalServers,
        alerts: alerts,
        appsWithPortals: appsWithPortals,
      ),
    );
  }
}

class FakeTrayServerSource extends ChangeNotifier implements TrayServerSource {
  @override
  List<NasServer> servers = [];

  @override
  String? healthError;

  int refreshCalls = 0;

  @override
  Future<void> refreshSelectedServer() async => refreshCalls++;

  void change() => notifyListeners();
}

class FakeTrayAppsSource extends ChangeNotifier implements TrayAppsSource {
  List<AppConfig> apps = [];
  Object? error;

  @override
  List<AppConfig> getAppsWithPortals() {
    if (error != null) throw error!;
    return apps;
  }

  void change() => notifyListeners();
}
