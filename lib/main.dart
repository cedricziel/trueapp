import 'dart:io';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truehub/app_dependencies.dart';
import 'package:truehub/app_providers.dart';
import 'package:truehub/providers/app_provider.dart';
import 'package:truehub/providers/connection_status_provider.dart';
import 'package:truehub/providers/health_provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/providers/tray_provider.dart';
import 'package:truehub/navigation/app_router.dart';
import 'package:truehub/services/telemetry_bootstrap.dart';
import 'package:truehub/services/window_manager.dart';
import 'package:truehub/widgets/app_lifecycle_reconnector.dart';
import 'package:truehub/widgets/tray_status_binder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final telemetryService = await bootstrapTelemetry();
  final dependencies = await AppDependencies.create(
    telemetry: telemetryService,
  );

  runApp(
    MultiProvider(
      providers: buildAppProviders(dependencies),
      child: const TrueNASManagerApp(),
    ),
  );
}

class TrueNASManagerApp extends StatefulWidget {
  const TrueNASManagerApp({super.key});

  @override
  State<TrueNASManagerApp> createState() => _TrueNASManagerAppState();
}

class _TrueNASManagerAppState extends State<TrueNASManagerApp> {
  Future<void> _refreshAfterResume(BuildContext context) async {
    final servers = context.read<ServerProvider>();
    final health = context.read<HealthProvider>();
    await servers.refreshConnection();
    if (servers.currentAuthStatus.isAuthenticated) {
      await health.refreshHealth();
    }
  }

  @override
  Widget build(BuildContext context) {
    // No timer runs while the process is suspended, so a connection the OS
    // tore down in the background stays dead until something asks for it.
    // Returning to the foreground is that trigger.
    return TrayStatusBinder(
      isDesktop: Platform.isMacOS || Platform.isWindows || Platform.isLinux,
      tray: context.read<TrayProvider>(),
      serverSource: context.read<ServerProvider>(),
      healthSource: context.read<HealthProvider>(),
      appsSource: context.read<AppProvider>(),
      connectionSource: context.read<ConnectionStatusProvider>(),
      onShowWindow: WindowManager.showWindow,
      onQuitApp: WindowManager.quitApp,
      child: AppLifecycleReconnector(
        onResumed: () {
          unawaited(_refreshAfterResume(context));
        },
        child: CupertinoApp.router(
          title: 'TrueNAS Manager',
          theme: const CupertinoThemeData(
            primaryColor: CupertinoColors.systemBlue,
          ),
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
