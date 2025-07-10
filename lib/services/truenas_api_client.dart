import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/models/server_health.dart';
import 'package:truenas_manager/models/file_item.dart';
import 'package:truenas_manager/models/user_info.dart';
import 'package:truenas_manager/models/connection_error.dart';
import 'package:truenas_manager/models/app.dart';
import 'package:truenas_manager/models/system_stats.dart';
import 'package:truenas_manager/services/network_service.dart';
import 'package:truenas_manager/services/api_client_interface.dart';

class TrueNasApiClient implements ApiClientInterface {
  final NasServer _server;
  final NetworkService _networkService = NetworkService();
  Peer? _client;
  WebSocketChannel? _wsChannel;
  bool _isAuthenticated = false;

  // System stats subscription management
  StreamController<SystemStats>? _systemStatsController;
  String? _realtimeSubscriptionId;
  bool _isSubscribedToRealtime = false;

  TrueNasApiClient(this._server);

  Future<void> _ensureConnected() async {
    if (_client != null && !_client!.isClosed) {
      return;
    }

    try {
      // Determine the appropriate URL based on network context
      final isOnTrustedNetwork = await _networkService.isOnTrustedNetwork(
        _server.trustedWifiSsids,
      );
      final baseUrl = _server.getUrlForNetwork(
        isOnTrustedNetwork: isOnTrustedNetwork,
      );

      final wsUrl = '${baseUrl.replaceFirst('http', 'ws')}/api/current';
      if (kDebugMode) {
        print('TrueNAS API: Connecting to WebSocket: $wsUrl');
        print(
          'TrueNAS API: Using ${isOnTrustedNetwork ? 'local' : 'remote'} URL',
        );
      }

      // Connect with timeout to detect network issues early
      _wsChannel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
        protocols: ['json-rpc'],
      );

      _client = Peer(_wsChannel!.cast<String>());

      // Register method to handle collection_update notifications from server
      _setupCollectionUpdateHandler();

      // Start listening for responses with error handling
      _client!.listen().catchError((error) {
        if (kDebugMode) {
          print('TrueNAS API: WebSocket error: $error');
        }
        throw _handleConnectionError(error);
      });

      _isAuthenticated = false;
      if (kDebugMode) {
        print('TrueNAS API: WebSocket connection established and listening');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Connection failed: $e');
      }
      throw _handleConnectionError(e);
    }
  }

  void _setupCollectionUpdateHandler() {
    if (_client == null) return;

    // Register method to handle collection_update notifications from TrueNAS
    _client!.registerMethod('collection_update', (parameters) {
      try {
        final collection = parameters['collection'].value as String?;
        if (collection == 'reporting.realtime') {
          final fields = parameters['fields'].value as Map<String, dynamic>;
          final systemStats = SystemStats.fromJson(fields);
          _systemStatsController?.add(systemStats);

          if (kDebugMode) {
            print(
              'TrueNAS API: Received realtime stats - CPU: ${systemStats.cpu.overall.usage.toStringAsFixed(1)}%',
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('TrueNAS API: Error parsing collection_update: $e');
        }
      }
    });
  }

  Future<void> _ensureAuthenticated() async {
    if (_isAuthenticated) return;

    try {
      await _ensureConnected();
      if (kDebugMode) {
        print(
          'TrueNAS API: Attempting authentication for user: ${_server.username}',
        );
      }

      final result = await _client!
          .sendRequest('auth.login', [_server.username, _server.password])
          .timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        print('TrueNAS API: Authentication result: $result');
      }

      if (result != true) {
        throw ConnectionException(
          ConnectionError.invalidCredentials(
            details: 'Server returned: $result',
          ),
        );
      }

      _isAuthenticated = true;
      if (kDebugMode) {
        print('TrueNAS API: Successfully authenticated');
      }
    } on TimeoutException {
      throw ConnectionException(
        ConnectionError.connectionTimeout(
          details: 'Authentication request timed out after 15 seconds',
        ),
      );
    } catch (e) {
      if (e is ConnectionException) {
        rethrow;
      }
      throw _handleConnectionError(e);
    }
  }

  Future<void> close() async {
    await unsubscribeFromSystemStats();
    await _client?.close();
    await _wsChannel?.sink.close();
  }

  // Authentication methods
  Future<bool> validateLogin(
    String username,
    String password, [
    String? otpToken,
  ]) async {
    try {
      await _ensureConnected();
      if (kDebugMode) {
        print('TrueNAS API: Validating login for user: $username');
      }
      final result = await _client!
          .sendRequest('auth.login', [
            username,
            password,
            if (otpToken != null) otpToken,
          ])
          .timeout(const Duration(seconds: 10));
      if (kDebugMode) {
        print('TrueNAS API: Login validation result: $result');
      }
      return result as bool;
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Login validation failed: $e');
      }
      return false;
    }
  }

  Future<UserInfo> getCurrentUser() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('auth.me');
      return UserInfo.fromJson(result as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // System information methods
  Future<Map<String, dynamic>> getSystemInfo() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('system.info');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getSystemCpuInfo() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('system.cpu_info');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getSystemMemoryInfo() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('system.memory_info');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<double> getSystemTemperature() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('system.temperature');
      return (result as num).toDouble();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Pool management methods
  Future<List<Map<String, dynamic>>> queryPools() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('pool.query');
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPoolById(String id) async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('pool.query', {'id': id});
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Dataset management methods
  Future<List<Map<String, dynamic>>> queryDatasets() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('pool.dataset.query');
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getDatasetById(String id) async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('pool.dataset.query', {
        'id': id,
      });
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // File system methods
  Future<List<Map<String, dynamic>>> listDirectory(String path) async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('filesystem.listdir', {
        'path': path,
      });
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getFileInfo(String path) async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('filesystem.stat', {
        'path': path,
      });
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Disk information methods
  Future<List<Map<String, dynamic>>> queryDisks() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('disk.query');
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getDiskById(String id) async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('disk.query', {'id': id});
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Network information methods
  Future<Map<String, dynamic>> getNetworkInfo() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('network.general.summary');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getNetworkInterfaces() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('interface.query');
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Higher-level methods
  Future<ServerHealth> getServerHealth() async {
    try {
      await getSystemInfo();
      final cpuInfo = await getSystemCpuInfo();
      final memoryInfo = await getSystemMemoryInfo();
      final diskInfo = await queryDisks();
      final temperature = await getSystemTemperature();
      final networkInfo = await getNetworkInfo();

      return ServerHealth(
        serverId: _server.id,
        timestamp: DateTime.now(),
        cpuUsage: _extractCpuUsage(cpuInfo),
        memoryUsage: _extractMemoryUsage(memoryInfo),
        diskUsage: _extractDiskUsage(diskInfo),
        temperature: temperature.toInt(),
        isOnline: true,
        disks: _extractDisks(diskInfo),
        network: _extractNetwork(networkInfo),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<FileItem>> getDirectoryListing(String path) async {
    try {
      final response = await listDirectory(path);
      return response.map((item) => FileItem.fromJson(item)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getPools() async {
    try {
      return await queryPools();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getDatasets() async {
    try {
      return await queryDatasets();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> testConnection() async {
    try {
      await getSystemInfo().timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      return false;
    }
  }

  // App management methods
  Future<List<App>> getAvailableApps() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('app.available');
      return (result as List<dynamic>)
          .map((app) => App.fromJson(app as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<String>> getAppCategories() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('app.categories');
      return (result as List<dynamic>).cast<String>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getDockerStatus() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('docker.status');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // System stats subscription methods
  Stream<SystemStats> get systemStatsStream {
    _systemStatsController ??= StreamController<SystemStats>.broadcast();
    return _systemStatsController!.stream;
  }

  Future<void> subscribeToSystemStats() async {
    if (_isSubscribedToRealtime) {
      if (kDebugMode) {
        print('TrueNAS API: Already subscribed to realtime stats');
      }
      return;
    }

    try {
      await _ensureAuthenticated();

      _systemStatsController ??= StreamController<SystemStats>.broadcast();

      // Subscribe to realtime reporting data
      _realtimeSubscriptionId =
          await _client!.sendRequest('core.subscribe', ['reporting.realtime'])
              as String;

      if (kDebugMode) {
        print(
          'TrueNAS API: Subscribed to realtime stats with ID: $_realtimeSubscriptionId',
        );
      }

      _isSubscribedToRealtime = true;

      if (kDebugMode) {
        print('TrueNAS API: Successfully subscribed to system stats stream');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Failed to subscribe to system stats: $e');
      }
      throw _handleError(e);
    }
  }

  Future<void> unsubscribeFromSystemStats() async {
    if (!_isSubscribedToRealtime || _realtimeSubscriptionId == null) {
      return;
    }

    try {
      if (_client != null && !_client!.isClosed) {
        await _client!.sendRequest('core.unsubscribe', [
          _realtimeSubscriptionId!,
        ]);

        if (kDebugMode) {
          print(
            'TrueNAS API: Unsubscribed from realtime stats with ID: $_realtimeSubscriptionId',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Error unsubscribing from system stats: $e');
      }
    } finally {
      _isSubscribedToRealtime = false;
      _realtimeSubscriptionId = null;
      await _systemStatsController?.close();
      _systemStatsController = null;

      if (kDebugMode) {
        print('TrueNAS API: System stats subscription cleaned up');
      }
    }
  }

  // System information methods (additional)
  Future<Map<String, dynamic>> getSystemGeneralConfig() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('system.general.config');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getSystemAdvancedConfig() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('system.advanced.config');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> getSystemProductType() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('system.product_type');
      return result as String;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> isIxHardware() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('truenas.is_ix_hardware');
      return result as bool;
    } catch (e) {
      throw _handleError(e);
    }
  }

  double _extractCpuUsage(Map<String, dynamic> cpuInfo) {
    return (cpuInfo['usage'] as num?)?.toDouble() ?? 0.0;
  }

  double _extractMemoryUsage(Map<String, dynamic> memoryInfo) {
    final used = (memoryInfo['used'] as num?)?.toDouble() ?? 0.0;
    final total = (memoryInfo['total'] as num?)?.toDouble() ?? 1.0;
    return total > 0 ? (used / total) * 100 : 0.0;
  }

  double _extractDiskUsage(List<Map<String, dynamic>> diskInfo) {
    if (diskInfo.isEmpty) return 0.0;

    double totalUsed = 0.0;
    double totalSize = 0.0;

    for (final disk in diskInfo) {
      totalUsed += (disk['used'] as num?)?.toDouble() ?? 0.0;
      totalSize += (disk['size'] as num?)?.toDouble() ?? 0.0;
    }

    return totalSize > 0 ? (totalUsed / totalSize) * 100 : 0.0;
  }

  List<DiskInfo> _extractDisks(List<Map<String, dynamic>> diskInfo) {
    return diskInfo
        .map(
          (disk) => DiskInfo(
            name: disk['name'] as String? ?? 'Unknown',
            model: disk['model'] as String? ?? 'Unknown',
            serial: disk['serial'] as String? ?? 'Unknown',
            size: (disk['size'] as num?)?.toInt() ?? 0,
            used: (disk['used'] as num?)?.toInt() ?? 0,
            temperature: (disk['temperature'] as num?)?.toInt() ?? 0,
            health: disk['health'] as String? ?? 'Unknown',
          ),
        )
        .toList();
  }

  NetworkInfo _extractNetwork(Map<String, dynamic> networkInfo) {
    return NetworkInfo(
      downloadSpeed: (networkInfo['download_speed'] as num?)?.toInt() ?? 0,
      uploadSpeed: (networkInfo['upload_speed'] as num?)?.toInt() ?? 0,
      totalDownload: (networkInfo['total_download'] as num?)?.toInt() ?? 0,
      totalUpload: (networkInfo['total_upload'] as num?)?.toInt() ?? 0,
    );
  }

  ConnectionException _handleConnectionError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network connectivity issues
    if (error is SocketException ||
        errorString.contains('network is unreachable') ||
        errorString.contains('no route to host') ||
        errorString.contains('connection refused')) {
      return ConnectionException(
        ConnectionError.networkUnreachable(details: error.toString()),
      );
    }

    // Timeout issues
    if (error is TimeoutException ||
        errorString.contains('timeout') ||
        errorString.contains('timed out') ||
        errorString.contains('client closed with pending request')) {
      return ConnectionException(
        ConnectionError.connectionTimeout(details: error.toString()),
      );
    }

    // Authentication issues
    if (error is RpcException) {
      if (error.code == 401 ||
          errorString.contains('unauthorized') ||
          errorString.contains('authentication failed') ||
          errorString.contains('invalid credentials')) {
        return ConnectionException(
          ConnectionError.invalidCredentials(details: error.message),
        );
      }

      if (error.code == 403 || errorString.contains('forbidden')) {
        return ConnectionException(
          ConnectionError.permissionDenied(details: error.message),
        );
      }

      if (error.code >= 500) {
        return ConnectionException(
          ConnectionError.serverError(details: error.message),
        );
      }
    }

    // WebSocket specific errors
    if (errorString.contains('websocket') ||
        errorString.contains('handshake') ||
        errorString.contains('upgrade failed')) {
      return ConnectionException(
        ConnectionError.networkUnreachable(
          details: 'WebSocket connection failed: ${error.toString()}',
        ),
      );
    }

    // Default to unknown error
    return ConnectionException(
      ConnectionError.unknown(details: error.toString()),
    );
  }

  Exception _handleError(dynamic error) {
    // For backward compatibility, convert ConnectionException to regular Exception
    if (error is ConnectionException) {
      return Exception(error.error.message);
    }

    final connectionError = _handleConnectionError(error);
    return Exception(connectionError.error.message);
  }
}
