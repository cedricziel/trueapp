import 'package:truenas_native_plugins/truenas_native_plugins.dart' as plugins;

/// Wrapper for native keychain service using the plugin
/// Stores only passwords with proper synchronization settings
class NativeKeychainService implements plugins.KeychainServiceInterface {
  final plugins.KeychainServiceInterface _keychainService;

  NativeKeychainService() : _keychainService = plugins.NativeKeychainService();

  /// Store password for server ID in synchronizable keychain
  /// Uses kSecAttrSynchronizable = true for iCloud Keychain sync
  /// Uses kSecAttrAccessibleWhenUnlocked for security + sync
  @override
  Future<bool> storePassword({
    required String serverId,
    required String password,
  }) => _keychainService.storePassword(serverId: serverId, password: password);

  /// Retrieve password for server ID from keychain
  @override
  Future<String?> getPassword({required String serverId}) =>
      _keychainService.getPassword(serverId: serverId);

  /// Delete password for server ID from keychain
  @override
  Future<bool> deletePassword({required String serverId}) =>
      _keychainService.deletePassword(serverId: serverId);

  /// Check if password exists for server ID
  @override
  Future<bool> hasPassword({required String serverId}) =>
      _keychainService.hasPassword(serverId: serverId);

  /// Get all server IDs that have passwords stored
  @override
  Future<List<String>> getAllServerIds() => _keychainService.getAllServerIds();

  /// Delete all passwords (for complete app reset)
  @override
  Future<bool> deleteAllPasswords() => _keychainService.deleteAllPasswords();

  /// Debug method to list all stored server IDs in keychain
  Future<List<String>> debugListStoredServerIds() async {
    return await getAllServerIds();
  }
}
