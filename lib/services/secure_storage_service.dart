import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class ServerCredentials {
  final String username;
  final String password;

  const ServerCredentials({required this.username, required this.password});
}

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static final LocalAuthentication _localAuth = LocalAuthentication();

  static String _getUsernameKey(String serverId) => 'server_username_$serverId';
  static String _getPasswordKey(String serverId) => 'server_password_$serverId';

  /// Check if biometric authentication is available on this device
  static Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      if (kDebugMode) {
        print(
          'SecureStorageService: Error checking biometric availability: $e',
        );
      }
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      if (kDebugMode) {
        print('SecureStorageService: Error getting available biometrics: $e');
      }
      return [];
    }
  }

  /// Authenticate user with biometrics
  static Future<bool> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable && biometricOnly) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('SecureStorageService: Authentication error: $e');
      }
      return false;
    }
  }

  /// Store server credentials securely
  static Future<bool> storeCredentials({
    required String serverId,
    required String username,
    required String password,
    bool requireAuthentication = true,
  }) async {
    try {
      if (requireAuthentication) {
        final authenticated = await authenticate(
          reason: 'Authenticate to save server credentials',
        );
        if (!authenticated) {
          return false;
        }
      }

      await _storage.write(key: _getUsernameKey(serverId), value: username);
      await _storage.write(key: _getPasswordKey(serverId), value: password);

      if (kDebugMode) {
        print('SecureStorageService: Credentials stored for server $serverId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('SecureStorageService: Error storing credentials: $e');
      }
      return false;
    }
  }

  /// Retrieve server credentials securely
  static Future<ServerCredentials?> getCredentials({
    required String serverId,
    bool requireAuthentication = true,
  }) async {
    try {
      if (requireAuthentication) {
        final authenticated = await authenticate(
          reason: 'Authenticate to access server credentials',
        );
        if (!authenticated) {
          return null;
        }
      }

      final username = await _storage.read(key: _getUsernameKey(serverId));
      final password = await _storage.read(key: _getPasswordKey(serverId));

      if (username != null && password != null) {
        return ServerCredentials(username: username, password: password);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('SecureStorageService: Error retrieving credentials: $e');
      }
      return null;
    }
  }

  /// Check if credentials exist for a server
  static Future<bool> hasCredentials(String serverId) async {
    try {
      final username = await _storage.read(key: _getUsernameKey(serverId));
      final password = await _storage.read(key: _getPasswordKey(serverId));
      return username != null && password != null;
    } catch (e) {
      if (kDebugMode) {
        print('SecureStorageService: Error checking credentials: $e');
      }
      return false;
    }
  }

  /// Delete server credentials
  static Future<bool> deleteCredentials({
    required String serverId,
    bool requireAuthentication = true,
  }) async {
    try {
      if (requireAuthentication) {
        final authenticated = await authenticate(
          reason: 'Authenticate to delete server credentials',
        );
        if (!authenticated) {
          return false;
        }
      }

      await _storage.delete(key: _getUsernameKey(serverId));
      await _storage.delete(key: _getPasswordKey(serverId));

      if (kDebugMode) {
        print('SecureStorageService: Credentials deleted for server $serverId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('SecureStorageService: Error deleting credentials: $e');
      }
      return false;
    }
  }

  /// Delete all stored credentials (for complete app reset)
  static Future<bool> deleteAllCredentials({
    bool requireAuthentication = true,
  }) async {
    try {
      if (requireAuthentication) {
        final authenticated = await authenticate(
          reason: 'Authenticate to delete all server credentials',
        );
        if (!authenticated) {
          return false;
        }
      }

      await _storage.deleteAll();

      if (kDebugMode) {
        print('SecureStorageService: All credentials deleted');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('SecureStorageService: Error deleting all credentials: $e');
      }
      return false;
    }
  }

  /// Migrate credentials from plaintext to secure storage
  static Future<bool> migrateCredentials({
    required String serverId,
    required String username,
    required String password,
  }) async {
    try {
      // Store credentials without requiring authentication during migration
      final success = await storeCredentials(
        serverId: serverId,
        username: username,
        password: password,
        requireAuthentication: false,
      );

      if (success && kDebugMode) {
        print(
          'SecureStorageService: Migrated credentials for server $serverId',
        );
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('SecureStorageService: Error migrating credentials: $e');
      }
      return false;
    }
  }
}
