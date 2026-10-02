import 'package:truehub/services/database.dart';
import 'package:truehub/services/native_keychain_service.dart';
import 'package:truenas_native_plugins/truenas_native_plugins.dart'
    show KeychainServiceInterface;
import 'package:truehub/services/app_logger.dart';

final _log = appLogger('storage.cleanup');

/// One-time cleanup helper to remove old servers without passwords
class DatabaseCleanup {
  static Future<void> removeServersWithoutPasswords(
    AppDatabase database, {
    KeychainServiceInterface? keychain,
  }) async {
    _log.debug('Removing servers without passwords for clean migration');

    final effectiveKeychain = keychain ?? NativeKeychainService.instance;
    final servers = await database.getAllServers();
    for (final server in servers) {
      final hasPassword = await effectiveKeychain.hasPassword(
        serverId: server.id,
      );
      if (!hasPassword) {
        _log.warn(
          'Removing server without password',
          attributes: {'server.id': server.id},
        );
        await database.deleteServer(server.id);
      }
    }

    _log.info('Cleanup completed');
  }

  /// Clean up all keychain entries for our app (for development/testing)
  static Future<void> cleanupAllKeychainEntries() async {
    _log.info('Cleaning up all keychain entries');

    try {
      final keychain = NativeKeychainService.instance;

      // Clean up all entries with our service identifier
      final success = await keychain.deleteAllPasswords();

      if (success) {
        _log.info('Keychain cleanup successful');
      } else {
        _log.warn('Keychain cleanup failed');
      }
    } catch (e) {
      _log.error('Error cleaning keychain', error: e);
    }
  }

  /// Complete cleanup - both database and keychain
  static Future<void> completeCleanup(AppDatabase database) async {
    await removeServersWithoutPasswords(database);
    await cleanupAllKeychainEntries();
  }
}
