import 'dart:async';

import 'package:truehub/models/app.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/services/app_logger.dart';
import 'package:truehub/services/telemetry_service_interface.dart';

final _log = appLogger('services.app_stats_tracker');

/// Owns the live app-stats subscription and the last known resource usage per
/// app, merging partial updates so a zero reading never erases a good value.
class AppStatsTracker {
  final TelemetryServiceInterface? _telemetry;
  final void Function() _onChanged;
  StreamSubscription<Map<String, AppResourceUsage>>? _subscription;
  final Map<String, AppResourceUsage> _lastKnown = {};
  int _epoch = 0;

  AppStatsTracker({
    required void Function() onChanged,
    TelemetryServiceInterface? telemetryService,
  }) : _onChanged = onChanged,
       _telemetry = telemetryService;

  AppResourceUsage? usageFor(String appName) => _lastKnown[appName];

  Future<void> subscribe(ApiClientInterface client) async {
    final epoch = ++_epoch;
    await _subscription?.cancel();

    try {
      await client.subscribeToAppStats();
      if (epoch != _epoch) return;

      _subscription = client.appStatsStream.listen(
        (appStatsMap) {
          _log.debug('Received app stats for ${appStatsMap.length} apps');
          merge(appStatsMap);
          _onChanged();
        },
        onError: (Object error, StackTrace stackTrace) {
          _log.error('Error in app stats stream', error: error);
          _telemetry?.recordError(
            error,
            stackTrace,
            context: 'AppStatsTracker.subscribe (stream)',
          );
        },
      );
    } catch (e, stackTrace) {
      _log.error('Failed to subscribe to app stats', error: e);
      _telemetry?.recordError(
        e,
        stackTrace,
        context: 'AppStatsTracker.subscribe',
      );
    }
  }

  Future<void> unsubscribe(ApiClientInterface? client) async {
    _epoch++;
    await _subscription?.cancel();
    _subscription = null;

    if (client != null) {
      try {
        await client.unsubscribeFromAppStats();
      } catch (e, stackTrace) {
        _log.error('Failed to unsubscribe from app stats', error: e);
        _telemetry?.recordError(
          e,
          stackTrace,
          context: 'AppStatsTracker.unsubscribe',
        );
      }
    }
  }

  void merge(Map<String, AppResourceUsage> appStatsMap) {
    for (final entry in appStatsMap.entries) {
      final incoming = entry.value;
      final existing = _lastKnown[entry.key];
      _lastKnown[entry.key] = existing == null
          ? incoming
          : AppResourceUsage(
              cpuUsage: incoming.cpuUsage > 0
                  ? incoming.cpuUsage
                  : existing.cpuUsage,
              memoryUsage: incoming.memoryUsage > 0
                  ? incoming.memoryUsage
                  : existing.memoryUsage,
              memoryLimit: incoming.memoryLimit > 0
                  ? incoming.memoryLimit
                  : existing.memoryLimit,
              networkRxBytes: incoming.networkRxBytes > 0
                  ? incoming.networkRxBytes
                  : existing.networkRxBytes,
              networkTxBytes: incoming.networkTxBytes > 0
                  ? incoming.networkTxBytes
                  : existing.networkTxBytes,
              lastUpdated: DateTime.now(),
            );
    }
  }

  void clear() => _lastKnown.clear();
}
