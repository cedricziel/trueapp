part of '../truenas_api_client.dart';

mixin _AppStatsOps on _ClientTransport implements AppStatsApi {
  @override
  Stream<Map<String, AppResourceUsage>> get appStatsStream {
    _appStatsController ??=
        StreamController<Map<String, AppResourceUsage>>.broadcast();
    return _appStatsController!.stream;
  }

  @override
  Future<void> subscribeToAppStats() async {
    _wantsAppStats = true;

    if (_isSubscribedToAppStats && _hasLiveConnection) {
      _log.debug('Already subscribed to app stats');
      return;
    }

    _isSubscribedToAppStats = false;
    _appStatsSubscriptionId = null;

    try {
      await _ensureAuthenticated();

      _appStatsController ??=
          StreamController<Map<String, AppResourceUsage>>.broadcast();

      // Subscribe to app stats data
      _appStatsSubscriptionId =
          await _request('core.subscribe', ['app.stats']) as String;

      _log.info(
        'Subscribed to app stats',
        attributes: {'subscription.id': _appStatsSubscriptionId},
      );

      _isSubscribedToAppStats = true;

      _log.info('Successfully subscribed to app stats stream');
    } catch (e) {
      _log.error('Failed to subscribe to app stats', error: e);
      throw _handleError(e);
    }
  }

  @override
  Future<void> unsubscribeFromAppStats() async {
    if (!_isSubscribedToAppStats || _appStatsSubscriptionId == null) {
      return;
    }

    try {
      if (_hasLiveConnection) {
        await _request('core.unsubscribe', [_appStatsSubscriptionId!]);

        _log.info(
          'Unsubscribed from app stats',
          attributes: {'subscription.id': _appStatsSubscriptionId},
        );
      }
    } catch (e) {
      _log.error('Error unsubscribing from app stats', error: e);
    } finally {
      _wantsAppStats = false;
      _isSubscribedToAppStats = false;
      _appStatsSubscriptionId = null;
      await _appStatsController?.close();
      _appStatsController = null;

      _log.info('App stats subscription cleaned up');
    }
  }
}
