import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/server_repository_interface.dart';
import 'package:truehub/services/server_repository_factory.dart';
import 'package:truehub/services/native_keychain_service.dart';

/// Unified server service that combines server metadata management with secure credential storage
/// Uses platform-appropriate repository (CloudKit on Apple, SQLite elsewhere) + Keychain for passwords
class UnifiedServerService {
  static UnifiedServerService? _instance;

  final ServerRepositoryInterface _repository;
  final dynamic
  _keychain; // Generic to support both production and mock keychains
  final StreamController<List<NasServer>> _serversController =
      StreamController<List<NasServer>>.broadcast();

  bool _isInitialized = false;
  StreamSubscription<List<NasServer>>? _repositorySubscription;

  /// Primary constructor - both production and testing use this
  UnifiedServerService({
    required ServerRepositoryInterface repository,
    required dynamic keychain,
  }) : _repository = repository,
       _keychain = keychain;

  /// Factory for production use with platform-appropriate dependencies
  static Future<UnifiedServerService> createForProduction() async {
    if (_instance != null) return _instance!;

    final repository = await ServerRepositoryFactory.create();
    final keychain = NativeKeychainService.instance;

    _instance = UnifiedServerService(
      repository: repository,
      keychain: keychain,
    );

    final initialized = await _instance!.initialize();
    if (!initialized) {
      throw StateError('Failed to initialize UnifiedServerService');
    }

    return _instance!;
  }

  static UnifiedServerService get instance {
    if (_instance == null) {
      throw StateError(
        'UnifiedServerService not initialized. Call createForProduction() first.',
      );
    }
    return _instance!;
  }

  /// Initialize the service - same method for production and testing
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize the injected repository
      final repositoryInitialized = await _repository.initialize();
      if (!repositoryInitialized) {
        return false;
      }

      // Subscribe to repository changes
      _repositorySubscription = _repository.serversStream.listen(
        (servers) {
          _serversController.add(servers);
        },
        onError: (error) {
          if (kDebugMode) {
            print('UnifiedServerService: Repository stream error: $error');
          }
        },
      );

      _isInitialized = true;

      if (kDebugMode) {
        print(
          'UnifiedServerService: Initialized with ${_repository.runtimeType}',
        );
        print('  - Offline access: ${_repository.supportsOfflineAccess}');
        print('  - Auto sync: ${_repository.supportsAutoSync}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedServerService: Initialization failed: $e');
      }
      return false;
    }
  }

  /// Get all servers
  Future<List<NasServer>> getAllServers() async {
    await _ensureInitialized();
    return await _repository.getAllServers();
  }

  /// Get a single server
  Future<NasServer?> getServer(String id) async {
    await _ensureInitialized();
    return await _repository.getServer(id);
  }

  /// Save server configuration with password
  Future<bool> saveServerConfig({
    required NasServer server,
    required String password,
  }) async {
    await _ensureInitialized();

    try {
      // Save server metadata to repository
      final metadataSuccess = await _repository.saveServer(server);
      if (!metadataSuccess) return false;

      // Save password to keychain
      final passwordSuccess = await _keychain.storePassword(
        serverId: server.id,
        password: password,
      );

      if (!passwordSuccess) {
        if (kDebugMode) {
          print(
            'UnifiedServerService: Failed to store password for ${server.id}',
          );
        }
        // Note: We don't rollback the metadata save since password can be added later
      }

      return metadataSuccess;
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedServerService: Save failed: $e');
      }
      return false;
    }
  }

  /// Update server configuration (metadata only)
  Future<bool> updateServerConfig(NasServer server) async {
    await _ensureInitialized();
    return await _repository.saveServer(server);
  }

  /// Delete server configuration and credentials
  Future<bool> deleteServerConfig(String serverId) async {
    await _ensureInitialized();

    try {
      // Delete from repository
      final metadataSuccess = await _repository.deleteServer(serverId);

      // Delete password from keychain
      final passwordSuccess = await _keychain.deletePassword(
        serverId: serverId,
      );

      if (!passwordSuccess) {
        if (kDebugMode) {
          print(
            'UnifiedServerService: Failed to delete password for $serverId',
          );
        }
      }

      return metadataSuccess;
    } catch (e) {
      if (kDebugMode) {
        print('UnifiedServerService: Delete failed: $e');
      }
      return false;
    }
  }

  /// Get password for a server
  Future<String?> getPassword(String serverId) async {
    return await _keychain.getPassword(serverId: serverId);
  }

  /// Get server with credentials loaded
  Future<(NasServer?, String?)> getServerWithPassword(String serverId) async {
    await _ensureInitialized();

    final server = await _repository.getServer(serverId);
    if (server == null) return (null, null);

    final password = await getPassword(serverId);
    return (server, password);
  }

  /// Get default server
  Future<NasServer?> getDefaultServer() async {
    await _ensureInitialized();
    return await _repository.getDefaultServer();
  }

  /// Set default server
  Future<bool> setDefaultServer(String id) async {
    await _ensureInitialized();
    return await _repository.setDefaultServer(id);
  }

  /// Clear default server
  Future<bool> clearDefaultServer() async {
    await _ensureInitialized();
    return await _repository.clearDefaultServer();
  }

  /// Force sync (if supported by repository)
  Future<bool> sync() async {
    await _ensureInitialized();
    return await _repository.sync();
  }

  /// Stream of server changes
  Stream<List<NasServer>> get serversStream => _serversController.stream;

  /// Repository capabilities
  bool get supportsOfflineAccess => _repository.supportsOfflineAccess;
  bool get supportsAutoSync => _repository.supportsAutoSync;
  bool get isInitialized => _isInitialized;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _repositorySubscription?.cancel();
    await _serversController.close();
    await _repository.dispose();
    _instance = null;
  }
}
