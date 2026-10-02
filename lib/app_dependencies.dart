import 'package:truehub/providers/connection_status_provider.dart';
import 'package:truehub/services/active_server.dart';
import 'package:truehub/services/api_client_manager_impl.dart';
import 'package:truehub/services/api_client_manager_interface.dart';
import 'package:truehub/services/cloudkit_service.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/native_keychain_service.dart';
import 'package:truehub/services/server_repository_factory.dart';
import 'package:truehub/services/telemetry_service_interface.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truenas_native_plugins/truenas_native_plugins.dart'
    show KeychainServiceInterface;

/// The production object graph, built once at startup and handed down from
/// `main` so nothing below it reaches for a global.
class AppDependencies {
  const AppDependencies({
    required this.telemetry,
    required this.database,
    required this.keychain,
    required this.serverService,
    required this.connectionStatus,
    required this.clientManager,
    required this.activeServer,
  });

  final TelemetryServiceInterface telemetry;
  final AppDatabaseHolder database;
  final KeychainServiceInterface keychain;
  final UnifiedServerService serverService;
  final ConnectionStatusProvider connectionStatus;
  final ApiClientManagerInterface clientManager;
  final ActiveServer activeServer;

  static Future<AppDependencies> create({
    required TelemetryServiceInterface telemetry,
  }) async {
    final database = AppDatabaseHolder(open: AppDatabase.production);
    final keychain = NativeKeychainService();
    final repository = await ServerRepositoryFactory(
      serversDaoSource: database,
      cloudKitServiceBuilder: CloudKitService.new,
    ).create();
    final serverService = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );
    if (!await serverService.initialize()) {
      throw StateError('Failed to initialize UnifiedServerService');
    }

    final connectionStatus = ConnectionStatusProvider();
    return AppDependencies(
      telemetry: telemetry,
      database: database,
      keychain: keychain,
      serverService: serverService,
      connectionStatus: connectionStatus,
      clientManager: ApiClientManagerImpl(
        connectionStatusProvider: connectionStatus,
        telemetry: telemetry,
      ),
      activeServer: ActiveServer(),
    );
  }
}
