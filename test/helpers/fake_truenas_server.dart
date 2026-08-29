import 'dart:async';
import 'dart:io';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/io.dart';

/// A minimal fake TrueNAS middleware endpoint speaking JSON-RPC 2.0 over a
/// real loopback WebSocket, for exercising [TrueNasApiClient] without a real
/// server.
///
/// Method responses are configured with [onMethod] before a client connects
/// (or before it reconnects, for a socket-drop test). A handful of common
/// methods (`auth.login`, `core.ping`, `core.subscribe`, `core.unsubscribe`)
/// have sane defaults so tests only need to configure what they care about.
class FakeTrueNasServer {
  FakeTrueNasServer._(this._httpServer) {
    // Sane defaults so most tests don't need to wire up plumbing methods.
    onMethod('auth.login', (_) => true);
    onMethod('core.ping', (_) => 'pong');
    onMethod(
      'auth.me',
      (_) => {
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
    );
    var subCounter = 0;
    onMethod('core.subscribe', (_) => 'sub-${++subCounter}');
    onMethod('core.unsubscribe', (_) => true);
  }

  final HttpServer _httpServer;
  final List<WebSocket> _sockets = [];
  final List<json_rpc.Peer> _peers = [];
  final Map<String, FutureOr<Object?> Function(json_rpc.Parameters)> _handlers =
      {};

  /// Number of client connections accepted so far.
  int connectionCount = 0;

  static Future<FakeTrueNasServer> start() async {
    final httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final server = FakeTrueNasServer._(httpServer);
    unawaited(server._acceptConnections());
    return server;
  }

  int get port => _httpServer.port;

  /// Configures the canned response (or throws an [json_rpc.RpcException])
  /// for [method]. Applies to every connection accepted from this point
  /// forward - already-connected peers keep whatever was registered when
  /// they connected, since json_rpc_2 forbids re-registering a method name
  /// on a live [json_rpc.Peer].
  void onMethod(
    String method,
    FutureOr<Object?> Function(json_rpc.Parameters) handler,
  ) {
    _handlers[method] = handler;
  }

  /// The most recently connected server-side peer, for sending unsolicited
  /// notifications (e.g. `collection_update`) to the client.
  json_rpc.Peer? get lastPeer => _peers.isEmpty ? null : _peers.last;

  Future<void> _acceptConnections() async {
    await for (final request in _httpServer) {
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
    _peers.add(peer);
    for (final entry in _handlers.entries) {
      peer.registerMethod(entry.key, entry.value);
    }
    unawaited(peer.listen().catchError((_) {}));
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
