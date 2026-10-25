import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/truenas_api_client.dart';

import '../helpers/fake_truenas_server.dart';

void main() {
  late FakeTrueNasServer server;
  late TrueNasApiClient client;

  setUp(() async {
    server = await FakeTrueNasServer.start(accounts: {'user': 'pw'});
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
      expect(server.successfulCalls('auth.login'), 1);
      expect(server.successfulCalls('core.subscribe'), 1);

      // Backgrounded: the OS tears the socket down. No timer can help here -
      // the keepalive ping sees a closed client and has nothing to ping.
      await server.dropConnections();

      // Foregrounded: the app asks the client to make itself usable again.
      await client.ensureConnectionAlive();

      expect(
        server.successfulCalls('auth.login'),
        2,
        reason: 'the client must re-authenticate on the new socket',
      );
      expect(
        server.successfulCalls('core.subscribe'),
        2,
        reason: 'active subscriptions must be restored, or stats stay frozen',
      );
    },
  );

  test(
    'a subscription that fails to restore is retried on the next resume',
    () async {
      await client.subscribeToSystemStats();
      expect(server.successfulCalls('core.subscribe'), 1);

      await server.dropConnections();
      server.onMethod(
        'core.subscribe',
        (_) => throw json_rpc.RpcException(1, 'subscription refused'),
      );

      // First resume: the socket comes back, but the server refuses the
      // subscription for now.
      await client.ensureConnectionAlive();
      expect(
        server.successfulCalls('core.subscribe'),
        1,
        reason: 'a refused subscription must not count as established',
      );

      // The server accepts subscriptions again; the stream the UI asked for is
      // still wanted, so the next resume has to attempt it rather than treat a
      // healthy socket as good enough.
      server.resetMethod('core.subscribe');
      await client.ensureConnectionAlive();

      expect(
        server.successfulCalls('core.subscribe'),
        2,
        reason:
            'a subscription the UI asked for must survive a failed restore, '
            'otherwise the stream stays frozen while recovery reports success',
      );
    },
  );

  test('concurrent recovery attempts reconnect only once', () async {
    await client.subscribeToSystemStats();
    expect(server.successfulCalls('auth.login'), 1);

    await server.dropConnections();

    // The resume hook and the keepalive timer can both notice the dead socket
    // at the same moment; that must not open two sessions.
    await Future.wait([
      client.ensureConnectionAlive(),
      client.ensureConnectionAlive(),
      client.ensureConnectionAlive(),
    ]);

    expect(
      server.successfulCalls('auth.login'),
      2,
      reason: 'overlapping recovery attempts must share one reconnect',
    );
    expect(server.successfulCalls('core.subscribe'), 2);
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

  test('a zombie socket that stops answering pings is torn down and '
      're-authenticated', () async {
    await client.subscribeToSystemStats();
    expect(server.successfulCalls('auth.login'), 1);

    // The socket stays open but stops answering - a half-dead connection
    // the Peer cannot see (isClosed remains false), so recovery must not
    // trust the session just because the socket still looks live.
    server.onMethod('core.ping', (_) => Completer<String>().future);
    unawaited(client.ensureConnectionAlive().catchError((_) {}));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // The next resume finds the earlier ping still unanswered and has to
    // recover with a fresh session, not vouch for the zombie.
    server.resetMethod('core.ping');
    await client.ensureConnectionAlive();

    expect(
      server.successfulCalls('auth.login'),
      2,
      reason:
          'recovery must re-authenticate on a fresh socket instead of '
          'reporting the unresponsive session as connected',
    );
  });

  test(
    'close() prevents later recovery from resurrecting the session',
    () async {
      await client.subscribeToSystemStats();
      expect(server.successfulCalls('auth.login'), 1);

      await client.close();

      // The app-resume hook can still fire for a client that was just
      // released; it must not rebuild the session close tore down, which
      // would leak a socket and a keepalive timer nobody owns.
      await client.ensureConnectionAlive();

      expect(
        server.successfulCalls('auth.login'),
        1,
        reason: 'a closed client must stay closed',
      );
    },
  );

  test(
    'subscribeToSystemStats re-subscribes after the connection was lost',
    () async {
      await client.subscribeToSystemStats();
      expect(server.successfulCalls('core.subscribe'), 1);

      // The app goes to the background; iOS tears the socket down.
      await server.dropConnections();

      // Coming back to the foreground, the screen asks for stats again. The
      // subscription lives on the dead socket, so it has to be re-established
      // - not skipped because a stale flag still says "already subscribed".
      await client.subscribeToSystemStats();

      expect(
        server.successfulCalls('core.subscribe'),
        2,
        reason:
            'the stats subscription must be re-established on the new '
            'connection, otherwise the screen keeps showing frozen values',
      );
    },
  );

  test(
    'a failed app stats re-subscribe leaves the stream for recovery to restore',
    () async {
      await client.subscribeToAppStats();
      expect(server.successfulCalls('core.subscribe'), 1);

      await server.dropConnections();
      server.onMethod(
        'core.subscribe',
        (_) => throw json_rpc.RpcException(1, 'subscription refused'),
      );
      await expectLater(client.subscribeToAppStats(), throwsA(anything));

      server.resetMethod('core.subscribe');
      await client.ensureConnectionAlive();

      expect(
        server.successfulCalls('core.subscribe'),
        2,
        reason:
            'the dead socket\'s subscription must not count as live, so '
            'recovery re-establishes the app stats stream',
      );
    },
  );
}
