import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:truehub/app_dependencies.dart';
import 'package:truehub/providers/app_provider.dart';
import 'package:truehub/providers/dataset_provider.dart';
import 'package:truehub/providers/file_provider.dart';
import 'package:truehub/providers/fleet_status_provider.dart';
import 'package:truehub/providers/health_provider.dart';
import 'package:truehub/providers/jobs_provider.dart';
import 'package:truehub/providers/pool_provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/providers/services_provider.dart';
import 'package:truehub/providers/system_stats_provider.dart';
import 'package:truehub/providers/tray_provider.dart';
import 'package:truehub/providers/user_profile_provider.dart';
import 'package:truehub/services/active_server.dart';
import 'package:truehub/services/api_client_manager_interface.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/telemetry_service_interface.dart';
import 'package:truehub/services/unified_server_service.dart';

List<SingleChildWidget> buildAppProviders(AppDependencies deps) {
  final serverService = deps.serverService;
  final clientManager = deps.clientManager;
  final telemetry = deps.telemetry;
  final activeServer = deps.activeServer.listenable;

  return [
    Provider<TelemetryServiceInterface>.value(value: telemetry),
    Provider<AppDatabaseHolder>.value(value: deps.database),
    Provider<UnifiedServerService>.value(value: serverService),
    Provider<ApiClientManagerInterface>.value(value: clientManager),
    Provider<ActiveServer>.value(value: deps.activeServer),
    ChangeNotifierProvider.value(value: deps.connectionStatus),
    ChangeNotifierProvider(
      create: (context) => ServerProvider(
        serverService,
        serversDaoSource: deps.database,
        clientManager: clientManager,
        telemetryService: telemetry,
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => PoolProvider(
        serverService,
        clientManager: clientManager,
        telemetryService: telemetry,
        activeServer: activeServer,
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => DatasetProvider(
        serverService,
        clientManager: clientManager,
        telemetryService: telemetry,
        activeServer: activeServer,
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => FileProvider(
        serverService,
        clientManager: clientManager,
        telemetryService: telemetry,
        activeServer: activeServer,
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => HealthProvider(
        serverService,
        clientManager: clientManager,
        telemetryService: telemetry,
        activeServer: activeServer,
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => UserProfileProvider(
        serverService,
        clientManager: clientManager,
        telemetryService: telemetry,
        activeServer: activeServer,
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => FleetStatusProvider(
        serverService,
        clientManager: clientManager,
        telemetryService: telemetry,
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => AppProvider(
        daoSource: deps.database,
        serverService: serverService,
        clientManager: clientManager,
        telemetryService: telemetry,
        activeServer: activeServer,
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => SystemStatsProvider(
        serverService,
        clientManager: clientManager,
        telemetryService: telemetry,
        activeServer: activeServer,
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => JobsProvider(
        serverService,
        clientManager: clientManager,
        telemetryService: telemetry,
        activeServer: activeServer,
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => ServicesProvider(
        serverService,
        clientManager: clientManager,
        telemetryService: telemetry,
        activeServer: activeServer,
      ),
    ),
    ChangeNotifierProvider(create: (context) => TrayProvider()),
  ];
}
