import 'package:flutter/foundation.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/secure_storage_service.dart';
import 'package:truehub/services/app_logger.dart';

final _log = appLogger('storage.credential_migration');

class CredentialMigrationService {
  static const String migrationCompletedKey = 'credential_migration_completed';

  /// Check if all servers have credentials in secure storage
  static Future<bool> checkMigrationStatus(AppDatabase database) async {
    try {
      final servers = await database.getAllServers();

      for (final server in servers) {
        final hasCredentials = await SecureStorageService.hasCredentials(
          server.id,
        );
        if (!hasCredentials) {
          _log.debug(
            'Server is missing credentials in secure storage',
            attributes: {'server.id': server.id},
          );
          return false;
        }
      }

      _log.debug(
        'All ${servers.length} servers have credentials in secure storage',
      );
      return true;
    } catch (e) {
      _log.error('Error checking migration status', error: e);
      return false;
    }
  }

  /// Manually migrate a server's credentials to secure storage
  static Future<bool> migrateServerCredentials({
    required String serverId,
    required String username,
    required String password,
  }) async {
    try {
      _log.debug('Migrating credentials', attributes: {'server.id': serverId});

      final success = await SecureStorageService.migrateCredentials(
        serverId: serverId,
        username: username,
        password: password,
      );

      if (success) {
        _log.info('Migrated credentials', attributes: {'server.id': serverId});
      } else {
        _log.warn(
          'Failed to migrate credentials',
          attributes: {'server.id': serverId},
        );
      }

      return success;
    } catch (e) {
      _log.error('Error migrating server credentials', error: e);
      return false;
    }
  }

  /// Get all stored credentials (for debugging)
  static Future<void> debugStoredCredentials(AppDatabase database) async {
    if (!kDebugMode) return;

    try {
      final servers = await database.getAllServers();
      _log.debug('Checking credentials of ${servers.length} servers');

      for (final server in servers) {
        final hasCredentials = await SecureStorageService.hasCredentials(
          server.id,
        );
        _log.debug(
          'Server credentials',
          attributes: {'server.id': server.id, 'present': hasCredentials},
        );
      }
    } catch (e) {
      _log.error('Error debugging credentials', error: e);
    }
  }
}
