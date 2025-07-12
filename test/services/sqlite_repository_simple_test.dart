import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/sqlite_server_repository.dart';
import 'package:truehub/services/database.dart';

/// Mock implementation of AppDatabase for testing
class MockAppDatabase implements AppDatabase {
  final Map<String, NasServer> _servers = {};
  String? _defaultServerId;
  bool _shouldThrowErrors = false;

  void setShouldThrowErrors(bool shouldThrow) {
    _shouldThrowErrors = shouldThrow;
  }

  @override
  Future<List<NasServer>> getAllServers() async {
    if (_shouldThrowErrors) throw Exception('Database error');
    
    return _servers.values.map((server) {
      final isDefault = server.id == _defaultServerId;
      return isDefault ? server.copyWith(isDefault: true) : server;
    }).toList();
  }

  @override
  Future<NasServer?> getServer(String id) async {
    if (_shouldThrowErrors) throw Exception('Database error');
    
    final server = _servers[id];
    if (server == null) return null;
    
    final isDefault = server.id == _defaultServerId;
    return isDefault ? server.copyWith(isDefault: true) : server;
  }

  @override
  Future<void> insertServer(NasServer server) async {
    if (_shouldThrowErrors) throw Exception('Database error');
    _servers[server.id] = server;
  }

  @override
  Future<void> updateServer(NasServer server) async {
    if (_shouldThrowErrors) throw Exception('Database error');
    if (!_servers.containsKey(server.id)) {
      throw Exception('Server not found');
    }
    _servers[server.id] = server;
  }

  @override
  Future<void> deleteServer(String id) async {
    if (_shouldThrowErrors) throw Exception('Database error');
    
    final removed = _servers.remove(id) != null;
    if (!removed) throw Exception('Server not found');
    
    if (_defaultServerId == id) {
      _defaultServerId = null;
    }
  }

  @override
  Future<NasServer?> getDefaultServer() async {
    if (_shouldThrowErrors) throw Exception('Database error');
    
    if (_defaultServerId == null) return null;
    final server = _servers[_defaultServerId];
    return server?.copyWith(isDefault: true);
  }

  @override
  Future<void> setDefaultServer(String id) async {
    if (_shouldThrowErrors) throw Exception('Database error');
    
    if (!_servers.containsKey(id)) {
      throw Exception('Server not found');
    }
    
    if (_defaultServerId != null) {
      final previousDefault = _servers[_defaultServerId!];
      if (previousDefault != null) {
        _servers[_defaultServerId!] = previousDefault.copyWith(isDefault: false);
      }
    }
    
    _defaultServerId = id;
    final server = _servers[id]!;
    _servers[id] = server.copyWith(isDefault: true);
  }

  @override
  Future<void> clearDefaultServer() async {
    if (_shouldThrowErrors) throw Exception('Database error');
    
    if (_defaultServerId != null) {
      final server = _servers[_defaultServerId!];
      if (server != null) {
        _servers[_defaultServerId!] = server.copyWith(isDefault: false);
      }
      _defaultServerId = null;
    }
  }

  int get serverCount => _servers.length;
  bool get hasDefaultServer => _defaultServerId != null;
  String? get defaultServerId => _defaultServerId;
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('SqliteServerRepository', () {
    late MockAppDatabase mockDatabase;
    late SqliteServerRepository repository;

    setUp(() {
      mockDatabase = MockAppDatabase();
      repository = SqliteServerRepository(mockDatabase);
    });

    tearDown(() async {
      await repository.dispose();
    });

    test('should initialize successfully', () async {
      final result = await repository.initialize();
      expect(result, isTrue);
    });

    test('should save and retrieve servers', () async {
      await repository.initialize();
      
      final server = NasServer.create(
        name: 'Test Server',
        host: '192.168.1.100',
        username: 'admin',
        password: 'temp-password',
      );
      
      final saveResult = await repository.saveServer(server);
      expect(saveResult, isTrue);
      expect(mockDatabase.serverCount, equals(1));
      
      final retrievedServer = await repository.getServer(server.id);
      expect(retrievedServer, isNotNull);
      expect(retrievedServer!.name, equals('Test Server'));
    });

    test('should get all servers', () async {
      await repository.initialize();
      
      final server1 = NasServer.create(name: 'Server 1', host: '192.168.1.100', username: 'admin', password: 'temp-password');
      final server2 = NasServer.create(name: 'Server 2', host: '192.168.1.101', username: 'admin', password: 'temp-password');
      
      await repository.saveServer(server1);
      await repository.saveServer(server2);
      
      final servers = await repository.getAllServers();
      expect(servers.length, equals(2));
    });

    test('should delete servers', () async {
      await repository.initialize();
      
      final server = NasServer.create(name: 'Test Server', host: '192.168.1.100', username: 'admin', password: 'temp-password');
      await repository.saveServer(server);
      
      final deleteResult = await repository.deleteServer(server.id);
      expect(deleteResult, isTrue);
      expect(mockDatabase.serverCount, equals(0));
    });

    test('should manage default server', () async {
      await repository.initialize();
      
      final server = NasServer.create(name: 'Default Server', host: '192.168.1.100', username: 'admin', password: 'temp-password');
      await repository.saveServer(server);
      
      final setResult = await repository.setDefaultServer(server.id);
      expect(setResult, isTrue);
      
      final defaultServer = await repository.getDefaultServer();
      expect(defaultServer, isNotNull);
      expect(defaultServer!.isDefault, isTrue);
      
      final clearResult = await repository.clearDefaultServer();
      expect(clearResult, isTrue);
      
      final clearedDefault = await repository.getDefaultServer();
      expect(clearedDefault, isNull);
    });

    test('should report correct capabilities', () async {
      await repository.initialize();
      
      expect(repository.supportsOfflineAccess, isTrue);
      expect(repository.supportsAutoSync, isFalse);
      
      final syncResult = await repository.sync();
      expect(syncResult, isTrue);
    });

    test('should provide servers stream', () async {
      await repository.initialize();
      
      final stream = repository.serversStream;
      expect(stream, isA<Stream<List<NasServer>>>());
    });

    test('should handle errors gracefully', () async {
      await repository.initialize();
      mockDatabase.setShouldThrowErrors(true);
      
      final server = NasServer.create(name: 'Test Server', host: '192.168.1.100', username: 'admin', password: 'temp-password');
      
      final saveResult = await repository.saveServer(server);
      expect(saveResult, isFalse);
      
      final setDefaultResult = await repository.setDefaultServer('test-id');
      expect(setDefaultResult, isFalse);
    });
  });
}