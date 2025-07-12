import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native keychain service using Apple's Security framework
/// Stores only passwords with proper synchronization settings
class NativeKeychainService {
  static const _methodChannel = MethodChannel(
    'com.cedricziel.truehub/keychain',
  );

  static NativeKeychainService? _instance;
  static NativeKeychainService get instance =>
      _instance ??= NativeKeychainService._();

  NativeKeychainService._();

  static const String _serviceIdentifier = 'com.cedricziel.truehub.server';

  /// Store password for server ID in synchronizable keychain
  /// Uses kSecAttrSynchronizable = true for iCloud Keychain sync
  /// Uses kSecAttrAccessibleWhenUnlocked for security + sync
  Future<bool> storePassword({
    required String serverId,
    required String password,
  }) async {
    try {
      // Only available on iOS/macOS
      if (!Platform.isIOS && !Platform.isMacOS) {
        if (kDebugMode) {
          print('NativeKeychainService: Not available on this platform');
        }
        return false;
      }

      final result = await _methodChannel.invokeMethod<bool>('storePassword', {
        'service': _serviceIdentifier,
        'account': serverId, // UUID that matches CloudKit recordID
        'password': password,
        'synchronizable': true, // Enable iCloud Keychain sync
        'accessible': 'WhenUnlocked', // Required for sync
      });

      if (kDebugMode) {
        print(
          'NativeKeychainService: Store password for $serverId: ${result == true ? 'success' : 'failed'}',
        );
      }

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('NativeKeychainService: Error storing password: $e');
      }
      return false;
    }
  }

  /// Retrieve password for server ID from keychain
  Future<String?> getPassword({required String serverId}) async {
    try {
      // Only available on iOS/macOS
      if (!Platform.isIOS && !Platform.isMacOS) {
        if (kDebugMode) {
          print('NativeKeychainService: Not available on this platform');
        }
        return null;
      }

      final result = await _methodChannel.invokeMethod<String>('getPassword', {
        'service': _serviceIdentifier,
        'account': serverId,
      });

      if (result != null) {
        if (kDebugMode) {
          print('NativeKeychainService: Retrieved password for $serverId');
        }
      } else if (kDebugMode) {
        print('NativeKeychainService: No password found for $serverId');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('NativeKeychainService: Error retrieving password: $e');
      }
      return null;
    }
  }

  /// Delete password for server ID from keychain
  Future<bool> deletePassword({required String serverId}) async {
    try {
      // Only available on iOS/macOS
      if (!Platform.isIOS && !Platform.isMacOS) {
        if (kDebugMode) {
          print('NativeKeychainService: Not available on this platform');
        }
        return false;
      }

      final result = await _methodChannel.invokeMethod<bool>('deletePassword', {
        'service': _serviceIdentifier,
        'account': serverId,
      });

      if (kDebugMode) {
        print(
          'NativeKeychainService: Delete password for $serverId: ${result == true ? 'success' : 'failed'}',
        );
      }

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('NativeKeychainService: Error deleting password: $e');
      }
      return false;
    }
  }

  /// Check if password exists for server ID
  Future<bool> hasPassword({required String serverId}) async {
    try {
      // Only available on iOS/macOS
      if (!Platform.isIOS && !Platform.isMacOS) {
        return false;
      }

      final result = await _methodChannel.invokeMethod<bool>('hasPassword', {
        'service': _serviceIdentifier,
        'account': serverId,
      });

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('NativeKeychainService: Error checking password existence: $e');
      }
      return false;
    }
  }

  /// Get all server IDs that have passwords stored
  Future<List<String>> getAllServerIds() async {
    try {
      // Only available on iOS/macOS
      if (!Platform.isIOS && !Platform.isMacOS) {
        return [];
      }

      final result = await _methodChannel.invokeMethod<List<dynamic>>(
        'getAllServerIds',
        {'service': _serviceIdentifier},
      );

      final serverIds = result?.cast<String>() ?? [];

      if (kDebugMode) {
        print(
          'NativeKeychainService: Found ${serverIds.length} server IDs with passwords',
        );
      }

      return serverIds;
    } catch (e) {
      if (kDebugMode) {
        print('NativeKeychainService: Error getting all server IDs: $e');
      }
      return [];
    }
  }

  /// Delete all passwords (for complete app reset)
  Future<bool> deleteAllPasswords() async {
    try {
      // Only available on iOS/macOS
      if (!Platform.isIOS && !Platform.isMacOS) {
        return false;
      }

      final result = await _methodChannel.invokeMethod<bool>(
        'deleteAllPasswords',
        {'service': _serviceIdentifier},
      );

      if (kDebugMode) {
        print(
          'NativeKeychainService: Delete all passwords: ${result == true ? 'success' : 'failed'}',
        );
      }

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('NativeKeychainService: Error deleting all passwords: $e');
      }
      return false;
    }
  }

  /// Debug method to list all stored server IDs in keychain
  Future<List<String>> debugListStoredServerIds() async {
    try {
      if (!Platform.isIOS && !Platform.isMacOS) {
        return [];
      }

      final result = await _methodChannel.invokeMethod<List<dynamic>>(
        'getAllServerIds',
        {'service': _serviceIdentifier},
      );

      final serverIds = result?.cast<String>() ?? [];

      if (kDebugMode) {
        print(
          'NativeKeychainService: Found ${serverIds.length} stored passwords:',
        );
        for (final id in serverIds) {
          print('  - $id');
        }
      }

      return serverIds;
    } catch (e) {
      if (kDebugMode) {
        print('NativeKeychainService: Error listing stored server IDs: $e');
      }
      return [];
    }
  }

  /// Debug method to check if password exists with old flutter_secure_storage pattern
  Future<String?> debugGetPasswordWithOldPattern(String serverId) async {
    try {
      if (!Platform.isIOS && !Platform.isMacOS) {
        return null;
      }

      // Old flutter_secure_storage used these patterns
      final oldPasswordKey = 'server_password_$serverId';

      final result = await _methodChannel.invokeMethod<String>('getPassword', {
        'service':
            'flutter_secure_storage', // flutter_secure_storage default service
        'account': oldPasswordKey,
      });

      if (kDebugMode) {
        print(
          'NativeKeychainService: Old pattern check for $serverId: ${result != null ? 'found' : 'not found'}',
        );
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('NativeKeychainService: Error checking old pattern: $e');
      }
      return null;
    }
  }
}
