import 'dart:async';
import '../models/server_config_dto.dart';

/// Interface for CloudKit service implementations
abstract class CloudKitServiceInterface {
  /// Stream of server configuration updates from CloudKit
  Stream<List<ServerConfigDTO>> get serverConfigsStream;

  /// Whether the service has been initialized
  bool get isInitialized;

  /// Initialize CloudKit service
  Future<bool> initialize();

  /// Check if CloudKit is available and user is signed in
  Future<bool> isAvailable();

  /// Save server configuration to CloudKit
  Future<bool> saveServerConfig(ServerConfigDTO config);

  /// Update server configuration in CloudKit
  Future<bool> updateServerConfig(ServerConfigDTO config);

  /// Fetch all server configurations from CloudKit
  Future<List<ServerConfigDTO>> fetchServerConfigs();

  /// Delete server configuration from CloudKit
  Future<bool> deleteServerConfig(String serverId);

  /// Start monitoring for CloudKit changes
  Future<void> startMonitoring();

  /// Stop monitoring for CloudKit changes
  Future<void> stopMonitoring();

  /// Dispose resources
  void dispose();
}
