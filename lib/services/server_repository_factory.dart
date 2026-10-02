import 'dart:io';
import 'package:truehub/services/server_repository_interface.dart';
import 'package:truehub/services/cloudkit_server_repository.dart';
import 'package:truehub/services/cloudkit_service_interface.dart';
import 'package:truehub/services/sqlite_server_repository.dart';
import 'package:truehub/services/database/dao_source.dart';
import 'package:truehub/services/app_logger.dart';

final _log = appLogger('storage.repository_factory');

/// Factory for creating platform-appropriate server repositories
class ServerRepositoryFactory {
  ServerRepositoryFactory({
    required ServersDaoSource serversDaoSource,
    required CloudKitServiceInterface Function() cloudKitServiceBuilder,
    bool? isApplePlatform,
  }) : _serversDaoSource = serversDaoSource,
       _cloudKitServiceBuilder = cloudKitServiceBuilder,
       _isApplePlatform = isApplePlatform ?? supportsCloudKit;

  final ServersDaoSource _serversDaoSource;
  final CloudKitServiceInterface Function() _cloudKitServiceBuilder;
  final bool _isApplePlatform;

  /// Creates and initializes the appropriate server repository for the
  /// current platform.
  Future<ServerRepositoryInterface> create({
    bool forceCloudKit = false,
    bool forceSqlite = false,
  }) async {
    final useCloudKit = (_isApplePlatform && !forceSqlite) || forceCloudKit;

    final ServerRepositoryInterface repository;
    if (useCloudKit) {
      _log.info('Using CloudKit repository');
      repository = CloudKitServerRepository(
        cloudKitService: _cloudKitServiceBuilder(),
      );
    } else {
      _log.info('Using SQLite repository');
      repository = _sqliteRepository();
    }

    final initialized = await repository.initialize();
    if (!initialized && useCloudKit) {
      // Fallback to SQLite if CloudKit fails
      _log.warn('CloudKit failed, falling back to SQLite');
      final fallback = _sqliteRepository();
      await fallback.initialize();
      return fallback;
    }

    return repository;
  }

  SqliteServerRepository _sqliteRepository() =>
      SqliteServerRepository(_serversDaoSource);

  /// Check if the current platform supports CloudKit
  static bool get supportsCloudKit => Platform.isIOS || Platform.isMacOS;
}
