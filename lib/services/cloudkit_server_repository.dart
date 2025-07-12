import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/server_config_dto.dart';
import 'package:truehub/services/server_repository_interface.dart';
import 'package:truehub/services/cloudkit_service.dart';

/// CloudKit-based server repository for Apple platforms
/// Provides automatic sync across devices with offline support
class CloudKitServerRepository implements ServerRepositoryInterface {
  final CloudKitService _cloudKit = CloudKitService.instance;
  final StreamController<List<NasServer>> _serversController =
      StreamController<List<NasServer>>.broadcast();

  List<NasServer> _cachedServers = [];
  bool _isInitialized = false;
  StreamSubscription<List<ServerConfigDTO>>? _cloudKitSubscription;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final available = await _cloudKit.initialize();
      if (!available) return false;

      // Subscribe to CloudKit updates
      _cloudKitSubscription = _cloudKit.serverConfigsStream.listen(
        _handleCloudKitUpdates,
        onError: (error) {
          if (kDebugMode) {
            print('CloudKitServerRepository: Stream error: $error');
          }
        },
      );

      // Start monitoring and perform initial sync
      await _cloudKit.startMonitoring();
      await _performInitialSync();

      _isInitialized = true;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('CloudKitServerRepository: Initialization failed: $e');
      }
      return false;
    }
  }

  Future<void> _performInitialSync() async {
    try {
      final configs = await _cloudKit.fetchServerConfigs();
      await _handleCloudKitUpdates(configs);
    } catch (e) {
      if (kDebugMode) {
        print('CloudKitServerRepository: Initial sync failed: $e');
      }
    }
  }

  Future<void> _handleCloudKitUpdates(List<ServerConfigDTO> configs) async {
    _cachedServers = configs.map(_dtoToServer).toList();
    _serversController.add(_cachedServers);

    if (kDebugMode) {
      print(
        'CloudKitServerRepository: Updated ${_cachedServers.length} servers',
      );
    }
  }

  NasServer _dtoToServer(ServerConfigDTO dto) {
    return NasServer(
      id: dto.id,
      name: dto.displayName,
      host: dto.hostName,
      username: dto.userName,
      password: '', // Never stored in CloudKit
      useHttps: dto.useHttps,
      allowUntrustedCertificates: dto.allowUntrustedCertificates,
      port: dto.port,
      localUrl: dto.localUrl,
      trustedWifiSsids: dto.trustedWifiSsids,
      lastConnected: dto.lastConnected,
      isActive: dto.isActive,
      isDefault: dto.isDefault,
    );
  }

  ServerConfigDTO _serverToDto(NasServer server) {
    return ServerConfigDTO.fromServer(server);
  }

  @override
  Future<List<NasServer>> getAllServers() async {
    if (!_isInitialized) await initialize();
    return List.from(_cachedServers);
  }

  @override
  Future<NasServer?> getServer(String id) async {
    if (!_isInitialized) await initialize();
    try {
      return _cachedServers.firstWhere((server) => server.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> saveServer(NasServer server) async {
    if (!_isInitialized) await initialize();

    try {
      final dto = _serverToDto(server);

      // Check if server exists in CloudKit
      final existingIndex = _cachedServers.indexWhere((s) => s.id == server.id);
      final isUpdate = existingIndex != -1;

      bool success;
      if (isUpdate) {
        success = await _cloudKit.updateServerConfig(dto);
      } else {
        success = await _cloudKit.saveServerConfig(dto);
      }

      if (success) {
        // Update local cache immediately for better UX
        if (isUpdate) {
          _cachedServers[existingIndex] = server;
        } else {
          _cachedServers.add(server);
        }
        _serversController.add(List.from(_cachedServers));
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('CloudKitServerRepository: Save failed: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> deleteServer(String id) async {
    if (!_isInitialized) await initialize();

    try {
      final success = await _cloudKit.deleteServerConfig(id);

      if (success) {
        // Update local cache immediately
        _cachedServers.removeWhere((server) => server.id == id);
        _serversController.add(_cachedServers);
      }

      return success;
    } catch (e) {
      if (kDebugMode) {
        print('CloudKitServerRepository: Delete failed: $e');
      }
      return false;
    }
  }

  @override
  Future<NasServer?> getDefaultServer() async {
    final servers = await getAllServers();
    try {
      return servers.firstWhere((server) => server.isDefault);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> setDefaultServer(String id) async {
    try {
      // Clear all default flags
      final updatedServers = <NasServer>[];
      for (final server in _cachedServers) {
        final updated = server.copyWith(isDefault: server.id == id);
        updatedServers.add(updated);
        await saveServer(updated);
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('CloudKitServerRepository: Set default failed: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> clearDefaultServer() async {
    try {
      for (final server in _cachedServers.where((s) => s.isDefault)) {
        final updated = server.copyWith(isDefault: false);
        await saveServer(updated);
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('CloudKitServerRepository: Clear default failed: $e');
      }
      return false;
    }
  }

  @override
  Stream<List<NasServer>> get serversStream => _serversController.stream;

  @override
  bool get supportsOfflineAccess => true; // CloudKit caches data locally

  @override
  bool get supportsAutoSync => true; // CloudKit handles automatic sync

  @override
  Future<bool> sync() async {
    try {
      await _performInitialSync();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    await _cloudKitSubscription?.cancel();
    await _serversController.close();
  }
}
