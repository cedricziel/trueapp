import 'dart:async';
import 'package:flutter/foundation.dart';
import '../interfaces/cloudkit_service_interface.dart';
import '../models/server_config_dto.dart';

/// Mock implementation of CloudKitService for testing
class MockCloudKitService implements CloudKitServiceInterface {
  final List<ServerConfigDTO> _mockConfigs = [];
  final StreamController<List<ServerConfigDTO>> _serverConfigsController =
      StreamController<List<ServerConfigDTO>>.broadcast();

  bool _isInitialized = false;
  bool _isAvailable = true;
  bool _shouldFailOperations = false;
  int _operationDelay = 0;
  bool _isMonitoring = false;

  @override
  Stream<List<ServerConfigDTO>> get serverConfigsStream =>
      _serverConfigsController.stream;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<bool> initialize() async {
    if (_operationDelay > 0) {
      await Future.delayed(Duration(milliseconds: _operationDelay));
    }

    if (_shouldFailOperations) return false;

    _isInitialized = true;
    if (kDebugMode) {
      print('MockCloudKitService: Initialized');
    }
    return true;
  }

  @override
  Future<bool> isAvailable() async {
    if (_operationDelay > 0) {
      await Future.delayed(Duration(milliseconds: _operationDelay));
    }

    return _isInitialized && _isAvailable && !_shouldFailOperations;
  }

  @override
  Future<bool> saveServerConfig(ServerConfigDTO config) async {
    if (_operationDelay > 0) {
      await Future.delayed(Duration(milliseconds: _operationDelay));
    }

    if (!_isInitialized || _shouldFailOperations) return false;

    // Remove existing config with same ID
    _mockConfigs.removeWhere((c) => c.id == config.id);
    _mockConfigs.add(config);

    // Emit update event
    _serverConfigsController.add(List.from(_mockConfigs));

    if (kDebugMode) {
      print('MockCloudKitService: Saved config ${config.id}');
    }

    return true;
  }

  @override
  Future<bool> updateServerConfig(ServerConfigDTO config) async {
    if (_operationDelay > 0) {
      await Future.delayed(Duration(milliseconds: _operationDelay));
    }

    if (!_isInitialized || _shouldFailOperations) return false;

    final index = _mockConfigs.indexWhere((c) => c.id == config.id);
    if (index == -1) return false;

    _mockConfigs[index] = config;

    // Emit update event
    _serverConfigsController.add(List.from(_mockConfigs));

    if (kDebugMode) {
      print('MockCloudKitService: Updated config ${config.id}');
    }

    return true;
  }

  @override
  Future<List<ServerConfigDTO>> fetchServerConfigs() async {
    if (_operationDelay > 0) {
      await Future.delayed(Duration(milliseconds: _operationDelay));
    }

    if (!_isInitialized || _shouldFailOperations) return [];

    if (kDebugMode) {
      print('MockCloudKitService: Fetched ${_mockConfigs.length} configs');
    }

    return List.from(_mockConfigs);
  }

  @override
  Future<bool> deleteServerConfig(String serverId) async {
    if (_operationDelay > 0) {
      await Future.delayed(Duration(milliseconds: _operationDelay));
    }

    if (!_isInitialized || _shouldFailOperations) return false;

    final countBefore = _mockConfigs.length;
    _mockConfigs.removeWhere((c) => c.id == serverId);
    final removed = _mockConfigs.length < countBefore;

    if (removed) {
      // Emit update event
      _serverConfigsController.add(List.from(_mockConfigs));

      if (kDebugMode) {
        print('MockCloudKitService: Deleted config $serverId');
      }
    }

    return removed;
  }

  @override
  Future<void> startMonitoring() async {
    if (_operationDelay > 0) {
      await Future.delayed(Duration(milliseconds: _operationDelay));
    }

    _isMonitoring = true;

    if (kDebugMode) {
      print('MockCloudKitService: Started monitoring');
    }
  }

  @override
  Future<void> stopMonitoring() async {
    if (_operationDelay > 0) {
      await Future.delayed(Duration(milliseconds: _operationDelay));
    }

    _isMonitoring = false;

    if (kDebugMode) {
      print('MockCloudKitService: Stopped monitoring');
    }
  }

  @override
  void dispose() {
    _serverConfigsController.close();
    _isInitialized = false;
    _isMonitoring = false;
  }

  // Test helpers
  void setShouldFailOperations(bool shouldFail) {
    _shouldFailOperations = shouldFail;
  }

  void setIsAvailable(bool isAvailable) {
    _isAvailable = isAvailable;
  }

  void setOperationDelay(int milliseconds) {
    _operationDelay = milliseconds;
  }

  void addMockConfig(ServerConfigDTO config) {
    _mockConfigs.add(config);
    if (_isMonitoring) {
      _serverConfigsController.add(List.from(_mockConfigs));
    }
  }

  void clearMockConfigs() {
    _mockConfigs.clear();
    if (_isMonitoring) {
      _serverConfigsController.add([]);
    }
  }

  int get mockConfigCount => _mockConfigs.length;

  bool get isMonitoring => _isMonitoring;

  /// Simulate a remote update event
  void simulateRemoteUpdate(List<ServerConfigDTO> configs) {
    _mockConfigs.clear();
    _mockConfigs.addAll(configs);
    _serverConfigsController.add(List.from(_mockConfigs));
  }

  /// Simulate a sync error
  void simulateSyncError(String error) {
    _serverConfigsController.addError(error);
  }
}
