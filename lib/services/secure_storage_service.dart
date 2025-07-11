import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:truenas_manager/services/authentication_session_service.dart';

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
    bool useSession = true,
  }) async {
    try {
      // Check if we have a valid session
      if (useSession && AuthenticationSessionService.instance.isSessionValid) {
        if (kDebugMode) {
          print('SecureStorageService: Using existing authentication session');
        }
        // Extend the session on each use
        AuthenticationSessionService.instance.extendSession();
        return true;
      }

      final isAvailable = await isBiometricAvailable();
      if (!isAvailable && biometricOnly) {
        if (kDebugMode) {
          print(
            'SecureStorageService: Biometric authentication not available, but biometricOnly=true',
          );
        }
        return false;
      }

      // If biometrics aren't available but not required, skip authentication for now
      if (!isAvailable && !biometricOnly) {
        if (kDebugMode) {
          print(
            'SecureStorageService: Biometric authentication not available, skipping authentication',
          );
        }
        // Mark session as authenticated even without biometrics
        if (useSession) {
          AuthenticationSessionService.instance.markAuthenticated();
        }
        return true; // Allow access without biometrics during testing/development
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
        ),
      );

      if (authenticated && useSession) {
        // Mark the session as authenticated
        AuthenticationSessionService.instance.markAuthenticated();
        if (kDebugMode) {
          print(
            'SecureStorageService: Authentication successful, session created',
          );
        }
      }

      return authenticated;
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
      if (kDebugMode) {
        print(
          'SecureStorageService: Attempting to store credentials for server $serverId',
        );
      }

      if (requireAuthentication) {
        final authenticated = await authenticate(
          reason: 'Authenticate to save server credentials',
        );
        if (!authenticated) {
          if (kDebugMode) {
            print(
              'SecureStorageService: Authentication failed while storing credentials for server $serverId',
            );
          }
          return false;
        }
      }

      final usernameKey = _getUsernameKey(serverId);
      final passwordKey = _getPasswordKey(serverId);

      if (kDebugMode) {
        print(
          'SecureStorageService: Storing credentials with keys: $usernameKey, $passwordKey',
        );
      }

      await _storage.write(key: usernameKey, value: username);
      await _storage.write(key: passwordKey, value: password);

      if (kDebugMode) {
        print(
          'SecureStorageService: Successfully stored credentials for server $serverId',
        );
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
      // if (kDebugMode) {
      //   print('SecureStorageService: Attempting to retrieve credentials for server $serverId');
      // }

      if (requireAuthentication) {
        final authenticated = await authenticate(
          reason: 'Authenticate to access server credentials',
        );
        if (!authenticated) {
          if (kDebugMode) {
            print(
              'SecureStorageService: Authentication failed for server $serverId',
            );
          }
          return null;
        }
      }

      final usernameKey = _getUsernameKey(serverId);
      final passwordKey = _getPasswordKey(serverId);

      // if (kDebugMode) {
      //   print('SecureStorageService: Reading credentials with keys: $usernameKey, $passwordKey');
      // }

      final username = await _storage.read(key: usernameKey);
      final password = await _storage.read(key: passwordKey);

      // if (kDebugMode) {
      //   print('SecureStorageService: Retrieved credentials - username: ${username != null ? 'found' : 'not found'}, password: ${password != null ? 'found' : 'not found'}');
      // }

      if (username != null && password != null) {
        return ServerCredentials(username: username, password: password);
      }

      if (kDebugMode) {
        print(
          'SecureStorageService: No credentials found for server $serverId',
        );
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

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('SecureStorageService: Error migrating credentials: $e');
      }
      return false;
    }
  }

  /// Debug function to list all stored keys (development only)
  static Future<void> debugListStoredKeys() async {
    if (kDebugMode) {
      try {
        final allKeys = await _storage.readAll();
        print('SecureStorageService: Stored keys (${allKeys.length} total):');
        for (final key in allKeys.keys) {
          print('  - $key: ${allKeys[key] != null ? 'has value' : 'null'}');
        }
      } catch (e) {
        print('SecureStorageService: Error listing stored keys: $e');
      }
    }
  }
}
