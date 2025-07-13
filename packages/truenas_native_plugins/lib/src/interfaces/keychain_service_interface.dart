/// Interface for Keychain service implementations
abstract class KeychainServiceInterface {
  /// Store password for server ID in keychain
  Future<bool> storePassword({
    required String serverId,
    required String password,
  });

  /// Retrieve password for server ID from keychain
  Future<String?> getPassword({required String serverId});

  /// Delete password for server ID from keychain
  Future<bool> deletePassword({required String serverId});

  /// Check if password exists for server ID
  Future<bool> hasPassword({required String serverId});

  /// Get all server IDs that have passwords stored
  Future<List<String>> getAllServerIds();

  /// Delete all passwords (for complete app reset)
  Future<bool> deleteAllPasswords();
}
