import 'dart:async';
import 'package:truehub/models/nas_server.dart';

/// Abstract interface for server data persistence and retrieval
/// Allows platform-specific implementations (CloudKit for Apple, SQLite for others)
abstract class ServerRepositoryInterface {
  /// Initialize the repository
  Future<bool> initialize();

  /// Get all servers
  Future<List<NasServer>> getAllServers();

  /// Get a single server by ID
  Future<NasServer?> getServer(String id);

  /// Save or update a server (without password)
  Future<bool> saveServer(NasServer server);

  /// Delete a server
  Future<bool> deleteServer(String id);

  /// Get the default server
  Future<NasServer?> getDefaultServer();

  /// Set default server
  Future<bool> setDefaultServer(String id);

  /// Clear default server
  Future<bool> clearDefaultServer();

  /// Stream of server changes
  Stream<List<NasServer>> get serversStream;

  /// Check if repository supports offline access
  bool get supportsOfflineAccess;

  /// Check if repository supports automatic sync
  bool get supportsAutoSync;

  /// Force a sync (if supported)
  Future<bool> sync();

  /// Dispose resources
  Future<void> dispose();
}
