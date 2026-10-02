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
      _log.debug('Already subscribed to realtime stats');
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

      _log.info(
        'Subscribed to realtime stats',
        attributes: {'subscription.id': _realtimeSubscriptionId},
      );

      _isSubscribedToRealtime = true;

      _log.info('Successfully subscribed to system stats stream');
    } catch (e) {
      _log.error('Failed to subscribe to system stats', error: e);
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

        _log.info(
          'Unsubscribed from realtime stats',
          attributes: {'subscription.id': _realtimeSubscriptionId},
        );
      }
    } catch (e) {
      _log.error('Error unsubscribing from system stats', error: e);
    } finally {
      _wantsSystemStats = false;
      _isSubscribedToRealtime = false;
      _realtimeSubscriptionId = null;
      await _systemStatsController?.close();
      _systemStatsController = null;

      _log.info('System stats subscription cleaned up');
    }
  }
}
