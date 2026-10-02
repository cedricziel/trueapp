part of '../truenas_api_client.dart';

mixin _SystemStatsOps on _ClientTransport implements SystemStatsApi {
  @override
  Stream<SystemStats> get systemStatsStream {
    _systemStatsController ??= StreamController<SystemStats>.broadcast();
    return _systemStatsController!.stream;
  }

  @override
  Future<void> subscribeToSystemStats() async {
    // A subscription only exists for as long as the socket that created it.
    // After the connection drops - which is what the OS does to a backgrounded
    // app - the flag is stale and re-subscribing is exactly what's needed.
    _wantsSystemStats = true;

    if (_isSubscribedToRealtime && _hasLiveConnection) {
      if (kDebugMode) {
        print('TrueNAS API: Already subscribed to realtime stats');
      }
      return;
    }

    _isSubscribedToRealtime = false;
    _realtimeSubscriptionId = null;

    try {
      await _ensureAuthenticated();

      _systemStatsController ??= StreamController<SystemStats>.broadcast();

      // Subscribe to realtime reporting data
      _realtimeSubscriptionId =
          await _request('core.subscribe', ['reporting.realtime']) as String;

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
      if (_hasLiveConnection) {
        await _request('core.unsubscribe', [_realtimeSubscriptionId!]);

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
      _wantsSystemStats = false;
      _isSubscribedToRealtime = false;
      _realtimeSubscriptionId = null;
      await _systemStatsController?.close();
      _systemStatsController = null;

      if (kDebugMode) {
        print('TrueNAS API: System stats subscription cleaned up');
      }
    }
  }
}
