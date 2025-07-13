import 'dart:async';
import 'package:truehub/models/server_config_dto.dart';
import 'package:truehub/services/cloudkit_service_interface.dart';
import 'package:truenas_native_plugins/truenas_native_plugins.dart' as plugins;

/// Adapter that wraps the native plugins MockCloudKitService to implement
/// the app's CloudKitServiceInterface
class MockCloudKitServiceAdapter implements CloudKitServiceInterface {
  final plugins.MockCloudKitService _mockService;
  final StreamController<List<ServerConfigDTO>> _serverConfigsController =
      StreamController<List<ServerConfigDTO>>.broadcast();
  late StreamSubscription<List<plugins.ServerConfigDTO>> _subscription;

  MockCloudKitServiceAdapter() : _mockService = plugins.MockCloudKitService() {
    // Convert plugin DTOs to app DTOs
    _subscription = _mockService.serverConfigsStream.listen((pluginConfigs) {
      final appConfigs = pluginConfigs
          .map((p) => ServerConfigDTO.fromPlugin(p))
          .toList();
      _serverConfigsController.add(appConfigs);
    });
  }

  @override
  Stream<List<ServerConfigDTO>> get serverConfigsStream =>
      _serverConfigsController.stream;

  @override
  bool get isInitialized => _mockService.isInitialized;

  @override
  Future<bool> initialize() => _mockService.initialize();

  @override
  Future<bool> isAvailable() => _mockService.isAvailable();

  @override
  Future<bool> saveServerConfig(ServerConfigDTO config) =>
      _mockService.saveServerConfig(config.toPlugin());

  @override
  Future<bool> updateServerConfig(ServerConfigDTO config) =>
      _mockService.updateServerConfig(config.toPlugin());

  @override
  Future<List<ServerConfigDTO>> fetchServerConfigs() async {
    final pluginConfigs = await _mockService.fetchServerConfigs();
    return pluginConfigs.map((p) => ServerConfigDTO.fromPlugin(p)).toList();
  }

  @override
  Future<bool> deleteServerConfig(String serverId) =>
      _mockService.deleteServerConfig(serverId);

  @override
  Future<void> startMonitoring() => _mockService.startMonitoring();

  @override
  Future<void> stopMonitoring() => _mockService.stopMonitoring();

  @override
  void dispose() {
    _subscription.cancel();
    _serverConfigsController.close();
    _mockService.dispose();
  }

  // Test helper methods delegated to the mock service
  void setShouldFailOperations(bool shouldFail) {
    _mockService.setShouldFailOperations(shouldFail);
  }

  void setIsAvailable(bool isAvailable) {
    _mockService.setIsAvailable(isAvailable);
  }

  void setOperationDelay(int milliseconds) {
    _mockService.setOperationDelay(milliseconds);
  }

  void addMockConfig(ServerConfigDTO config) {
    _mockService.addMockConfig(config.toPlugin());
  }

  void clearMockConfigs() {
    _mockService.clearMockConfigs();
  }

  int get mockConfigCount => _mockService.mockConfigCount;

  bool get isMonitoring => _mockService.isMonitoring;

  void simulateRemoteUpdate(List<ServerConfigDTO> configs) {
    _mockService.simulateRemoteUpdate(
      configs.map((c) => c.toPlugin()).toList(),
    );
  }

  void simulateSyncError(String error) {
    _mockService.simulateSyncError(error);
  }
}
