part of 'server_repository_interface_test.dart';

/// Mock implementation of ServerRepositoryInterface for contract testing
class MockServerRepositoryImplementation implements ServerRepositoryInterface {
  final Map<String, NasServer> _servers = {};
  final StreamController<List<NasServer>> _serversController =
      StreamController<List<NasServer>>.broadcast();

  bool _isInitialized = false;
  String? _defaultServerId;
  bool _shouldFailOperations = false;

  void setShouldFailOperations(bool shouldFail) {
    _shouldFailOperations = shouldFail;
  }

  @override
  Future<bool> initialize() async {
    if (_shouldFailOperations) return false;

    _isInitialized = true;
    _emitServers();
    return true;
  }

  @override
  Future<List<NasServer>> getAllServers() async {
    if (!_isInitialized) throw StateError('Repository not initialized');
    if (_shouldFailOperations) throw Exception('Operation failed');

    return _servers.values.toList();
  }

  @override
  Future<NasServer?> getServer(String id) async {
    if (!_isInitialized) throw StateError('Repository not initialized');
    if (_shouldFailOperations) return null;

    return _servers[id];
  }

  @override
  Future<bool> saveServer(NasServer server) async {
    if (!_isInitialized) throw StateError('Repository not initialized');
    if (_shouldFailOperations) return false;

    _servers[server.id] = server;
    _emitServers();
    return true;
  }

  @override
  Future<bool> deleteServer(String id) async {
    if (!_isInitialized) throw StateError('Repository not initialized');
    if (_shouldFailOperations) return false;

    final removed = _servers.remove(id) != null;
    if (removed) {
      // Clear default if deleted server was default
      if (_defaultServerId == id) {
        _defaultServerId = null;
      }
      _emitServers();
    }
    return removed;
  }

  @override
  Future<NasServer?> getDefaultServer() async {
    if (!_isInitialized) throw StateError('Repository not initialized');
    if (_shouldFailOperations) return null;

    if (_defaultServerId == null) return null;
    final server = _servers[_defaultServerId];
    return server?.copyWith(isDefault: true);
  }

  @override
  Future<bool> setDefaultServer(String id) async {
    if (!_isInitialized) throw StateError('Repository not initialized');
    if (_shouldFailOperations) return false;

    if (!_servers.containsKey(id)) return false;

    // Clear previous default
    if (_defaultServerId != null) {
      final previousDefault = _servers[_defaultServerId!];
      if (previousDefault != null) {
        _servers[_defaultServerId!] = previousDefault.copyWith(
          isDefault: false,
        );
      }
    }

    // Set new default
    _defaultServerId = id;
    final server = _servers[id]!;
    _servers[id] = server.copyWith(isDefault: true);

    _emitServers();
    return true;
  }

  @override
  Future<bool> clearDefaultServer() async {
    if (!_isInitialized) throw StateError('Repository not initialized');
    if (_shouldFailOperations) return false;

    if (_defaultServerId != null) {
      final server = _servers[_defaultServerId!];
      if (server != null) {
        _servers[_defaultServerId!] = server.copyWith(isDefault: false);
      }
      _defaultServerId = null;
      _emitServers();
    }
    return true;
  }

  @override
  Stream<List<NasServer>> get serversStream => _serversController.stream;

  @override
  bool get supportsOfflineAccess => true;

  @override
  bool get supportsAutoSync => false;

  @override
  Future<bool> sync() async {
    if (!_isInitialized) throw StateError('Repository not initialized');
    if (_shouldFailOperations) return false;

    // Mock sync operation
    _emitServers();
    return true;
  }

  @override
  Future<void> dispose() async {
    await _serversController.close();
    _servers.clear();
    _isInitialized = false;
    _defaultServerId = null;
  }

  void _emitServers() {
    if (!_serversController.isClosed) {
      _serversController.add(_servers.values.toList());
    }
  }

  // Test helpers
  int get serverCount => _servers.length;
  bool get isInitialized => _isInitialized;
}
