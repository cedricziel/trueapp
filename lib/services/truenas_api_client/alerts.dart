part of '../truenas_api_client.dart';

mixin _AlertsOps on _ClientTransport implements AlertsApi {
  @override
  Stream<AlertEvent> get alertEvents {
    _alertsController ??= StreamController<AlertEvent>.broadcast();
    return _alertsController!.stream;
  }

  @override
  Future<void> subscribeToAlerts() async {
    _wantsAlerts = true;

    if (_isSubscribedToAlerts && _hasLiveConnection) {
      _log.debug('Already subscribed to alerts');
      return;
    }

    _isSubscribedToAlerts = false;
    _alertsSubscriptionId = null;

    try {
      await _ensureAuthenticated();

      _alertsController ??= StreamController<AlertEvent>.broadcast();

      _alertsSubscriptionId =
          await _request('core.subscribe', ['alert.list']) as String;
      _isSubscribedToAlerts = true;

      _log.info(
        'Subscribed to alerts',
        attributes: {'subscription.id': _alertsSubscriptionId},
      );
    } catch (e) {
      _log.error('Failed to subscribe to alerts', error: e);
      throw _handleError(e);
    }
  }

  @override
  Future<void> unsubscribeFromAlerts() async {
    if (!_isSubscribedToAlerts || _alertsSubscriptionId == null) {
      return;
    }

    try {
      if (_hasLiveConnection) {
        await _request('core.unsubscribe', [_alertsSubscriptionId!]);

        _log.info(
          'Unsubscribed from alerts',
          attributes: {'subscription.id': _alertsSubscriptionId},
        );
      }
    } catch (e) {
      _log.error('Error unsubscribing from alerts', error: e);
    } finally {
      _wantsAlerts = false;
      _isSubscribedToAlerts = false;
      _alertsSubscriptionId = null;
      await _alertsController?.close();
      _alertsController = null;
    }
  }

  @override
  Future<void> dismissAlert(String alertId) =>
      _sendAlertAction('alert.dismiss', alertId);

  @override
  Future<void> restoreAlert(String alertId) =>
      _sendAlertAction('alert.restore', alertId);

  Future<void> _sendAlertAction(String method, String alertId) async {
    try {
      await _sendRequest(method, [alertId]);
    } catch (e) {
      throw _handleError(e);
    }
  }
}
