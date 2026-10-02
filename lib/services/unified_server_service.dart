import 'dart:async';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/server_repository_interface.dart';
import 'package:truenas_native_plugins/truenas_native_plugins.dart'
    show KeychainServiceInterface;
import 'package:truehub/services/server_credentials_lookup.dart';
import 'package:truehub/services/server_lookup.dart';
import 'package:truehub/services/app_logger.dart';

final _log = appLogger('services.unified_server');

/// Unified server service that combines server metadata management with secure credential storage
/// Uses platform-appropriate repository (CloudKit on Apple, SQLite elsewhere) + Keychain for passwords
class UnifiedServerService
    implements ServerLookup, ServerCredentialsLookup, ServerCredentialsSource {
  final ServerRepositoryInterface _repository;
  final KeychainServiceInterface _keychain;
  final StreamController<List<NasServer>> _serversController =
      StreamController<List<NasServer>>.broadcast();

  bool _isInitialized = false;
  StreamSubscription<List<NasServer>>? _repositorySubscription;

  UnifiedServerService({
    required ServerRepositoryInterface repository,
    required KeychainServiceInterface keychain,
  }) : _repository = repository,
       _keychain = keychain;

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
          _log.error('Repository stream error', error: error);
        },
      );

      _isInitialized = true;

      _log.info(
        'Initialized',
        attributes: {
          'repository': '${_repository.runtimeType}',
          'offline_access': _repository.supportsOfflineAccess,
          'auto_sync': _repository.supportsAutoSync,
        },
      );

      return true;
    } catch (e) {
      _log.error('Initialization failed', error: e);
      return false;
    }
  }

  /// Get all servers
  Future<List<NasServer>> getAllServers() async {
    await _ensureInitialized();
    return await _repository.getAllServers();
  }

  /// Get a single server
  @override
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
        _log.warn(
          'Failed to store password',
          attributes: {'server.id': server.id},
        );
        // Note: We don't rollback the metadata save since password can be added later
      }

      return metadataSuccess;
    } catch (e) {
      _log.error('Save failed', error: e);
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
        _log.warn(
          'Failed to delete password',
          attributes: {'server.id': serverId},
        );
      }

      return metadataSuccess;
    } catch (e) {
      _log.error('Delete failed', error: e);
      return false;
    }
  }

  @override
  Future<String?> getPassword(String serverId) async {
    return await _keychain.getPassword(serverId: serverId);
  }

  /// Get server with credentials loaded
  @override
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
  @override
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
  }
}
