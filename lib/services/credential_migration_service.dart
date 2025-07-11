import 'package:flutter/foundation.dart';
import 'package:truenas_manager/services/database.dart';
import 'package:truenas_manager/services/secure_storage_service.dart';

class CredentialMigrationService {
  static const String migrationCompletedKey = 'credential_migration_completed';
  
  /// Check if all servers have credentials in secure storage
  static Future<bool> checkMigrationStatus(AppDatabase database) async {
    try {
      final servers = await database.getAllServers();
      
      for (final server in servers) {
        final hasCredentials = await SecureStorageService.hasCredentials(server.id);
        if (!hasCredentials) {
          if (kDebugMode) {
            print('CredentialMigrationService: Server ${server.id} (${server.name}) is missing credentials in secure storage');
          }
          return false;
        }
      }
      
      if (kDebugMode) {
        print('CredentialMigrationService: All ${servers.length} servers have credentials in secure storage');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('CredentialMigrationService: Error checking migration status: $e');
      }
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
      if (kDebugMode) {
        print('CredentialMigrationService: Migrating credentials for server $serverId');
      }

      final success = await SecureStorageService.migrateCredentials(
        serverId: serverId,
        username: username,
        password: password,
      );

      if (success) {
        if (kDebugMode) {
          print('CredentialMigrationService: Successfully migrated credentials for server $serverId');
        }
      } else {
        if (kDebugMode) {
          print('CredentialMigrationService: Failed to migrate credentials for server $serverId');
        }
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('CredentialMigrationService: Error migrating server credentials: $e');
      }
      return false;
    }
  }

  /// Get all stored credentials (for debugging)
  static Future<void> debugStoredCredentials(AppDatabase database) async {
    if (!kDebugMode) return;

    try {
      final servers = await database.getAllServers();
      print('CredentialMigrationService: Debug - checking ${servers.length} servers:');
      
      for (final server in servers) {
        final hasCredentials = await SecureStorageService.hasCredentials(server.id);
        print('  - ${server.name} (${server.id}): ${hasCredentials ? 'HAS' : 'MISSING'} credentials');
      }
    } catch (e) {
      print('CredentialMigrationService: Error debugging credentials: $e');
    }
  }
}