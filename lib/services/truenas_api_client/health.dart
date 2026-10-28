part of '../truenas_api_client.dart';

mixin _HealthOps on _ClientTransport, _SystemStatsOps implements HealthApi {
  Future<Map<String, dynamic>> _getSystemInfo() async {
    try {
      final result = await _sendRequest('system.info');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// One `reporting.realtime` sample: SCALE has no request/response method
  /// for live CPU, memory or temperature. Reuses a live subscription;
  /// otherwise subscribes for the sample and the last concurrent sampler
  /// closes it again.
  Future<SystemStats> _sampleSystemStats() async {
    final next = systemStatsStream.first.timeout(const Duration(seconds: 10))
      ..ignore();
    _realtimeSamplers++;
    try {
      if (!_isSubscribedToRealtime || !_hasLiveConnection) {
        if (!_wantsSystemStats) _realtimeForSampleOnly = true;
        await _subscribeToRealtime();
      }
      return await next;
    } finally {
      if (--_realtimeSamplers == 0 && _realtimeForSampleOnly) {
        await unsubscribeFromSystemStats();
      }
    }
  }

  Future<List<Map<String, dynamic>>> _queryDisks() async {
    try {
      final result = await _sendRequest('disk.query');
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> _getNetworkInfo() async {
    try {
      final result = await _sendRequest('network.general.summary');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ServerHealth> getServerHealth() async {
    try {
      await _getSystemInfo();
      final diskInfo = await _queryDisks();
      final networkInfo = await _getNetworkInfo();
      final stats = await _sampleSystemStats();

      return ServerHealth(
        serverId: _server.id,
        timestamp: DateTime.now(),
        cpuUsage: stats.cpu.overall.usage,
        memoryUsage: stats.memory.physicalMemoryUsagePercent,
        diskUsage: _extractDiskUsage(diskInfo),
        temperature: stats.cpu.overall.temperature?.round(),
        isOnline: true,
        disks: _extractDisks(diskInfo),
        network: _extractNetwork(networkInfo),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<Alert>> getAlerts() async {
    try {
      await _ensureAuthenticated();
      final result = await _request('alert.list');
      return (result as List<dynamic>)
          .map((json) => Alert.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<ServiceStatus>> getServices() async {
    try {
      await _ensureAuthenticated();
      final result = await _request('service.query');
      return (result as List<dynamic>)
          .map((json) => ServiceStatus.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      await _getSystemInfo().timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      return false;
    }
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
}
