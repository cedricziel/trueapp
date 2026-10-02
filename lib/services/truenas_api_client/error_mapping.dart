part of '../truenas_api_client.dart';

mixin _ErrorMapping {
  ConnectionException _handleConnectionError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network connectivity issues
    if (error is SocketException ||
        errorString.contains('network is unreachable') ||
        errorString.contains('no route to host') ||
        errorString.contains('connection refused')) {
      return ConnectionException(
        ConnectionError.networkUnreachable(details: error.toString()),
      );
    }

    // Timeout issues
    if (error is TimeoutException ||
        errorString.contains('timeout') ||
        errorString.contains('timed out') ||
        errorString.contains('client closed with pending request')) {
      return ConnectionException(
        ConnectionError.connectionTimeout(details: error.toString()),
      );
    }

    // A JSON-RPC error from the middleware itself. TrueNAS attaches a
    // `data` map ({error: errno, errname, reason, trace, extra}) to method
    // call failures, and its message alone ("Method call error") says
    // nothing - the reason is what the user needs to see.
    if (error is RpcException) {
      final data = error.data;
      final reason = data is Map ? data['reason']?.toString() : null;
      final errname = data is Map ? data['errname']?.toString() : null;
      final reasonLower = (reason ?? '').toLowerCase();
      final details = reason == null || reason.isEmpty
          ? 'JSON-RPC error ${error.code}: ${error.message}'
          : reason;

      if (errname == 'ENOTAUTHENTICATED' ||
          reasonLower.contains('not authenticated') ||
          reasonLower.contains('session is expired')) {
        return ConnectionException(
          ConnectionError.authenticationFailed(details: details),
        );
      }

      if (error.code == 401 ||
          errorString.contains('unauthorized') ||
          errorString.contains('authentication failed') ||
          errorString.contains('invalid credentials')) {
        return ConnectionException(
          ConnectionError.invalidCredentials(details: details),
        );
      }

      if (error.code == 403 ||
          errname == 'EACCES' ||
          errname == 'EPERM' ||
          errorString.contains('forbidden') ||
          reasonLower.contains('not authorized')) {
        return ConnectionException(
          ConnectionError.permissionDenied(details: details),
        );
      }

      // Anything else the middleware rejected (a method that failed, a
      // method that doesn't exist on this TrueNAS version, invalid params)
      // happened on the server, and is not a connectivity problem.
      return ConnectionException(ConnectionError.serverError(details: details));
    }

    // The server answered, but not in a shape this client understands.
    if (error is FormatException || error is TypeError) {
      return ConnectionException(
        ConnectionError.invalidResponse(details: error.toString()),
      );
    }

    // WebSocket specific errors
    if (errorString.contains('websocket') ||
        errorString.contains('handshake') ||
        errorString.contains('upgrade failed')) {
      return ConnectionException(
        ConnectionError.networkUnreachable(
          details: 'WebSocket connection failed: ${error.toString()}',
        ),
      );
    }

    // Default to unknown error
    return ConnectionException(
      ConnectionError.unknown(details: error.toString()),
    );
  }

  /// Normalises any failure into a [ConnectionException]. This used to
  /// re-wrap the classified error as a plain `Exception(message)`, which
  /// dropped both the [ConnectionErrorType] and the technical details on
  /// the floor - so every failure reached the UI as a generic "Connection
  /// error" with nothing to act on.
  ConnectionException _handleError(dynamic error) {
    if (error is ConnectionException) {
      return error;
    }
    return _handleConnectionError(error);
  }
}
