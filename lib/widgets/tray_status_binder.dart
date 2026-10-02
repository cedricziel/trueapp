import 'package:flutter/widgets.dart';
import 'package:truehub/models/app_config.dart';
import 'package:truehub/services/app_logger.dart';
import 'package:truehub/services/tray_status_ports.dart';

final _log = appLogger('widgets.tray_status_binder');

class TrayStatusBinder extends StatefulWidget {
  const TrayStatusBinder({
    super.key,
    required this.isDesktop,
    required this.tray,
    required this.serverSource,
    required this.appsSource,
    required this.onShowWindow,
    required this.onQuitApp,
    required this.child,
  });

  final bool isDesktop;
  final TrayStatusSink tray;
  final TrayServerSource serverSource;
  final TrayAppsSource appsSource;
  final VoidCallback onShowWindow;
  final VoidCallback onQuitApp;
  final Widget child;

  @override
  State<TrayStatusBinder> createState() => _TrayStatusBinderState();
}

class _TrayStatusBinderState extends State<TrayStatusBinder> {
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isDesktop) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.tray.setCallbacks(
        onShowWindow: widget.onShowWindow,
        onQuitApp: widget.onQuitApp,
        onRefresh: () => widget.serverSource.refreshSelectedServer(),
      );
      widget.tray.initializeTray();
      widget.serverSource.addListener(_updateTrayStatus);
      widget.appsSource.addListener(_updateTrayStatus);
      _listening = true;
    });
  }

  void _updateTrayStatus() {
    final serverSource = widget.serverSource;
    final servers = serverSource.servers;

    final alerts = <String>[];
    final healthError = serverSource.healthError;
    if (healthError != null) alerts.add(healthError);

    var appsWithPortals = <AppConfig>[];
    try {
      appsWithPortals = widget.appsSource.getAppsWithPortals();
    } catch (e) {
      _log.error('Error getting apps with portals', error: e);
    }

    widget.tray.updateServerStatus(
      connectedServers: servers.length,
      totalServers: servers.length,
      alerts: alerts,
      appsWithPortals: appsWithPortals,
    );
  }

  @override
  void dispose() {
    if (_listening) {
      widget.serverSource.removeListener(_updateTrayStatus);
      widget.appsSource.removeListener(_updateTrayStatus);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
