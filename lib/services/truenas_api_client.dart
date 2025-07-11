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
import 'package:truenas_manager/providers/connection_status_provider.dart';

class TrueNasApiClient implements ApiClientInterface {
  final NasServer _server;
  final NetworkService _networkService = NetworkService();
  final ConnectionStatusProvider? _connectionStatusProvider;
  Peer? _client;
  WebSocketChannel? _wsChannel;
  bool _isAuthenticated = false;
  String? _currentConnectionUrl;
  bool? _isLocalConnection;

  // System stats subscription management
  StreamController<SystemStats>? _systemStatsController;
  String? _realtimeSubscriptionId;
  bool _isSubscribedToRealtime = false;

  // App stats subscription management
  StreamController<Map<String, AppResourceUsage>>? _appStatsController;
  String? _appStatsSubscriptionId;
  bool _isSubscribedToAppStats = false;

  // Keepalive mechanism
  Timer? _keepaliveTimer;
  bool _keepaliveEnabled = true;
  Duration _keepaliveInterval = const Duration(seconds: 30);
  bool _awaitingPong = false;

  TrueNasApiClient(this._server, [this._connectionStatusProvider]);

  Future<void> _ensureConnected() async {
    if (_client != null && !_client!.isClosed) {
      return;
    }

    _connectionStatusProvider?.updateConnectionState(
      _server.id,
      TrueNASConnectionState.connecting,
    );

    try {
      // Determine the appropriate URL based on network context
      final isOnTrustedNetwork = await _networkService.isOnTrustedNetwork(
        _server.trustedWifiSsids,
      );
      final baseUrl = _server.getUrlForNetwork(
        isOnTrustedNetwork: isOnTrustedNetwork,
      );

      final wsUrl = '${baseUrl.replaceFirst('http', 'ws')}/api/current';
      _currentConnectionUrl = baseUrl;
      _isLocalConnection = isOnTrustedNetwork;

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
      _connectionStatusProvider?.updateConnectionState(
        _server.id,
        TrueNASConnectionState.error,
        error: e.toString(),
      );
      throw _handleConnectionError(e);
    }
  }

  void _startKeepalive() {
    if (!_keepaliveEnabled || _keepaliveTimer != null) {
      return;
    }

    if (kDebugMode) {
      print(
        'TrueNAS API: Starting keepalive with ${_keepaliveInterval.inSeconds}s interval',
      );
    }

    _keepaliveTimer = Timer.periodic(_keepaliveInterval, (_) {
      _sendKeepalivePing();
    });
  }

  void _stopKeepalive() {
    _keepaliveTimer?.cancel();
    _keepaliveTimer = null;
    _awaitingPong = false;

    if (kDebugMode) {
      print('TrueNAS API: Stopped keepalive');
    }
  }

  Future<void> _sendKeepalivePing() async {
    if (_client == null || _client!.isClosed || !_isAuthenticated) {
      return;
    }

    if (_awaitingPong) {
      if (kDebugMode) {
        print(
          'TrueNAS API: Keepalive timeout - no pong received, reconnecting...',
        );
      }
      await _handleKeepaliveTimeout();
      return;
    }

    try {
      _awaitingPong = true;
      final pingTime = DateTime.now();

      if (kDebugMode) {
        print('TrueNAS API: Sending keepalive ping');
      }

      _connectionStatusProvider?.updatePingStatus(
        _server.id,
        pingSent: pingTime,
      );

      final result = await _client!
          .sendRequest('core.ping', [])
          .timeout(const Duration(seconds: 10));

      if (result == 'pong') {
        final pongTime = DateTime.now();
        final latency = pongTime.difference(pingTime);
        _awaitingPong = false;

        _connectionStatusProvider?.updatePingStatus(
          _server.id,
          pongReceived: pongTime,
          latency: latency,
        );

        if (kDebugMode) {
          print(
            'TrueNAS API: Received keepalive pong (${latency.inMilliseconds}ms)',
          );
        }
      } else {
        if (kDebugMode) {
          print('TrueNAS API: Unexpected keepalive response: $result');
        }
        _awaitingPong = false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Keepalive ping failed: $e');
      }
      await _handleKeepaliveTimeout();
    }
  }

  Future<void> _handleKeepaliveTimeout() async {
    _awaitingPong = false;

    if (kDebugMode) {
      print('TrueNAS API: Keepalive failed, attempting reconnection');
    }

    _connectionStatusProvider?.updateConnectionState(
      _server.id,
      TrueNASConnectionState.reconnecting,
    );

    // Reset connection state
    _isAuthenticated = false;

    try {
      // Close existing connection
      await _client?.close();
      await _wsChannel?.sink.close();

      // Re-establish connection
      await _ensureConnected();
      await _ensureAuthenticated();

      if (kDebugMode) {
        print('TrueNAS API: Successfully reconnected after keepalive timeout');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Failed to reconnect after keepalive timeout: $e');
      }
      _connectionStatusProvider?.updateConnectionState(
        _server.id,
        TrueNASConnectionState.error,
        error: e.toString(),
      );
      // Stop keepalive on repeated failures to avoid continuous retry loops
      _stopKeepalive();
    }
  }

  @override
  void setKeepaliveInterval(Duration interval) {
    _keepaliveInterval = interval;

    if (_keepaliveTimer != null) {
      _stopKeepalive();
      _startKeepalive();
    }
  }

  @override
  void enableKeepalive(bool enabled) {
    _keepaliveEnabled = enabled;

    if (enabled && _isAuthenticated) {
      _startKeepalive();
    } else {
      _stopKeepalive();
    }
  }

  @override
  bool get isKeepaliveActive => _keepaliveTimer?.isActive ?? false;

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
        } else if (collection == 'app.stats') {
          final fields = parameters['fields'].value as List<dynamic>;
          final appStatsMap = <String, AppResourceUsage>{};

          for (final appData in fields) {
            final appStats = appData as Map<String, dynamic>;
            final appName = appStats['app_name'] as String;

            // Extract network statistics
            final networks = appStats['networks'] as List<dynamic>? ?? [];
            var totalRxBytes = 0.0;
            var totalTxBytes = 0.0;

            for (final network in networks) {
              final networkData = network as Map<String, dynamic>;
              totalRxBytes +=
                  (networkData['rx_bytes'] as num?)?.toDouble() ?? 0.0;
              totalTxBytes +=
                  (networkData['tx_bytes'] as num?)?.toDouble() ?? 0.0;
            }

            final resourceUsage = AppResourceUsage(
              cpuUsage: (appStats['cpu_usage'] as num?)?.toDouble() ?? 0.0,
              memoryUsage: (appStats['memory'] as num?)?.toInt() ?? 0,
              memoryLimit: 0, // Not available in real-time stats
              networkRxBytes: totalRxBytes,
              networkTxBytes: totalTxBytes,
              lastUpdated: DateTime.now(),
            );

            appStatsMap[appName] = resourceUsage;
          }

          _appStatsController?.add(appStatsMap);

          if (kDebugMode) {
            print(
              'TrueNAS API: Received app stats for ${appStatsMap.length} apps',
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

      // Update connection status to connected
      _connectionStatusProvider?.updateConnectionState(
        _server.id,
        TrueNASConnectionState.connected,
        connectionUrl: _currentConnectionUrl,
        isLocalConnection: _isLocalConnection,
      );

      // Start keepalive after successful authentication
      _startKeepalive();

      // Send immediate ping to get initial connection status
      _sendKeepalivePing();
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

  @override
  Future<void> close() async {
    _stopKeepalive();
    _connectionStatusProvider?.updateConnectionState(
      _server.id,
      TrueNASConnectionState.disconnected,
    );
    await unsubscribeFromSystemStats();
    await unsubscribeFromAppStats();
    await _client?.close();
    await _wsChannel?.sink.close();
  }

  // Authentication methods
  @override
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

  @override
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
  @override
  Future<Map<String, dynamic>> getSystemInfo() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('system.info');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getSystemCpuInfo() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('system.cpu_info');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getSystemMemoryInfo() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('system.memory_info');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
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
  @override
  Future<List<Map<String, dynamic>>> queryPools() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('pool.query');
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
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
  @override
  Future<List<Map<String, dynamic>>> queryDatasets() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('pool.dataset.query');
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
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
  @override
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

  @override
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
  @override
  Future<List<Map<String, dynamic>>> queryDisks() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('disk.query');
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
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
  @override
  Future<Map<String, dynamic>> getNetworkInfo() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('network.general.summary');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
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
  @override
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

  @override
  Future<List<FileItem>> getDirectoryListing(String path) async {
    try {
      final response = await listDirectory(path);
      return response.map((item) => FileItem.fromJson(item)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPools() async {
    try {
      return await queryPools();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getDatasets() async {
    try {
      return await queryDatasets();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      await getSystemInfo().timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      return false;
    }
  }

  // App management methods
  @override
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

  @override
  Future<List<App>> getInstalledApps() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('app.query');
      return (result as List<dynamic>)
          .map((app) => _convertTrueNasAppToApp(app as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Convert TrueNAS app query response to our App model
  App _convertTrueNasAppToApp(Map<String, dynamic> trueNasApp) {
    // Extract upgrade info from the response
    final upgradeInfo = AppUpgradeInfo(
      upgradeAvailable: trueNasApp['upgrade_available'] as bool? ?? false,
      availableVersion: trueNasApp['latest_version'] as String?,
      currentVersion: trueNasApp['version'] as String?,
      upgradeNotes: null, // Not available in TrueNAS response
      canUpgrade:
          (trueNasApp['upgrade_available'] as bool? ?? false) &&
          (trueNasApp['state'] as String?) == 'RUNNING',
    );

    // Extract resource usage from limits (not real-time usage)
    AppResourceUsage? resourceUsage;
    final resources = trueNasApp['resources'] as Map<String, dynamic>?;
    if (resources != null) {
      final limits = resources['limits'] as Map<String, dynamic>?;
      if (limits != null) {
        resourceUsage = AppResourceUsage(
          cpuUsage: 0.0, // Not available in real-time
          memoryUsage: 0, // Not available in real-time
          memoryLimit: (limits['memory'] as num?)?.toInt() ?? 0,
          networkRxBytes: 0.0, // Not available
          networkTxBytes: 0.0, // Not available
          lastUpdated: DateTime.now(),
        );
      }
    }

    // Extract port information from active_workloads
    final activeWorkloads =
        trueNasApp['active_workloads'] as Map<String, dynamic>?;
    final usedPorts = <AppPortInfo>[];
    if (activeWorkloads != null) {
      final usedPortsData =
          activeWorkloads['used_ports'] as List<dynamic>? ?? [];
      for (final portData in usedPortsData) {
        usedPorts.add(AppPortInfo.fromJson(portData as Map<String, dynamic>));
      }
    }

    // Extract portal information
    final portals =
        (trueNasApp['portals'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, value.toString()),
        ) ??
        <String, String>{};

    // Extract metadata for app information
    final metadata = trueNasApp['metadata'] as Map<String, dynamic>?;

    // Extract commonly used values
    final appName = trueNasApp['name'] as String? ?? '';
    final appState = trueNasApp['state'] as String?;
    final isHealthy = appState == 'RUNNING';
    final healthError = !isHealthy
        ? 'App is ${appState?.toLowerCase() ?? 'stopped'}'
        : null;

    return App(
      name: appName,
      title: metadata?['title'] as String? ?? appName,
      description: metadata?['description'] as String? ?? '',
      installed: true, // These are installed apps
      healthy: isHealthy,
      healthyError: healthError,
      latestVersion: trueNasApp['latest_version'] as String? ?? '',
      latestAppVersion: metadata?['app_version'] as String? ?? '',
      latestHumanVersion: trueNasApp['human_version'] as String? ?? '',
      iconUrl: metadata?['icon'] as String?,
      categories:
          (metadata?['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      home: metadata?['home'] as String?,
      tags:
          (metadata?['keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      screenshots:
          (metadata?['screenshots'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      sources:
          (metadata?['sources'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      appReadme: null, // Not available in this response
      maintainers:
          (metadata?['maintainers'] as List<dynamic>?)
              ?.map((e) => AppMaintainer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdate: null, // Not available in this response format
      recommended: false, // Not available in this response
      catalog: 'community', // Default, not available in this response
      train: metadata?['train'] as String? ?? 'community',
      resourceUsage: resourceUsage,
      upgradeInfo: upgradeInfo,
      usedPorts: usedPorts,
      portals: portals,
    );
  }

  @override
  Future<List<String>> getAppCategories() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('app.categories');
      return (result as List<dynamic>).cast<String>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getDockerStatus() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('docker.status');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getAppResourceUsage(String appName) async {
    // This method is not available in TrueNAS API
    // Resource usage is extracted from app.query response instead
    return {
      'cpu_usage': 0.0,
      'memory_usage': 0,
      'memory_limit': 0,
      'network_rx_bytes': 0.0,
      'network_tx_bytes': 0.0,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<Map<String, dynamic>> getAppUpgradeInfo(String appName) async {
    // This method is not available in TrueNAS API
    // Upgrade info is extracted from app.query response instead
    return {
      'upgrade_available': false,
      'available_version': null,
      'current_version': null,
      'upgrade_notes': null,
      'can_upgrade': false,
    };
  }

  @override
  Future<bool> upgradeApp(String appName, {String? version}) async {
    try {
      await _ensureAuthenticated();
      // The TrueNAS API takes just the app name as a string parameter
      final result = await _client!.sendRequest('app.upgrade', [appName]);
      // The upgrade method returns the app object on success, so we check if it's not null
      return result != null;
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Failed to upgrade app $appName: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> startApp(String appName) async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('app.start', [appName]);
      return result != null;
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Failed to start app $appName: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> stopApp(String appName) async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('app.stop', [appName]);
      return result != null;
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Failed to stop app $appName: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> restartApp(String appName) async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('app.restart', [appName]);
      return result != null;
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Failed to restart app $appName: $e');
      }
      return false;
    }
  }

  // System stats subscription methods
  @override
  Stream<SystemStats> get systemStatsStream {
    _systemStatsController ??= StreamController<SystemStats>.broadcast();
    return _systemStatsController!.stream;
  }

  @override
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

  @override
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

  // App stats subscription methods
  @override
  Stream<Map<String, AppResourceUsage>> get appStatsStream {
    _appStatsController ??=
        StreamController<Map<String, AppResourceUsage>>.broadcast();
    return _appStatsController!.stream;
  }

  @override
  Future<void> subscribeToAppStats() async {
    if (_isSubscribedToAppStats) {
      if (kDebugMode) {
        print('TrueNAS API: Already subscribed to app stats');
      }
      return;
    }

    try {
      await _ensureAuthenticated();

      _appStatsController ??=
          StreamController<Map<String, AppResourceUsage>>.broadcast();

      // Subscribe to app stats data
      _appStatsSubscriptionId =
          await _client!.sendRequest('core.subscribe', ['app.stats']) as String;

      if (kDebugMode) {
        print(
          'TrueNAS API: Subscribed to app stats with ID: $_appStatsSubscriptionId',
        );
      }

      _isSubscribedToAppStats = true;

      if (kDebugMode) {
        print('TrueNAS API: Successfully subscribed to app stats stream');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Failed to subscribe to app stats: $e');
      }
      throw _handleError(e);
    }
  }

  @override
  Future<void> unsubscribeFromAppStats() async {
    if (!_isSubscribedToAppStats || _appStatsSubscriptionId == null) {
      return;
    }

    try {
      if (_client != null && !_client!.isClosed) {
        await _client!.sendRequest('core.unsubscribe', [
          _appStatsSubscriptionId!,
        ]);

        if (kDebugMode) {
          print(
            'TrueNAS API: Unsubscribed from app stats with ID: $_appStatsSubscriptionId',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Error unsubscribing from app stats: $e');
      }
    } finally {
      _isSubscribedToAppStats = false;
      _appStatsSubscriptionId = null;
      await _appStatsController?.close();
      _appStatsController = null;

      if (kDebugMode) {
        print('TrueNAS API: App stats subscription cleaned up');
      }
    }
  }

  // System information methods (additional)
  @override
  Future<Map<String, dynamic>> getSystemGeneralConfig() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('system.general.config');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getSystemAdvancedConfig() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('system.advanced.config');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<String> getSystemProductType() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('system.product_type');
      return result as String;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
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
