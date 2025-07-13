import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/services/server_repository_interface.dart';
import 'package:truenas_native_plugins/truenas_native_plugins.dart' show MockKeychainService;
import '../helpers/mock_server_sync_service.dart';

part 'unified_server_service_test_setup.dart';
part 'unified_server_service_test_core.dart';
part 'unified_server_service_test_integration.dart';

/// Comprehensive test suite for UnifiedServerService
///
/// This test suite follows SOLID principles by testing:
/// - Single Responsibility: Each test focuses on one aspect
/// - Open/Closed: Uses interfaces for extensibility
/// - Liskov Substitution: Tests work with any repository implementation
/// - Interface Segregation: Tests specific interfaces separately
/// - Dependency Inversion: Tests depend on abstractions
void main() {
  group('UnifiedServerService', () {
    late MockServerRepository mockRepository;
    late MockKeychainService mockKeychain;
    late UnifiedServerService service;
    late NasServer testServer;

    setUp(() {
      mockRepository = MockServerRepository();
      mockKeychain = MockKeychainService();
      service = UnifiedServerService(
        repository: mockRepository,
        keychain: mockKeychain,
      );

      testServer = NasServer.create(
        name: 'Test Server',
        host: '192.168.1.100',
        username: 'admin',
        password: 'test-password',
      );
    });

    group('Initialization', _testInitialization);
    group('Server Configuration Management', _testServerConfiguration);
    group('Password Management', _testPasswordManagement);
    group('Default Server Management', _testDefaultServerManagement);
    group('Server Retrieval', _testServerRetrieval);
    group('Stream Updates', _testStreamUpdates);
    group('Error Handling', _testErrorHandling);
    group('Integration Scenarios', _testIntegrationScenarios);
  });
}

/// Mock implementation following Interface Segregation Principle
class MockServerRepository implements ServerRepositoryInterface {
  final Map<String, NasServer> _servers = {};
  bool _isInitialized = false;
  bool _shouldFailOperations = false;
  final Stream<List<NasServer>> _emptyStream = Stream.value([]);

  @override
  Future<bool> initialize() async {
    if (_shouldFailOperations) return false;
    _isInitialized = true;
    return true;
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<List<NasServer>> getAllServers() async {
    if (!_isInitialized) throw StateError('Repository not initialized');
    return _servers.values.toList();
  }

  @override
  Future<NasServer?> getServer(String id) async {
    if (!_isInitialized) throw StateError('Repository not initialized');
    return _servers[id];
  }

  @override
  Future<bool> saveServer(NasServer server) async {
    if (!_isInitialized) throw StateError('Repository not initialized');
    if (_shouldFailOperations) return false;
    _servers[server.id] = server;
    return true;
  }

  @override
  Future<bool> deleteServer(String id) async {
    if (!_isInitialized) throw StateError('Repository not initialized');
    if (_shouldFailOperations) return false;
    return _servers.remove(id) != null;
  }

  @override
  Future<NasServer?> getDefaultServer() async {
    final servers = await getAllServers();
    try {
      return servers.firstWhere((s) => s.isDefault);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> setDefaultServer(String id) async {
    if (!_isInitialized) return false;
    if (_shouldFailOperations) return false;

    // Clear all defaults
    final servers = _servers.values.toList();
    for (final server in servers) {
      _servers[server.id] = server.copyWith(isDefault: false);
    }

    // Set new default
    final server = _servers[id];
    if (server != null) {
      _servers[id] = server.copyWith(isDefault: true);
      return true;
    }
    return false;
  }

  @override
  Future<bool> clearDefaultServer() async {
    if (!_isInitialized) return false;
    if (_shouldFailOperations) return false;

    final servers = _servers.values.toList();
    for (final server in servers) {
      if (server.isDefault) {
        _servers[server.id] = server.copyWith(isDefault: false);
      }
    }
    return true;
  }

  @override
  Stream<List<NasServer>> get serversStream => _emptyStream;

  @override
  bool get supportsOfflineAccess => true;

  @override
  bool get supportsAutoSync => false;

  @override
  Future<bool> sync() async => !_shouldFailOperations;

  @override
  Future<void> dispose() async {
    _servers.clear();
    _isInitialized = false;
  }

  // Test helpers
  void setShouldFailOperations(bool shouldFail) {
    _shouldFailOperations = shouldFail;
  }

  void addServer(NasServer server) {
    _servers[server.id] = server;
  }

  int get serverCount => _servers.length;
}

// NOTE: MockKeychainService is now imported from truenas_native_plugins package
// See package imports at the top of the file
