part of '../truenas_api_client.dart';

mixin _SessionOps on _ClientBase, _Connection, _KeepaliveAndRecovery
    implements SessionApi {
  @override
  Future<void> close() async {
    // Refuse recovery work from here on: a keepalive timeout or app-resume
    // hook firing during the awaits below must not rebuild the session this
    // close is tearing down. Set before the first await so nothing sneaks
    // in between.
    _isClosing = true;

    // Let in-flight work settle first, so this close tears down the socket
    // those attempts produce instead of racing their handshakes - which
    // would leak the socket and the keepalive timer a successful login
    // starts.
    await _recovery.settle();
    await _connecting.settle();
    await _authenticating.settle();

    _stopKeepalive();
    _connectionStatusProvider?.updateConnectionState(
      _server.id,
      TrueNASConnectionState.disconnected,
    );
    await unsubscribeFromSystemStats();
    await unsubscribeFromAppStats();
    await unsubscribeFromJobs();
    final staleClient = _client;
    final staleChannel = _wsChannel;
    _client = null;
    _wsChannel = null;
    _isAuthenticated = false;
    await staleClient?.close();
    await staleChannel?.sink.close();
  }

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
          .sendRequest('auth.login', [username, password, ?otpToken])
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
      final result = await _sendRequest('auth.me');
      return UserInfo.fromJson(result as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }
}
