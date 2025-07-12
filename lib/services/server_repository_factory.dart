import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:truehub/services/server_repository_interface.dart';
import 'package:truehub/services/cloudkit_server_repository.dart';
import 'package:truehub/services/sqlite_server_repository.dart';
import 'package:truehub/services/database.dart';

/// Factory for creating platform-appropriate server repositories
class ServerRepositoryFactory {
  static ServerRepositoryInterface? _instance;

  /// Get the appropriate server repository for the current platform
  static Future<ServerRepositoryInterface> create({
    AppDatabase? database,
    bool forceCloudKit = false,
    bool forceSqlite = false,
  }) async {
    if (_instance != null) return _instance!;

    // Platform detection
    final isApplePlatform = Platform.isIOS || Platform.isMacOS;
    final useCloudKit = (isApplePlatform && !forceSqlite) || forceCloudKit;

    if (useCloudKit) {
      if (kDebugMode) {
        print('ServerRepositoryFactory: Using CloudKit repository');
      }
      _instance = CloudKitServerRepository();
    } else {
      if (kDebugMode) {
        print('ServerRepositoryFactory: Using SQLite repository');
      }
      final db = database ?? AppDatabase();
      _instance = SqliteServerRepository(db);
    }

    final initialized = await _instance!.initialize();
    if (!initialized && useCloudKit) {
      // Fallback to SQLite if CloudKit fails
      if (kDebugMode) {
        print(
          'ServerRepositoryFactory: CloudKit failed, falling back to SQLite',
        );
      }
      final db = database ?? AppDatabase();
      _instance = SqliteServerRepository(db);
      await _instance!.initialize();
    }

    return _instance!;
  }

  /// Get the current repository instance (must call create first)
  static ServerRepositoryInterface get instance {
    if (_instance == null) {
      throw StateError(
        'ServerRepository not initialized. Call create() first.',
      );
    }
    return _instance!;
  }

  /// Reset the factory (for testing)
  static Future<void> reset() async {
    await _instance?.dispose();
    _instance = null;
  }

  /// Check if the current platform supports CloudKit
  static bool get supportsCloudKit => Platform.isIOS || Platform.isMacOS;
}
