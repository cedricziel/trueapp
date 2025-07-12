import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/providers/pool_provider.dart';
import 'package:truehub/providers/dataset_provider.dart';
import 'package:truehub/providers/app_provider.dart';
import 'package:truehub/providers/system_stats_provider.dart';
import 'package:truehub/providers/connection_status_provider.dart';
import 'package:truehub/providers/tray_provider.dart';
import 'package:truehub/screens/home_screen.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/api_client_manager.dart';
import 'package:truehub/services/window_manager.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/models/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  final connectionStatusProvider = ConnectionStatusProvider();
  final unifiedServerService = await UnifiedServerService.createForProduction();

  // Initialize services
  ApiClientManager.setConnectionStatusProvider(connectionStatusProvider);

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        Provider<UnifiedServerService>.value(value: unifiedServerService),
        ChangeNotifierProvider.value(value: connectionStatusProvider),
        ChangeNotifierProvider(
          create: (context) => ServerProvider(unifiedServerService),
        ),
        ChangeNotifierProvider(
          create: (context) => PoolProvider(unifiedServerService),
        ),
        ChangeNotifierProvider(
          create: (context) => DatasetProvider(unifiedServerService),
        ),
        ChangeNotifierProvider(
          create: (context) => AppProvider(
            database: database,
            serverService: unifiedServerService,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SystemStatsProvider(unifiedServerService),
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
  void initState() {
    super.initState();
    // Only initialize tray on desktop platforms that support it
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeTray();
        _setupServerStatusListener();
      });
    }
  }

  void _setupServerStatusListener() {
    // Only set up listener on desktop platforms
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      final serverProvider = context.read<ServerProvider>();
      final appProvider = context.read<AppProvider>();

      serverProvider.addListener(_updateTrayStatus);
      appProvider.addListener(_updateTrayStatus);
    }
  }

  void _initializeTray() {
    final trayProvider = context.read<TrayProvider>();
    trayProvider.setCallbacks(
      onShowWindow: _showWindow,
      onQuitApp: _quitApp,
      onRefresh: _refreshServers,
    );
    trayProvider.initializeTray();
  }

  void _showWindow() {
    WindowManager.showWindow();
  }

  void _quitApp() {
    WindowManager.quitApp();
  }

  void _refreshServers() {
    final serverProvider = context.read<ServerProvider>();
    serverProvider.refreshSelectedServer();
  }

  void _updateTrayStatus() async {
    // Only update tray on desktop platforms
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) return;

    final trayProvider = context.read<TrayProvider>();
    final serverProvider = context.read<ServerProvider>();
    final appProvider = context.read<AppProvider>();

    int totalServers = serverProvider.servers.length;
    int connectedServers = serverProvider.servers
        .where(
          (server) =>
              // Assuming servers have a connected property or similar
              true, // For now, assume all servers are connected
        )
        .length;

    List<String> alerts = [];
    // Add any server health alerts if available
    if (serverProvider.healthError != null) {
      alerts.add(serverProvider.healthError!);
    }

    // Get apps with portals from the unified AppProvider
    List<AppConfig> appsWithPortals = [];
    try {
      appsWithPortals = appProvider.getAppsWithPortals();
      if (kDebugMode) {
        print('Tray: Found ${appsWithPortals.length} apps with portals');
        for (final app in appsWithPortals) {
          print('  - ${app.appName}: ${app.ports.length} ports');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Tray: Error getting apps with portals: $e');
      }
    }

    trayProvider.updateServerStatus(
      connectedServers: connectedServers,
      totalServers: totalServers,
      alerts: alerts,
      appsWithPortals: appsWithPortals,
    );
  }

  @override
  void dispose() {
    // Only remove listener on desktop platforms
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      final serverProvider = context.read<ServerProvider>();
      final appProvider = context.read<AppProvider>();

      serverProvider.removeListener(_updateTrayStatus);
      appProvider.removeListener(_updateTrayStatus);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'TrueNAS Manager',
      theme: const CupertinoThemeData(
        primaryColor: CupertinoColors.systemBlue,
        brightness: Brightness.light,
      ),
      home: const HomeScreen(),
    );
  }
}
