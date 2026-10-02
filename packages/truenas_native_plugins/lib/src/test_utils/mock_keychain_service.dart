import '../interfaces/keychain_service_interface.dart';

/// Mock implementation of KeychainService for testing
class MockKeychainService implements KeychainServiceInterface {
  final Map<String, String> _passwords = {};
  bool _shouldFailOperations = false;
  int _operationDelay = 0;

  @override
  Future<bool> storePassword({
    required String serverId,
    required String password,
  }) async {
    if (_operationDelay > 0) {
      await Future.delayed(Duration(milliseconds: _operationDelay));
    }

    if (_shouldFailOperations) return false;

    _passwords[serverId] = password;

    return true;
  }

  @override
  Future<String?> getPassword({required String serverId}) async {
    if (_operationDelay > 0) {
      await Future.delayed(Duration(milliseconds: _operationDelay));
    }

    if (_shouldFailOperations) return null;

    final password = _passwords[serverId];

    return password;
  }

  @override
  Future<bool> deletePassword({required String serverId}) async {
    if (_operationDelay > 0) {
      await Future.delayed(Duration(milliseconds: _operationDelay));
    }

    if (_shouldFailOperations) return false;

    final removed = _passwords.remove(serverId) != null;

    return removed;
  }

  @override
  Future<bool> hasPassword({required String serverId}) async {
    if (_operationDelay > 0) {
      await Future.delayed(Duration(milliseconds: _operationDelay));
    }

    if (_shouldFailOperations) return false;

    return _passwords.containsKey(serverId);
  }

  @override
  Future<List<String>> getAllServerIds() async {
    if (_operationDelay > 0) {
      await Future.delayed(Duration(milliseconds: _operationDelay));
    }

    if (_shouldFailOperations) return [];

    final serverIds = _passwords.keys.toList();

    return serverIds;
  }

  @override
  Future<bool> deleteAllPasswords() async {
    if (_operationDelay > 0) {
      await Future.delayed(Duration(milliseconds: _operationDelay));
    }

    if (_shouldFailOperations) return false;

    final hadPasswords = _passwords.isNotEmpty;
    _passwords.clear();

    return hadPasswords;
  }

  // Test helpers
  void setShouldFailOperations(bool shouldFail) {
    _shouldFailOperations = shouldFail;
  }

  void setOperationDelay(int milliseconds) {
    _operationDelay = milliseconds;
  }

  void addPassword(String serverId, String password) {
    _passwords[serverId] = password;
  }

  void clearPasswords() {
    _passwords.clear();
  }

  int get passwordCount => _passwords.length;

  bool hasStoredPassword(String serverId) => _passwords.containsKey(serverId);

  String? getStoredPassword(String serverId) => _passwords[serverId];

  Map<String, String> get allPasswords => Map.from(_passwords);
}
