import 'dart:async';
import 'dart:io';

import 'package:flutter_otel/flutter_otel.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:truehub/models/connection_error.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A low-cardinality classification of [error] for the `error.type` span and
/// log attribute. Looks through [ConnectionException] and
/// [WebSocketChannelException] to the failure underneath, since the wrapper
/// types say nothing about what actually went wrong.
String errorTypeOf(Object error) {
  if (error is ConnectionException) {
    switch (error.error.type) {
      case ConnectionErrorType.authenticationFailed:
      case ConnectionErrorType.invalidCredentials:
        return 'auth_rejected';
      case ConnectionErrorType.permissionDenied:
        return 'permission_denied';
      case ConnectionErrorType.invalidResponse:
        return 'invalid_response';
      case ConnectionErrorType.networkUnreachable:
      case ConnectionErrorType.connectionTimeout:
      case ConnectionErrorType.serverError:
      case ConnectionErrorType.unknown:
        final cause = error.error.cause;
        return cause == null ? error.error.type.name : errorTypeOf(cause);
    }
  }

  if (error is WebSocketChannelException && error.inner != null) {
    return errorTypeOf(error.inner!);
  }
  if (error is TimeoutException) return 'timeout';
  if (error is TlsException) return 'tls';
  if (error is SocketException) return _socketErrorType(error);
  if (error is WebSocketException) {
    return error.message.contains('not upgraded to websocket')
        ? 'websocket_upgrade_failed'
        : 'websocket_error';
  }
  if (error is RpcException) return 'rpc_error';
  return error.runtimeType.toString();
}

String _socketErrorType(SocketException error) {
  final text = '${error.message} ${error.osError?.message ?? ''}'.toLowerCase();
  if (text.contains('connection refused')) return 'connection_refused';
  if (text.contains('failed host lookup') ||
      text.contains('nodename nor servname') ||
      text.contains('name or service not known')) {
    return 'dns';
  }
  if (text.contains('network is unreachable') ||
      text.contains('no route to host')) {
    return 'network_unreachable';
  }
  if (text.contains('timed out')) return 'timeout';
  if (text.contains('connection reset')) return 'connection_reset';
  return 'socket_error';
}

/// The exception behind a [ConnectionException], or [error] itself when there
/// is nothing underneath. Hand this to a logger or span so the real failure -
/// not the generic "Server not reachable" wrapper - is what gets recorded.
Object rootCauseOf(Object error) {
  if (error is ConnectionException) return error.error.cause ?? error;
  return error;
}

/// One line saying what failed and why. A [ConnectionException] stringifies
/// to its user-facing message alone, which is useless in a log.
String describeError(Object error) {
  if (error is! ConnectionException) return error.toString();
  final connectionError = error.error;
  final detail = connectionError.cause ?? connectionError.technicalDetails;
  return detail == null
      ? connectionError.message
      : '${connectionError.message}: $detail';
}

/// OTel `server.address` / `server.port` for [url]. Host and port only: the
/// URL itself can carry user-info or credential-shaped query parameters.
Map<String, Object> endpointAttributes(String? url) {
  final uri = url == null ? null : Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) return const {};
  final port = uri.hasPort
      ? uri.port
      : switch (uri.scheme) {
          'https' || 'wss' => 443,
          'http' || 'ws' => 80,
          _ => null,
        };
  return {'server.address': uri.host, 'server.port': ?port};
}

extension DiagnosticLogger on Logger {
  /// [Logger.error] with the concrete cause in the body and `error.*`
  /// attributes, so a [ConnectionException] never logs as only its generic
  /// message.
  void errorWithCause(
    String body,
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?>? attributes,
  }) => this.error(
    '$body: ${describeError(error)}',
    error: rootCauseOf(error),
    stackTrace: stackTrace,
    attributes: {'error.type': errorTypeOf(error), ...?attributes},
  );
}
