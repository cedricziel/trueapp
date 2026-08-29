import 'dart:async';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/providers/connection_status_provider.dart';

/// Interface for managing TrueNAS API client instances
abstract class ApiClientManagerInterface {
  /// Set the connection status provider
  void setConnectionStatusProvider(ConnectionStatusProvider? provider);

  /// Get or create a client for the given server
  Future<ApiClientInterface?> getClient(NasServer server);

  /// Release a client reference (decrements ref count)
  Future<void> releaseClient(String serverId);

  /// Force close a client regardless of ref count
  Future<void> closeClient(String serverId);

  /// Close all active clients
  Future<void> closeAllClients();

  /// Verifies every pooled client's connection and recovers the ones the OS
  /// dropped while the app was suspended.
  ///
  /// One unreachable server never prevents the others from recovering, so
  /// failures are returned per server id rather than thrown.
  Future<Map<String, Object>> ensureAllConnectionsAlive();

  /// Get an existing client without creating a new one
  ApiClientInterface? getExistingClient(String serverId);

  /// Check if a client exists for the given server
  bool hasClient(String serverId);

  /// Get the number of active clients
  int getClientCount();

  /// Get list of active server IDs
  List<String> getActiveServerIds();

  /// Get reference counts for debugging
  Map<String, int> getRefCounts();

  /// Force recreation of a client
  Future<ApiClientInterface?> forceRecreateClient(NasServer server);

  /// Clear all clients (for testing)
  Future<void> clearAllForTesting();
}
