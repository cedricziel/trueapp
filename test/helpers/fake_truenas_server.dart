import 'dart:async';
import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/io.dart';

typedef FakeRpcHandler = FutureOr<Object?> Function(json_rpc.Parameters);

/// A call the fake finished answering, successfully or not.
final class FakeRpcCall {
  const FakeRpcCall(this.method, this.params, {this.error});

  final String method;
  final Object? params;

  /// What the handler threw, null when it answered.
  final Object? error;

  bool get succeeded => error == null;
}

/// A fake TrueNAS middleware endpoint speaking JSON-RPC 2.0 over a real
/// loopback WebSocket at `/api/current`, for exercising [TrueNasApiClient]
/// without a real server.
///
/// Like the real middleware, it checks `auth.login` against [accounts] (and
/// [otpCodes] for two-factor accounts) and refuses every other method except
/// `core.ping` until the connection has logged in. `auth.me`, `core.ping`,
/// `core.subscribe` and `core.unsubscribe` have working defaults; [onMethod]
/// overrides any method, effective immediately on live connections too.
class FakeTrueNasServer {
  FakeTrueNasServer._(this._httpServer, this.accounts, this.otpCodes);

  static Future<FakeTrueNasServer> start({
    Map<String, String> accounts = const {'root': 'password'},
    Map<String, String> otpCodes = const {},
  }) async {
    final httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final server = FakeTrueNasServer._(
      httpServer,
      Map.of(accounts),
      Map.of(otpCodes),
    );
    unawaited(server._acceptConnections());
    return server;
  }

  final HttpServer _httpServer;

  /// Username to password.
  final Map<String, String> accounts;

  /// Username to the OTP token it must log in with.
  final Map<String, String> otpCodes;

  /// Every call answered so far, oldest first.
  final List<FakeRpcCall> calls = [];

  final List<WebSocket> _sockets = [];
  final List<json_rpc.Peer> _peers = [];
  final Map<String, FakeRpcHandler> _handlers = {};
  final Map<String, List<json_rpc.RpcException>> _failures = {};
  var _subscriptionCounter = 0;

  /// Number of client connections accepted so far.
  int connectionCount = 0;

  int get port => _httpServer.port;

  /// Answers [method] with [handler] instead of the default.
  void onMethod(String method, FakeRpcHandler handler) {
    _handlers[method] = handler;
  }

  /// Restores the default behaviour of [method].
  void resetMethod(String method) => _handlers.remove(method);

  /// Makes the next call to [method] fail with [code], once per call to this.
  void failNext(String method, {int code = 1, String message = 'failed'}) {
    (_failures[method] ??= []).add(json_rpc.RpcException(code, message));
  }

  /// Calls to [method] that succeeded.
  int successfulCalls(String method) =>
      calls.where((c) => c.method == method && c.succeeded).length;

  /// Pushes a `collection_update` event to every live connection.
  void emit(String collection, {String? msg, Object? id, Object? fields}) {
    for (final peer in _peers) {
      peer.sendNotification('collection_update', {
        'collection': collection,
        'msg': ?msg,
        'id': ?id,
        'fields': ?fields,
      });
    }
  }

  Future<void> _acceptConnections() async {
    await for (final request in _httpServer) {
      if (request.uri.path != '/api/current') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        continue;
      }
      final socket = await WebSocketTransformer.upgrade(
        request,
        protocolSelector: (protocols) => 'json-rpc',
      );
      connectionCount++;
      _sockets.add(socket);
      _serve(IOWebSocketChannel(socket).cast<String>());
    }
  }

  void _serve(StreamChannel<String> channel) {
    final peer = json_rpc.Peer(channel);
    final connection = _Connection();
    // Named registrations pass a handler's own METHOD_NOT_FOUND through
    // untouched; json_rpc_2 rewrites that code when a fallback throws it.
    // The fallback covers methods first configured after this connection.
    for (final method in {..._defaultMethods, ..._handlers.keys}) {
      peer.registerMethod(
        method,
        (json_rpc.Parameters params) => _dispatch(params, connection),
      );
    }
    peer.registerFallback((params) => _dispatch(params, connection));
    _peers.add(peer);
    unawaited(
      peer.listen().catchError((_) {}).whenComplete(() => _peers.remove(peer)),
    );
  }

  Future<Object?> _dispatch(
    json_rpc.Parameters params,
    _Connection connection,
  ) async {
    final method = params.method;
    try {
      final failures = _failures[method];
      if (failures != null && failures.isNotEmpty) throw failures.removeAt(0);
      if (connection.user == null &&
          method != 'auth.login' &&
          method != 'core.ping') {
        // Shape copied from a live SCALE box.
        throw json_rpc.RpcException(
          -32001,
          'Method call error',
          data: {
            'error': 207,
            'errname': 'ENOTAUTHENTICATED',
            'reason': '[ENOTAUTHENTICATED] Not authenticated',
          },
        );
      }
      final handler = _handlers[method] ?? _defaultHandler(method);
      if (handler == null) throw json_rpc.RpcException.methodNotFound(method);
      final result = await handler(params);
      if (method == 'auth.login' && result == true) {
        connection.user = params.asList.first as String;
      }
      calls.add(FakeRpcCall(method, params.value));
      return result;
    } catch (error) {
      calls.add(FakeRpcCall(method, params.value, error: error));
      rethrow;
    }
  }

  static const _defaultMethods = {
    'auth.login',
    'auth.me',
    'core.ping',
    'core.subscribe',
    'core.unsubscribe',
  };

  FakeRpcHandler? _defaultHandler(String method) => switch (method) {
    'auth.login' => _login,
    'auth.me' => (_) => {
      'pw_name': 'root',
      'pw_gecos': 'Root User',
      'pw_dir': '/root',
      'pw_shell': '/bin/sh',
      'pw_uid': 0,
      'pw_gid': 0,
      'source': 'LOCAL',
      'local': true,
      'grouplist': <int>[],
      'attributes': <String, dynamic>{},
      'privilege': <String, dynamic>{},
    },
    'core.ping' => (_) => 'pong',
    'core.subscribe' => (_) => 'sub-${++_subscriptionCounter}',
    'core.unsubscribe' => (_) => true,
    _ => null,
  };

  bool _login(json_rpc.Parameters params) {
    final [username, password, ...rest] = params.asList;
    if (accounts[username] != password) return false;
    final otp = otpCodes[username];
    return otp == null || (rest.isNotEmpty && rest.first == otp);
  }

  /// Kills the live socket(s) without a graceful protocol shutdown, the way
  /// the OS drops a backgrounded app's connection.
  Future<void> dropConnections() async {
    for (final socket in _sockets) {
      await socket.close();
    }
    _sockets.clear();
    _peers.clear();
    // Give the client's stream a turn to observe the closure.
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  Future<void> stop() async {
    await dropConnections();
    await _httpServer.close(force: true);
  }
}

final class _Connection {
  /// Who logged in on this connection, null until then.
  String? user;
}
