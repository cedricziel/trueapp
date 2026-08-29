import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/stream_channel.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/truenas_api_client.dart';
import 'package:web_socket_channel/io.dart';

/// A minimal stand-in for a TrueNAS middleware WebSocket endpoint.
///
/// It counts the calls the client makes so a test can assert that a
/// subscription was actually re-established, and it can drop the socket the
/// way iOS does when an app is suspended in the background.
class FakeTrueNasServer {
  FakeTrueNasServer._(this._httpServer);

  final HttpServer _httpServer;
  final List<WebSocket> _sockets = [];
  int loginCount = 0;
  int subscribeCount = 0;
  int pingCount = 0;

  /// Makes core.subscribe fail, the way a server still starting up rejects
  /// subscriptions for a while after a reconnect.
  bool failSubscribes = false;

  static Future<FakeTrueNasServer> start() async {
    final httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final server = FakeTrueNasServer._(httpServer);
    unawaited(server._acceptConnections());
    return server;
  }

  int get port => _httpServer.port;

  Future<void> _acceptConnections() async {
    await for (final request in _httpServer) {
      final socket = await WebSocketTransformer.upgrade(
        request,
        protocolSelector: (protocols) => 'json-rpc',
      );
      _sockets.add(socket);
      _serve(IOWebSocketChannel(socket).cast<String>());
    }
  }

  void _serve(StreamChannel<String> channel) {
    final peer = json_rpc.Peer(channel)
      ..registerMethod('auth.login', (json_rpc.Parameters _) {
        loginCount++;
        return true;
      })
      ..registerMethod('core.subscribe', (json_rpc.Parameters _) {
        if (failSubscribes) {
          throw json_rpc.RpcException(1, 'subscription refused');
        }
        subscribeCount++;
        return 'subscription-$subscribeCount';
      })
      ..registerMethod('core.unsubscribe', (json_rpc.Parameters _) => true)
      ..registerMethod('core.ping', (json_rpc.Parameters _) {
        pingCount++;
        return 'pong';
      });
    unawaited(peer.listen().catchError((_) {}));
  }

  /// Kills the live socket(s) without a graceful protocol shutdown - what the
  /// device does to a backgrounded app's connection.
  Future<void> dropConnections() async {
    for (final socket in _sockets) {
      await socket.close();
    }
    _sockets.clear();
    // Give the client's stream a turn to observe the closure.
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  Future<void> stop() async {
    await dropConnections();
    await _httpServer.close(force: true);
  }
}

void main() {
  late FakeTrueNasServer server;
  late TrueNasApiClient client;

  setUp(() async {
    server = await FakeTrueNasServer.start();
    client = TrueNasApiClient(
      NasServer(
        id: 'recovery-test',
        name: 'Recovery Test',
        host: '127.0.0.1',
        port: server.port,
        useHttps: false,
        username: 'user',
        password: 'pw',
        localUrl: null,
        // Empty list keeps NetworkService off the platform channels.
        trustedWifiSsids: const [],
        isDefault: false,
      ),
    );
  });

  tearDown(() async {
    await client.close();
    await server.stop();
  });

  test(
    'ensureConnectionAlive restores a connection dropped in the background',
    () async {
      await client.subscribeToSystemStats();
      expect(server.loginCount, 1);
      expect(server.subscribeCount, 1);

      // Backgrounded: the OS tears the socket down. No timer can help here -
      // the keepalive ping sees a closed client and has nothing to ping.
      await server.dropConnections();

      // Foregrounded: the app asks the client to make itself usable again.
      await client.ensureConnectionAlive();

      expect(
        server.loginCount,
        2,
        reason: 'the client must re-authenticate on the new socket',
      );
      expect(
        server.subscribeCount,
        2,
        reason: 'active subscriptions must be restored, or stats stay frozen',
      );
    },
  );

  test(
    'a subscription that fails to restore is retried on the next resume',
    () async {
      await client.subscribeToSystemStats();
      expect(server.subscribeCount, 1);

      await server.dropConnections();
      server.failSubscribes = true;

      // First resume: the socket comes back, but the server refuses the
      // subscription for now.
      await client.ensureConnectionAlive();
      expect(
        server.subscribeCount,
        1,
        reason: 'a refused subscription must not count as established',
      );

      // The server accepts subscriptions again; the stream the UI asked for is
      // still wanted, so the next resume has to attempt it rather than treat a
      // healthy socket as good enough.
      server.failSubscribes = false;
      await client.ensureConnectionAlive();

      expect(
        server.subscribeCount,
        2,
        reason:
            'a subscription the UI asked for must survive a failed restore, '
            'otherwise the stream stays frozen while recovery reports success',
      );
    },
  );

  test('concurrent recovery attempts reconnect only once', () async {
    await client.subscribeToSystemStats();
    expect(server.loginCount, 1);

    await server.dropConnections();

    // The resume hook and the keepalive timer can both notice the dead socket
    // at the same moment; that must not open two sessions.
    await Future.wait([
      client.ensureConnectionAlive(),
      client.ensureConnectionAlive(),
      client.ensureConnectionAlive(),
    ]);

    expect(
      server.loginCount,
      2,
      reason: 'overlapping recovery attempts must share one reconnect',
    );
    expect(server.subscribeCount, 2);
  });

  test(
    'ensureConnectionAlive reports a failed recovery to its caller',
    () async {
      await client.subscribeToSystemStats();

      // The server is gone entirely - recovery cannot succeed, and the caller
      // has to learn that instead of being told everything is fine.
      await server.stop();

      await expectLater(
        client.ensureConnectionAlive(),
        throwsA(isA<Exception>()),
      );
    },
  );

  test(
    'subscribeToSystemStats re-subscribes after the connection was lost',
    () async {
      await client.subscribeToSystemStats();
      expect(server.subscribeCount, 1);

      // The app goes to the background; iOS tears the socket down.
      await server.dropConnections();

      // Coming back to the foreground, the screen asks for stats again. The
      // subscription lives on the dead socket, so it has to be re-established
      // - not skipped because a stale flag still says "already subscribed".
      await client.subscribeToSystemStats();

      expect(
        server.subscribeCount,
        2,
        reason:
            'the stats subscription must be re-established on the new '
            'connection, otherwise the screen keeps showing frozen values',
      );
    },
  );
}
