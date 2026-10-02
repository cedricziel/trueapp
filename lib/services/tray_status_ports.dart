import 'package:flutter/foundation.dart';
import 'package:truehub/models/app_config.dart';
import 'package:truehub/models/nas_server.dart';

abstract interface class TrayStatusSink {
  void setCallbacks({
    VoidCallback? onShowWindow,
    VoidCallback? onQuitApp,
    VoidCallback? onRefresh,
  });

  Future<void> initializeTray();

  Future<void> updateServerStatus({
    required int connectedServers,
    required int totalServers,
    List<String>? alerts,
    List<AppConfig>? appsWithPortals,
  });
}

abstract interface class TrayServerSource implements Listenable {
  List<NasServer> get servers;

  Future<void> refreshSelectedServer();
}

abstract interface class TrayHealthSource implements Listenable {
  String? get healthError;
}

abstract interface class TrayConnectionSource implements Listenable {
  List<String> get connectedServers;
}

abstract interface class TrayAppsSource implements Listenable {
  List<AppConfig> getAppsWithPortals();
}
