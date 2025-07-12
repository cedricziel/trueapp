import 'package:flutter/foundation.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/native_keychain_service.dart';

/// One-time cleanup helper to remove old servers without passwords
class DatabaseCleanup {
  static Future<void> removeServersWithoutPasswords(
    AppDatabase database,
  ) async {
    if (kDebugMode) {
      print(
        'DatabaseCleanup: Removing servers without passwords for clean migration',
      );
    }

    final servers = await database.getAllServers();
    for (final server in servers) {
      if (server.password.isEmpty) {
        if (kDebugMode) {
          print(
            'DatabaseCleanup: Removing server ${server.id} (${server.name}) - no password',
          );
        }
        await database.deleteServer(server.id);
      }
    }

    if (kDebugMode) {
      print('DatabaseCleanup: Cleanup completed');
    }
  }

  /// Clean up all keychain entries for our app (for development/testing)
  static Future<void> cleanupAllKeychainEntries() async {
    if (kDebugMode) {
      print('DatabaseCleanup: Cleaning up all keychain entries');
    }

    try {
      final keychain = NativeKeychainService.instance;

      // Clean up all entries with our service identifier
      final success = await keychain.deleteAllPasswords();

      if (kDebugMode) {
        print(
          'DatabaseCleanup: Keychain cleanup ${success ? 'successful' : 'failed'}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('DatabaseCleanup: Error cleaning keychain: $e');
      }
    }
  }

  /// Complete cleanup - both database and keychain
  static Future<void> completeCleanup(AppDatabase database) async {
    await removeServersWithoutPasswords(database);
    await cleanupAllKeychainEntries();
  }
}
