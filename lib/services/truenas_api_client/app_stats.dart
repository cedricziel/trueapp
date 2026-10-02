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
          await _request('core.subscribe', ['app.stats']) as String;

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
      if (_hasLiveConnection) {
        await _request('core.unsubscribe', [_appStatsSubscriptionId!]);

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
      _wantsAppStats = false;
      _isSubscribedToAppStats = false;
      _appStatsSubscriptionId = null;
      await _appStatsController?.close();
      _appStatsController = null;

      if (kDebugMode) {
        print('TrueNAS API: App stats subscription cleaned up');
      }
    }
  }
}
