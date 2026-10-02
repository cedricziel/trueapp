part of '../truenas_api_client.dart';

mixin _ServicesOps on _ClientTransport implements ServicesApi {
  @override
  Future<void> startService(String serviceId) =>
      _controlService('service.start', serviceId);

  @override
  Future<void> stopService(String serviceId) =>
      _controlService('service.stop', serviceId);

  @override
  Future<void> restartService(String serviceId) =>
      _controlService('service.restart', serviceId);

  /// `silent: false` makes the middleware raise when the unit fails to
  /// change state instead of answering `false`, so the caller sees the error.
  Future<void> _controlService(String method, String serviceId) async {
    try {
      await _ensureAuthenticated();
      await _request(method, [
        serviceId,
        {'silent': false},
      ]);
    } catch (e) {
      throw _handleError(e);
    }
  }
}
