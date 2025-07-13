import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'interfaces/keychain_service_interface.dart';

/// Native keychain service using Apple's Security framework
/// Stores only passwords with proper synchronization settings
class NativeKeychainService implements KeychainServiceInterface {
  final String _channelPrefix;
  final String _serviceIdentifier;
  late final MethodChannel _methodChannel;

  static NativeKeychainService? _instance;
  static NativeKeychainService get instance =>
      _instance ??= NativeKeychainService();

  NativeKeychainService({
    String channelPrefix = 'com.cedricziel.truehub',
    String serviceIdentifier = 'com.cedricziel.truehub.server',
  })  : _channelPrefix = channelPrefix,
        _serviceIdentifier = serviceIdentifier {
    _methodChannel = MethodChannel('$_channelPrefix/keychain');
  }

  @override
  Future<bool> storePassword({
    required String serverId,
    required String password,
  }) async {
    try {
      // Only available on iOS/macOS
      if (!Platform.isIOS && !Platform.isMacOS) {
        if (kDebugMode) {
          print('KeychainService: Not available on this platform');
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
          'KeychainService: Store password for $serverId: ${result == true ? 'success' : 'failed'}',
        );
      }

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('KeychainService: Error storing password: $e');
      }
      return false;
    }
  }

  @override
  Future<String?> getPassword({required String serverId}) async {
    try {
      // Only available on iOS/macOS
      if (!Platform.isIOS && !Platform.isMacOS) {
        if (kDebugMode) {
          print('KeychainService: Not available on this platform');
        }
        return null;
      }

      final result = await _methodChannel.invokeMethod<String>('getPassword', {
        'service': _serviceIdentifier,
        'account': serverId,
      });

      if (result != null) {
        if (kDebugMode) {
          print('KeychainService: Retrieved password for $serverId');
        }
      } else if (kDebugMode) {
        print('KeychainService: No password found for $serverId');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('KeychainService: Error retrieving password: $e');
      }
      return null;
    }
  }

  @override
  Future<bool> deletePassword({required String serverId}) async {
    try {
      // Only available on iOS/macOS
      if (!Platform.isIOS && !Platform.isMacOS) {
        if (kDebugMode) {
          print('KeychainService: Not available on this platform');
        }
        return false;
      }

      final result = await _methodChannel.invokeMethod<bool>('deletePassword', {
        'service': _serviceIdentifier,
        'account': serverId,
      });

      if (kDebugMode) {
        print(
          'KeychainService: Delete password for $serverId: ${result == true ? 'success' : 'failed'}',
        );
      }

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('KeychainService: Error deleting password: $e');
      }
      return false;
    }
  }

  @override
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
        print('KeychainService: Error checking password existence: $e');
      }
      return false;
    }
  }

  @override
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
          'KeychainService: Found ${serverIds.length} server IDs with passwords',
        );
      }

      return serverIds;
    } catch (e) {
      if (kDebugMode) {
        print('KeychainService: Error getting all server IDs: $e');
      }
      return [];
    }
  }

  @override
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
          'KeychainService: Delete all passwords: ${result == true ? 'success' : 'failed'}',
        );
      }

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('KeychainService: Error deleting all passwords: $e');
      }
      return false;
    }
  }
}
