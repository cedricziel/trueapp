import 'dart:async';
import 'package:drift/native.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/providers/pool_provider.dart';
import 'package:truehub/providers/dataset_provider.dart';

// Mock implementation of UnifiedServerService for testing
class MockUnifiedServerService implements UnifiedServerService {
  final Map<String, String> _passwords = {};
  final Map<String, NasServer> _servers = {};
  final StreamController<List<NasServer>> _serversController =
      StreamController<List<NasServer>>.broadcast();

  @override
  Future<bool> initialize() async {
    return true;
  }

  @override
  Future<bool> saveServerConfig({
    required NasServer server,
    required String password,
  }) async {
    _passwords[server.id] = password;
    _servers[server.id] = server;
    _serversController.add(_servers.values.toList());
    return true;
  }

  @override
  Future<bool> updateServerConfig(NasServer server) async {
    _servers[server.id] = server;
    _serversController.add(_servers.values.toList());
    return true;
  }

  @override
  Future<String?> getPassword(String serverId) async {
    return _passwords[serverId];
  }

  @override
  Future<(NasServer?, String?)> getServerWithPassword(String serverId) async {
    final server = _servers[serverId];
    final password = _passwords[serverId];
    return (server, password);
  }

  @override
  Future<List<NasServer>> getAllServers() async {
    return _servers.values.toList();
  }

  @override
  Future<NasServer?> getServer(String id) async {
    return _servers[id];
  }

  @override
  Future<bool> deleteServerConfig(String serverId) async {
    _passwords.remove(serverId);
    _servers.remove(serverId);
    _serversController.add(_servers.values.toList());
    return true;
  }

  @override
  Future<NasServer?> getDefaultServer() async {
    try {
      return _servers.values.firstWhere((server) => server.isDefault);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> setDefaultServer(String serverId) async {
    // Clear all defaults
    for (final server in _servers.values) {
      _servers[server.id] = server.copyWith(isDefault: false);
    }
    // Set new default
    final server = _servers[serverId];
    if (server != null) {
      _servers[serverId] = server.copyWith(isDefault: true);
      _serversController.add(_servers.values.toList());
      return true;
    }
    return false;
  }

  @override
  Future<bool> clearDefaultServer() async {
    for (final server in _servers.values) {
      _servers[server.id] = server.copyWith(isDefault: false);
    }
    _serversController.add(_servers.values.toList());
    return true;
  }

  @override
  Stream<List<NasServer>> get serversStream => _serversController.stream;

  @override
  bool get isInitialized => true;

  @override
  bool get supportsOfflineAccess => true;

  @override
  bool get supportsAutoSync => true;

  @override
  Future<bool> sync() async => true;

  @override
  Future<void> dispose() async {
    await _serversController.close();
  }
}

class MockAppDatabase extends AppDatabase {
  MockAppDatabase() : super.forTesting(NativeDatabase.memory());
}

// Helper function to create test providers with mocks
class TestProviders {
  static MockUnifiedServerService createMockUnifiedServerService() {
    return MockUnifiedServerService();
  }

  static ServerProvider createServerProvider() {
    return ServerProvider(createMockUnifiedServerService());
  }

  static PoolProvider createPoolProvider() {
    return PoolProvider(createMockUnifiedServerService());
  }

  static DatasetProvider createDatasetProvider() {
    return DatasetProvider(createMockUnifiedServerService());
  }
}
