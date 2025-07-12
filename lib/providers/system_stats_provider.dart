import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/system_stats.dart';
import 'package:truehub/services/truenas_api_client.dart';
import 'package:truehub/services/api_client_manager.dart';

class SystemStatsProvider extends ChangeNotifier {
  TrueNasApiClient? _apiClient;
  String? _currentServerId;
  SystemStats? _currentStats;
  String? _error;
  bool _isLoading = false;
  bool _isSubscribed = false;
  StreamSubscription<SystemStats>? _statsSubscription;

  SystemStats? get currentStats => _currentStats;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isSubscribed => _isSubscribed;
  bool get hasData => _currentStats != null;

  Future<void> setApiClient(NasServer server) async {
    if (_apiClient != null) {
      await unsubscribeFromStats();
    }

    // Release previous client if any
    if (_currentServerId != null) {
      await ApiClientManager.releaseClient(_currentServerId!);
    }

    _currentServerId = server.id;

    try {
      _apiClient = await ApiClientManager.getClient(server);
    } catch (e) {
      if (kDebugMode) {
        print('SystemStatsProvider: Failed to get API client: $e');
      }
    }
  }

  Future<void> subscribeToStats() async {
    if (_apiClient == null) {
      _setError('No API client configured');
      return;
    }

    if (_isSubscribed) {
      if (kDebugMode) {
        print('SystemStatsProvider: Already subscribed to stats');
      }
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      // Subscribe to the real-time system stats stream
      await _apiClient!.subscribeToSystemStats();

      // Listen to the stream and update our state
      _statsSubscription = _apiClient!.systemStatsStream.listen(
        _onStatsReceived,
        onError: _onStatsError,
        onDone: _onStatsStreamDone,
      );

      _isSubscribed = true;
      if (kDebugMode) {
        print('SystemStatsProvider: Successfully subscribed to stats stream');
      }
    } catch (e) {
      _setError('Failed to subscribe to system stats: ${e.toString()}');
      if (kDebugMode) {
        print('SystemStatsProvider: Subscription error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> unsubscribeFromStats() async {
    if (!_isSubscribed) {
      return;
    }

    try {
      if (kDebugMode) {
        print('SystemStatsProvider: Unsubscribing from stats stream');
      }

      // Cancel the stream subscription
      await _statsSubscription?.cancel();
      _statsSubscription = null;

      // Unsubscribe from the API client
      if (_apiClient != null) {
        await _apiClient!.unsubscribeFromSystemStats();
      }

      _isSubscribed = false;
      _currentStats = null;
      _clearError();

      if (kDebugMode) {
        print('SystemStatsProvider: Successfully unsubscribed from stats');
      }
    } catch (e) {
      if (kDebugMode) {
        print('SystemStatsProvider: Error during unsubscription: $e');
      }
    }

    notifyListeners();
  }

  Future<void> refreshStats() async {
    if (_isSubscribed) {
      // If already subscribed, the data will come automatically
      // Just clear any existing error state
      _clearError();
      notifyListeners();
    } else {
      // If not subscribed, start subscription
      await subscribeToStats();
    }
  }

  void _onStatsReceived(SystemStats stats) {
    _currentStats = stats;
    _clearError();
    _setLoading(false);
    notifyListeners();

    if (kDebugMode) {
      print(
        'SystemStatsProvider: Received stats - CPU: ${stats.cpu.overall.usage.toStringAsFixed(1)}%, '
        'Memory: ${stats.memory.physicalMemoryUsagePercent.toStringAsFixed(1)}%',
      );
    }
  }

  void _onStatsError(dynamic error) {
    _setError('System stats stream error: ${error.toString()}');
    _setLoading(false);
    if (kDebugMode) {
      print('SystemStatsProvider: Stream error: $error');
    }
  }

  void _onStatsStreamDone() {
    _isSubscribed = false;
    _setLoading(false);
    if (kDebugMode) {
      print('SystemStatsProvider: Stats stream done');
    }
    notifyListeners();
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    _setLoading(false);
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  // Convenience getters for common stats
  double get cpuUsage => _currentStats?.cpu.overall.usage ?? 0.0;
  double get memoryUsage =>
      _currentStats?.memory.physicalMemoryUsagePercent ?? 0.0;
  double get arcUsage => _currentStats?.memory.arcUsagePercent ?? 0.0;

  int get physicalMemoryTotal => _currentStats?.memory.physicalMemoryTotal ?? 0;
  int get physicalMemoryAvailable =>
      _currentStats?.memory.physicalMemoryAvailable ?? 0;
  int get arcSize => _currentStats?.memory.arcSize ?? 0;

  double get diskReadOps => _currentStats?.disks.readOps ?? 0.0;
  double get diskWriteOps => _currentStats?.disks.writeOps ?? 0.0;
  double get diskBusyPercent => _currentStats?.disks.busy ?? 0.0;

  Map<String, NetworkInterfaceStats> get networkInterfaces =>
      _currentStats?.interfaces ?? {};

  List<MapEntry<String, CpuCore>> get cpuCores {
    if (_currentStats == null) return [];
    return _currentStats!.cpu.cores.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  // Helper method to format bytes
  String formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    if (bytes < 1024 * 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
    return '${(bytes / (1024 * 1024 * 1024 * 1024)).toStringAsFixed(1)}TB';
  }

  // Helper method to format rates
  String formatRate(double bytesPerSecond) {
    return '${formatBytes(bytesPerSecond.round())}/s';
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print('SystemStatsProvider: Disposing');
    }
    // Note: We can't await in dispose, so we do a fire-and-forget cleanup
    unsubscribeFromStats();

    if (_currentServerId != null) {
      ApiClientManager.releaseClient(_currentServerId!);
    }
    super.dispose();
  }
}
