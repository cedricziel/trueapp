import 'dart:async';
import 'package:truehub/models/server_config_dto.dart';

/// Interface for CloudKit service to enable mocking and dependency injection
abstract class CloudKitServiceInterface {
  /// Stream of server configuration updates from CloudKit
  Stream<List<ServerConfigDTO>> get serverConfigsStream;

  /// Whether the service is initialized
  bool get isInitialized;

  /// Initialize CloudKit service
  Future<bool> initialize();

  /// Check if CloudKit is available and user is signed in
  Future<bool> isAvailable();

  /// Save server configuration to CloudKit
  Future<bool> saveServerConfig(ServerConfigDTO config);

  /// Update existing server configuration
  Future<bool> updateServerConfig(ServerConfigDTO config);

  /// Fetch all server configurations
  Future<List<ServerConfigDTO>> fetchServerConfigs();

  /// Delete server configuration
  Future<bool> deleteServerConfig(String serverId);

  /// Start monitoring CloudKit changes
  Future<void> startMonitoring();

  /// Stop monitoring CloudKit changes
  Future<void> stopMonitoring();

  /// Cleanup resources
  void dispose();
}
