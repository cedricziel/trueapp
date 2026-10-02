import 'dart:io';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/widgets/app_lifecycle_reconnector.dart';
import 'package:truehub/providers/pool_provider.dart';
import 'package:truehub/providers/dataset_provider.dart';
import 'package:truehub/providers/file_provider.dart';
import 'package:truehub/providers/health_provider.dart';
import 'package:truehub/providers/fleet_status_provider.dart';
import 'package:truehub/providers/app_provider.dart';
import 'package:truehub/providers/system_stats_provider.dart';
import 'package:truehub/providers/jobs_provider.dart';
import 'package:truehub/providers/connection_status_provider.dart';
import 'package:truehub/providers/tray_provider.dart';
import 'package:truehub/navigation/app_router.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/api_client_manager_impl.dart';
import 'package:truehub/services/active_server.dart';
import 'package:truehub/services/api_client_manager_interface.dart';
import 'package:truehub/services/window_manager.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/services/telemetry_service_interface.dart';
import 'package:truehub/services/telemetry_bootstrap.dart';
import 'package:truehub/widgets/tray_status_binder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final telemetryService = await bootstrapTelemetry();

  final database = AppDatabase.instance;
  final connectionStatusProvider = ConnectionStatusProvider();
  final unifiedServerService = await UnifiedServerService.createForProduction();

  final ApiClientManagerInterface clientManager = ApiClientManagerImpl(
    connectionStatusProvider: connectionStatusProvider,
    telemetry: telemetryService,
  );
  final activeServer = ActiveServer();

  runApp(
    MultiProvider(
      providers: [
        Provider<TelemetryServiceInterface>.value(value: telemetryService),
        Provider<AppDatabase>.value(value: database),
        Provider<UnifiedServerService>.value(value: unifiedServerService),
        Provider<ApiClientManagerInterface>.value(value: clientManager),
        Provider<ActiveServer>.value(value: activeServer),
        ChangeNotifierProvider.value(value: connectionStatusProvider),
        ChangeNotifierProvider(
          create: (context) => ServerProvider(
            unifiedServerService,
            databaseRef: () => AppDatabase.instance,
            clientManager: clientManager,
            telemetryService: telemetryService,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => PoolProvider(
            unifiedServerService,
            clientManager: clientManager,
            telemetryService: telemetryService,
            activeServer: activeServer.listenable,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => DatasetProvider(
            unifiedServerService,
            clientManager: clientManager,
            telemetryService: telemetryService,
            activeServer: activeServer.listenable,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => FileProvider(
            unifiedServerService,
            clientManager: clientManager,
            telemetryService: telemetryService,
            activeServer: activeServer.listenable,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => HealthProvider(
            unifiedServerService,
            clientManager: clientManager,
            telemetryService: telemetryService,
            activeServer: activeServer.listenable,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => FleetStatusProvider(
            unifiedServerService,
            clientManager: clientManager,
            telemetryService: telemetryService,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => AppProvider(
            databaseRef: () => AppDatabase.instance,
            serverService: unifiedServerService,
            clientManager: clientManager,
            telemetryService: telemetryService,
            activeServer: activeServer.listenable,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SystemStatsProvider(
            unifiedServerService,
            clientManager: clientManager,
            telemetryService: telemetryService,
            activeServer: activeServer.listenable,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => JobsProvider(
            unifiedServerService,
            clientManager: clientManager,
            telemetryService: telemetryService,
            activeServer: activeServer.listenable,
          ),
        ),
        ChangeNotifierProvider(create: (context) => TrayProvider()),
      ],
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
  @override
  Widget build(BuildContext context) {
    // No timer runs while the process is suspended, so a connection the OS
    // tore down in the background stays dead until something asks for it.
    // Returning to the foreground is that trigger.
    return TrayStatusBinder(
      isDesktop: Platform.isMacOS || Platform.isWindows || Platform.isLinux,
      tray: context.read<TrayProvider>(),
      serverSource: context.read<ServerProvider>(),
      appsSource: context.read<AppProvider>(),
      connectionSource: context.read<ConnectionStatusProvider>(),
      onShowWindow: WindowManager.showWindow,
      onQuitApp: WindowManager.quitApp,
      child: AppLifecycleReconnector(
        onResumed: () {
          unawaited(context.read<ServerProvider>().refreshConnection());
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
