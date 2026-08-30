import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/providers/connection_status_provider.dart';
import 'package:truehub/services/api_client_manager_interface.dart';
import 'package:truehub/services/api_client_manager_impl.dart';
import 'package:truehub/services/telemetry_service_interface.dart';

/// Legacy static facade for ApiClientManager
/// This maintains backward compatibility while allowing for dependency injection
class ApiClientManager {
  static ApiClientManagerInterface? _instance;

  /// Get the current instance (creates default if needed)
  static ApiClientManagerInterface get instance {
    _instance ??= ApiClientManagerImpl();
    return _instance!;
  }

  /// Set a custom instance (for testing)
  @visibleForTesting
  static void setInstance(ApiClientManagerInterface? manager) {
    _instance = manager;
  }

  // Legacy static methods that delegate to instance
  static void setConnectionStatusProvider(ConnectionStatusProvider? provider) {
    instance.setConnectionStatusProvider(provider);
  }

  static void setTelemetryService(TelemetryServiceInterface? telemetry) {
    instance.setTelemetryService(telemetry);
  }

  static Future<ApiClientInterface?> getClient(NasServer server) async {
    return instance.getClient(server);
  }

  static Future<void> releaseClient(String serverId) async {
    return instance.releaseClient(serverId);
  }

  static Future<void> closeClient(String serverId) async {
    return instance.closeClient(serverId);
  }

  static Future<Map<String, Object>> ensureAllConnectionsAlive() async {
    return instance.ensureAllConnectionsAlive();
  }

  static Future<void> closeAllClients() async {
    return instance.closeAllClients();
  }

  static ApiClientInterface? getExistingClient(String serverId) {
    return instance.getExistingClient(serverId);
  }

  static bool hasClient(String serverId) {
    return instance.hasClient(serverId);
  }

  static int getClientCount() {
    return instance.getClientCount();
  }

  static List<String> getActiveServerIds() {
    return instance.getActiveServerIds();
  }

  static Map<String, int> getRefCounts() {
    return instance.getRefCounts();
  }

  static Future<ApiClientInterface?> forceRecreateClient(
    NasServer server,
  ) async {
    return instance.forceRecreateClient(server);
  }

  /// Clears all cached clients and state. Used for testing only.
  @visibleForTesting
  static Future<void> clearAllForTesting() async {
    return instance.clearAllForTesting();
  }
}
