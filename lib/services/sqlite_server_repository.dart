import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/server_repository_interface.dart';
import 'package:truehub/services/database.dart';

/// SQLite-based server repository for non-Apple platforms
/// Provides local storage without automatic sync
class SqliteServerRepository implements ServerRepositoryInterface {
  final AppDatabase _database;
  final StreamController<List<NasServer>> _serversController =
      StreamController<List<NasServer>>.broadcast();

  bool _isInitialized = false;

  SqliteServerRepository(this._database);

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Database is already initialized in the constructor
      _isInitialized = true;

      // Emit initial servers
      final servers = await getAllServers();
      _serversController.add(servers);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('SqliteServerRepository: Initialization failed: $e');
      }
      return false;
    }
  }

  @override
  Future<List<NasServer>> getAllServers() async {
    return await _database.getAllServers();
  }

  @override
  Future<NasServer?> getServer(String id) async {
    return await _database.getServer(id);
  }

  @override
  Future<bool> saveServer(NasServer server) async {
    try {
      final existing = await _database.getServer(server.id);

      if (existing != null) {
        await _database.updateServer(server);
      } else {
        await _database.insertServer(server);
      }

      // Emit updated servers
      final servers = await getAllServers();
      _serversController.add(servers);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('SqliteServerRepository: Save failed: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> deleteServer(String id) async {
    try {
      await _database.deleteServer(id);

      // Emit updated servers
      final servers = await getAllServers();
      _serversController.add(servers);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('SqliteServerRepository: Delete failed: $e');
      }
      return false;
    }
  }

  @override
  Future<NasServer?> getDefaultServer() async {
    return await _database.getDefaultServer();
  }

  @override
  Future<bool> setDefaultServer(String id) async {
    try {
      await _database.setDefaultServer(id);

      // Emit updated servers
      final servers = await getAllServers();
      _serversController.add(servers);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('SqliteServerRepository: Set default failed: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> clearDefaultServer() async {
    try {
      await _database.clearDefaultServer();

      // Emit updated servers
      final servers = await getAllServers();
      _serversController.add(servers);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('SqliteServerRepository: Clear default failed: $e');
      }
      return false;
    }
  }

  @override
  Stream<List<NasServer>> get serversStream => _serversController.stream;

  @override
  bool get supportsOfflineAccess => true; // SQLite is always offline

  @override
  bool get supportsAutoSync => false; // No automatic sync

  @override
  Future<bool> sync() async {
    // SQLite doesn't support sync, but return true for compatibility
    return true;
  }

  @override
  Future<void> dispose() async {
    await _serversController.close();
  }
}
