import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:truehub/services/authentication_session_service.dart';
import 'package:truehub/models/keychain_server_config.dart';
import 'package:truehub/services/app_logger.dart';

final _log = appLogger('storage.secure');

class ServerCredentials {
  final String username;
  final String password;

  const ServerCredentials({required this.username, required this.password});
}

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    // flutter_secure_storage >= 10 always uses encrypted storage on Android.
    aOptions: AndroidOptions.defaultOptions,
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: true,
      groupId: 'com.cedricziel.truehub.shared',
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: true,
      groupId: 'com.cedricziel.truehub.shared',
    ),
  );

  static final LocalAuthentication _localAuth = LocalAuthentication();

  static String _getUsernameKey(String serverId) => 'server_username_$serverId';
  static String _getPasswordKey(String serverId) => 'server_password_$serverId';
  static String _getServerConfigKey(String serverId) =>
      'server_config_$serverId';
  static const String _serverListKey = 'server_list';

  /// Check if biometric authentication is available on this device
  static Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      _log.error('Error checking biometric availability', error: e);
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      _log.error('Error getting available biometrics', error: e);
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
        _log.info('Using existing authentication session');
        // Extend the session on each use
        AuthenticationSessionService.instance.extendSession();
        return true;
      }

      final isAvailable = await isBiometricAvailable();
      if (!isAvailable && biometricOnly) {
        _log.debug(
          'Biometric authentication not available, but biometricOnly=true',
        );
        return false;
      }

      // If biometrics aren't available but not required, skip authentication for now
      if (!isAvailable && !biometricOnly) {
        _log.debug(
          'Biometric authentication not available, skipping authentication',
        );
        // Mark session as authenticated even without biometrics
        if (useSession) {
          AuthenticationSessionService.instance.markAuthenticated();
        }
        return true; // Allow access without biometrics during testing/development
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: biometricOnly,
        // local_auth 3.x name for stickyAuth: retry instead of failing when
        // the app is backgrounded mid-authentication.
        persistAcrossBackgrounding: true,
      );

      if (authenticated && useSession) {
        // Mark the session as authenticated
        AuthenticationSessionService.instance.markAuthenticated();
        _log.debug('Authentication successful, session created');
      }

      return authenticated;
    } catch (e) {
      _log.error('Authentication error', error: e);
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
      _log.debug(
        'Attempting to store credentials',
        attributes: {'server.id': serverId},
      );

      if (requireAuthentication) {
        final authenticated = await authenticate(
          reason: 'Authenticate to save server credentials',
        );
        if (!authenticated) {
          _log.warn(
            'Authentication failed while storing credentials',
            attributes: {'server.id': serverId},
          );
          return false;
        }
      }

      final usernameKey = _getUsernameKey(serverId);
      final passwordKey = _getPasswordKey(serverId);

      await _storage.write(key: usernameKey, value: username);
      await _storage.write(key: passwordKey, value: password);

      _log.info('Stored credentials', attributes: {'server.id': serverId});
      return true;
    } catch (e) {
      _log.error('Error storing credentials', error: e);
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
          _log.warn(
            'Authentication failed',
            attributes: {'server.id': serverId},
          );
          return null;
        }
      }

      final usernameKey = _getUsernameKey(serverId);
      final passwordKey = _getPasswordKey(serverId);

      final username = await _storage.read(key: usernameKey);
      final password = await _storage.read(key: passwordKey);

      if (username != null && password != null) {
        return ServerCredentials(username: username, password: password);
      }

      _log.warn('No credentials found', attributes: {'server.id': serverId});
      return null;
    } catch (e) {
      _log.error('Error retrieving credentials', error: e);
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
      _log.error('Error checking credentials', error: e);
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

      _log.debug('Credentials deleted', attributes: {'server.id': serverId});
      return true;
    } catch (e) {
      _log.error('Error deleting credentials', error: e);
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

      _log.debug('All credentials deleted');
      return true;
    } catch (e) {
      _log.error('Error deleting all credentials', error: e);
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
      _log.error('Error migrating credentials', error: e);
      return false;
    }
  }

  /// Debug function to list all stored keys (development only)
  static Future<void> debugListStoredKeys() async {
    if (kDebugMode) {
      try {
        final allKeys = await _storage.readAll();
        _log.debug(
          'Stored keys',
          attributes: {'count': allKeys.length, 'keys': allKeys.keys.join(',')},
        );
      } catch (e) {
        _log.error('Error listing stored keys', error: e);
      }
    }
  }

  /// Store complete server configuration in keychain
  static Future<bool> storeServerConfig({
    required KeychainServerConfig config,
    bool requireAuthentication = true,
  }) async {
    try {
      _log.debug(
        'Attempting to store server config',
        attributes: {'server.id': config.id},
      );

      if (requireAuthentication) {
        final authenticated = await authenticate(
          reason: 'Authenticate to save server configuration',
        );
        if (!authenticated) {
          return false;
        }
      }

      // Store the complete config as JSON
      final configKey = _getServerConfigKey(config.id);
      await _storage.write(key: configKey, value: config.toJsonString());

      // Also store in legacy format for backward compatibility
      await _storage.write(
        key: _getUsernameKey(config.id),
        value: config.username,
      );
      await _storage.write(
        key: _getPasswordKey(config.id),
        value: config.password,
      );

      // Update server list
      await _addToServerList(config.id);

      _log.info('Stored server config', attributes: {'server.id': config.id});
      return true;
    } catch (e) {
      _log.error('Error storing server config', error: e);
      return false;
    }
  }

  /// Retrieve complete server configuration from keychain
  static Future<KeychainServerConfig?> getServerConfig({
    required String serverId,
    bool requireAuthentication = true,
  }) async {
    try {
      if (requireAuthentication) {
        final authenticated = await authenticate(
          reason: 'Authenticate to access server configuration',
        );
        if (!authenticated) {
          return null;
        }
      }

      final configKey = _getServerConfigKey(serverId);
      final configJson = await _storage.read(key: configKey);

      if (configJson != null) {
        return KeychainServerConfig.fromJsonString(configJson);
      }

      // Fall back to legacy format if no complete config exists
      final credentials = await getCredentials(
        serverId: serverId,
        requireAuthentication: false,
      );
      if (credentials != null) {
        _log.debug(
          'Found legacy credentials but no complete config',
          attributes: {'server.id': serverId},
        );
      }

      return null;
    } catch (e) {
      _log.error('Error retrieving server config', error: e);
      return null;
    }
  }

  /// Get list of all server IDs stored in keychain
  static Future<List<String>> getServerList() async {
    try {
      final serverListJson = await _storage.read(key: _serverListKey);
      if (serverListJson != null) {
        final List<dynamic> list = jsonDecode(serverListJson);
        return list.cast<String>();
      }
      return [];
    } catch (e) {
      _log.error('Error retrieving server list', error: e);
      return [];
    }
  }

  /// Add server ID to the server list
  static Future<void> _addToServerList(String serverId) async {
    try {
      final serverList = await getServerList();
      if (!serverList.contains(serverId)) {
        serverList.add(serverId);
        await _storage.write(
          key: _serverListKey,
          value: jsonEncode(serverList),
        );
      }
    } catch (e) {
      _log.error('Error updating server list', error: e);
    }
  }

  /// Remove server ID from the server list
  static Future<void> _removeFromServerList(String serverId) async {
    try {
      final serverList = await getServerList();
      serverList.remove(serverId);
      await _storage.write(key: _serverListKey, value: jsonEncode(serverList));
    } catch (e) {
      _log.error('Error updating server list', error: e);
    }
  }

  /// Delete complete server configuration
  static Future<bool> deleteServerConfig({
    required String serverId,
    bool requireAuthentication = true,
  }) async {
    try {
      if (requireAuthentication) {
        final authenticated = await authenticate(
          reason: 'Authenticate to delete server configuration',
        );
        if (!authenticated) {
          return false;
        }
      }

      // Delete all server-related keys
      await _storage.delete(key: _getServerConfigKey(serverId));
      await _storage.delete(key: _getUsernameKey(serverId));
      await _storage.delete(key: _getPasswordKey(serverId));

      // Remove from server list
      await _removeFromServerList(serverId);

      _log.debug('Server config deleted', attributes: {'server.id': serverId});
      return true;
    } catch (e) {
      _log.error('Error deleting server config', error: e);
      return false;
    }
  }

  /// Check if server config exists in keychain
  static Future<bool> hasServerConfig(String serverId) async {
    try {
      final configKey = _getServerConfigKey(serverId);
      final config = await _storage.read(key: configKey);
      return config != null;
    } catch (e) {
      _log.error('Error checking server config', error: e);
      return false;
    }
  }
}
