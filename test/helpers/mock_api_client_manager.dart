import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/providers/connection_status_provider.dart';
import 'package:truehub/services/api_client_manager_interface.dart';
import 'package:truehub/services/telemetry_service_interface.dart';

/// Mock implementation of ApiClientManagerInterface for testing
class MockApiClientManager implements ApiClientManagerInterface {
  final Map<String, ApiClientInterface?> _mockClients = {};
  final Map<String, int> _mockRefCounts = {};
  ConnectionStatusProvider? _connectionStatusProvider; // ignore: unused_field
  TelemetryServiceInterface? _telemetry; // ignore: unused_field

  // Test control flags
  bool shouldFailConnection = false;
  bool shouldReturnNull = false;
  int connectionDelay = 0;

  // Track method calls for verification
  final List<String> methodCalls = [];

  @override
  void setConnectionStatusProvider(ConnectionStatusProvider? provider) {
    methodCalls.add('setConnectionStatusProvider');
    _connectionStatusProvider = provider;
  }

  @override
  void setTelemetryService(TelemetryServiceInterface? telemetry) {
    methodCalls.add('setTelemetryService');
    _telemetry = telemetry;
  }

  @override
  Future<ApiClientInterface?> getClient(NasServer server) async {
    methodCalls.add('getClient:${server.id}');

    if (connectionDelay > 0) {
      await Future.delayed(Duration(milliseconds: connectionDelay));
    }

    if (shouldFailConnection) {
      throw Exception('Mock connection failed');
    }

    if (shouldReturnNull) {
      return null;
    }

    // Return existing mock client if available
    if (_mockClients.containsKey(server.id)) {
      _mockRefCounts[server.id] = (_mockRefCounts[server.id] ?? 0) + 1;
      return _mockClients[server.id];
    }

    // For testing, we don't create real clients
    // Instead, return null or a mock client based on test needs
    _mockRefCounts[server.id] = 1;
    return null;
  }

  @override
  Future<void> releaseClient(String serverId) async {
    methodCalls.add('releaseClient:$serverId');

    if (_mockRefCounts.containsKey(serverId)) {
      final newCount = (_mockRefCounts[serverId] ?? 1) - 1;
      if (newCount <= 0) {
        _mockRefCounts.remove(serverId);
        _mockClients.remove(serverId);
      } else {
        _mockRefCounts[serverId] = newCount;
      }
    }
  }

  @override
  Future<void> closeClient(String serverId) async {
    methodCalls.add('closeClient:$serverId');
    _mockClients.remove(serverId);
    _mockRefCounts.remove(serverId);
  }

  @override
  Future<Map<String, Object>> ensureAllConnectionsAlive() async {
    methodCalls.add('ensureAllConnectionsAlive');
    return <String, Object>{};
  }

  @override
  Future<void> closeAllClients() async {
    methodCalls.add('closeAllClients');
    _mockClients.clear();
    _mockRefCounts.clear();
  }

  @override
  ApiClientInterface? getExistingClient(String serverId) {
    methodCalls.add('getExistingClient:$serverId');
    return _mockClients[serverId];
  }

  @override
  bool hasClient(String serverId) {
    methodCalls.add('hasClient:$serverId');
    return _mockClients.containsKey(serverId);
  }

  @override
  int getClientCount() {
    methodCalls.add('getClientCount');
    return _mockClients.length;
  }

  @override
  List<String> getActiveServerIds() {
    methodCalls.add('getActiveServerIds');
    return _mockClients.keys.toList();
  }

  @override
  Map<String, int> getRefCounts() {
    methodCalls.add('getRefCounts');
    return Map.from(_mockRefCounts);
  }

  @override
  Future<ApiClientInterface?> forceRecreateClient(NasServer server) async {
    methodCalls.add('forceRecreateClient:${server.id}');
    await closeClient(server.id);
    return await getClient(server);
  }

  @override
  @visibleForTesting
  Future<void> clearAllForTesting() async {
    methodCalls.add('clearAllForTesting');
    if (kDebugMode) {
      print('MockApiClientManager: Clearing all clients for testing');
    }
    _mockClients.clear();
    _mockRefCounts.clear();
    _connectionStatusProvider = null;
    _telemetry = null;
    methodCalls.clear();
  }

  // Test helper methods
  void addMockClient(String serverId, ApiClientInterface? client) {
    _mockClients[serverId] = client;
    _mockRefCounts[serverId] = 1;
  }

  void reset() {
    _mockClients.clear();
    _mockRefCounts.clear();
    methodCalls.clear();
    shouldFailConnection = false;
    shouldReturnNull = false;
    connectionDelay = 0;
  }

  bool wasMethodCalled(String methodName) {
    return methodCalls.any((call) => call.startsWith(methodName));
  }

  int getMethodCallCount(String methodName) {
    return methodCalls.where((call) => call.startsWith(methodName)).length;
  }
}
