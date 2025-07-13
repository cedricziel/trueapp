import 'dart:async';
import 'package:truenas_native_plugins/truenas_native_plugins.dart' as plugins;
import 'package:truehub/models/server_config_dto.dart';
import 'package:truehub/services/cloudkit_service_interface.dart';

/// Wrapper for CloudKit service using the native plugin
/// Follows Apple's two-layer pattern: CloudKit for metadata, Keychain for passwords
class CloudKitService implements CloudKitServiceInterface {
  final plugins.CloudKitServiceInterface _cloudKitService;
  late final StreamController<List<ServerConfigDTO>> _serverConfigsController;
  late final StreamSubscription<List<plugins.ServerConfigDTO>>
  _pluginSubscription;

  static CloudKitService? _instance;
  static CloudKitService get instance => _instance ??= CloudKitService._();

  CloudKitService._() : _cloudKitService = plugins.NativeCloudKitService() {
    _serverConfigsController =
        StreamController<List<ServerConfigDTO>>.broadcast();

    // Convert plugin DTOs to app DTOs
    _pluginSubscription = _cloudKitService.serverConfigsStream.listen((
      pluginConfigs,
    ) {
      final appConfigs = pluginConfigs
          .map((p) => ServerConfigDTO.fromPlugin(p))
          .toList();
      _serverConfigsController.add(appConfigs);
    });
  }

  /// Stream of server configuration updates from CloudKit
  @override
  Stream<List<ServerConfigDTO>> get serverConfigsStream =>
      _serverConfigsController.stream;

  @override
  bool get isInitialized => _cloudKitService.isInitialized;

  /// Initialize CloudKit service
  @override
  Future<bool> initialize() => _cloudKitService.initialize();

  /// Check if CloudKit is available and user is signed in
  @override
  Future<bool> isAvailable() => _cloudKitService.isAvailable();

  /// Save server configuration to CloudKit
  @override
  Future<bool> saveServerConfig(ServerConfigDTO config) =>
      _cloudKitService.saveServerConfig(config.toPlugin());

  /// Update server configuration in CloudKit
  @override
  Future<bool> updateServerConfig(ServerConfigDTO config) =>
      _cloudKitService.updateServerConfig(config.toPlugin());

  /// Fetch all server configurations from CloudKit
  @override
  Future<List<ServerConfigDTO>> fetchServerConfigs() async {
    final pluginConfigs = await _cloudKitService.fetchServerConfigs();
    return pluginConfigs.map((p) => ServerConfigDTO.fromPlugin(p)).toList();
  }

  /// Delete server configuration from CloudKit
  @override
  Future<bool> deleteServerConfig(String serverId) =>
      _cloudKitService.deleteServerConfig(serverId);

  /// Start monitoring for CloudKit changes
  @override
  Future<void> startMonitoring() => _cloudKitService.startMonitoring();

  /// Stop monitoring for CloudKit changes
  @override
  Future<void> stopMonitoring() => _cloudKitService.stopMonitoring();

  /// Dispose resources
  @override
  void dispose() {
    _pluginSubscription.cancel();
    _serverConfigsController.close();
    _cloudKitService.dispose();
  }
}
