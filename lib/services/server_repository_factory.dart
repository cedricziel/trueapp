import 'dart:io';

import 'package:truehub/services/server_repository_interface.dart';
import 'package:truehub/services/cloudkit_server_repository.dart';
import 'package:truehub/services/cloudkit_service_interface.dart';
import 'package:truehub/services/sqlite_server_repository.dart';
import 'package:truehub/services/database/dao_source.dart';
import 'package:truehub/services/app_logger.dart';
import 'package:truehub/services/telemetry_service_interface.dart';
import 'package:truehub/services/tracing_server_repository.dart';

final _log = appLogger('storage.repository_factory');

/// Factory for creating platform-appropriate server repositories
class ServerRepositoryFactory {
  ServerRepositoryFactory({
    required this._serversDaoSource,
    required this._cloudKitServiceBuilder,
    bool? isApplePlatform,
    this._telemetry,
  }) : _isApplePlatform = isApplePlatform ?? supportsCloudKit;

  final ServersDaoSource _serversDaoSource;
  final CloudKitServiceInterface Function() _cloudKitServiceBuilder;
  final bool _isApplePlatform;
  final TelemetryServiceInterface? _telemetry;

  /// Creates and initializes the appropriate server repository for the
  /// current platform.
  Future<ServerRepositoryInterface> create({
    bool forceCloudKit = false,
    bool forceSqlite = false,
  }) async {
    final useCloudKit = (_isApplePlatform && !forceSqlite) || forceCloudKit;

    final ServerRepositoryInterface repository;
    CloudKitServiceInterface? cloudKitService;
    if (useCloudKit) {
      _log.info('Using CloudKit repository');
      cloudKitService = _cloudKitServiceBuilder();
      repository = _traced(
        CloudKitServerRepository(cloudKitService: cloudKitService),
        'cloudkit',
      );
    } else {
      _log.info('Using SQLite repository');
      repository = _traced(_sqliteRepository(), 'sqlite');
    }

    final initialized = await repository.initialize();
    if (!initialized && useCloudKit) {
      // Fallback to SQLite if CloudKit fails
      _log.warn('CloudKit failed, falling back to SQLite');
      await repository.dispose();
      cloudKitService?.dispose();
      final fallback = _traced(_sqliteRepository(), 'sqlite');
      await fallback.initialize();
      return fallback;
    }

    return repository;
  }

  ServerRepositoryInterface _traced(
    ServerRepositoryInterface inner,
    String dbSystem,
  ) {
    final telemetry = _telemetry;
    if (telemetry == null) return inner;
    return TracingServerRepository(
      inner: inner,
      telemetry: telemetry,
      dbSystem: dbSystem,
    );
  }

  SqliteServerRepository _sqliteRepository() =>
      SqliteServerRepository(_serversDaoSource);

  /// Check if the current platform supports CloudKit
  static bool get supportsCloudKit => Platform.isIOS || Platform.isMacOS;
}
