import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/providers/connection_status_provider.dart';

void main() {
  late ConnectionStatusProvider provider;

  setUp(() {
    provider = ConnectionStatusProvider();
  });

  group('ConnectionStatusProvider - initial state', () {
    test('has no statuses and reports empty aggregates', () {
      expect(provider.getStatus('server-1'), isNull);
      expect(provider.connectedServers, isEmpty);
      expect(provider.healthyConnectionCount, 0);
    });
  });

  group('ConnectionStatusProvider - updateConnectionState', () {
    test('creates a new status entry and notifies', () {
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.updateConnectionState(
        'server-1',
        TrueNASConnectionState.connecting,
      );

      final status = provider.getStatus('server-1');
      expect(status, isNotNull);
      expect(status!.state, TrueNASConnectionState.connecting);
      expect(status.lastPong, isNull);
      expect(notifications, 1);
    });

    test('transitioning to connected sets lastPong to now', () {
      provider.updateConnectionState(
        'server-1',
        TrueNASConnectionState.connected,
        connectionUrl: 'https://nas.local',
        isLocalConnection: true,
      );

      final status = provider.getStatus('server-1')!;
      expect(status.state, TrueNASConnectionState.connected);
      expect(status.lastPong, isNotNull);
      expect(status.connectionUrl, 'https://nas.local');
      expect(status.isLocalConnection, isTrue);
      expect(status.isHealthy, isTrue);
    });

    test(
      'preserves connectionUrl and isLocalConnection when omitted on a later update',
      () {
        provider.updateConnectionState(
          'server-1',
          TrueNASConnectionState.connected,
          connectionUrl: 'https://nas.local',
          isLocalConnection: true,
        );

        provider.updateConnectionState(
          'server-1',
          TrueNASConnectionState.reconnecting,
        );

        final status = provider.getStatus('server-1')!;
        expect(status.state, TrueNASConnectionState.reconnecting);
        expect(status.connectionUrl, 'https://nas.local');
        expect(status.isLocalConnection, isTrue);
        // lastPong from the earlier connected state is preserved too.
        expect(status.lastPong, isNotNull);
      },
    );

    test('records an error message on the error state', () {
      provider.updateConnectionState(
        'server-1',
        TrueNASConnectionState.error,
        error: 'Connection refused',
      );

      final status = provider.getStatus('server-1')!;
      expect(status.state, TrueNASConnectionState.error);
      expect(status.error, 'Connection refused');
    });

    test('tracks multiple servers independently', () {
      provider.updateConnectionState(
        'server-1',
        TrueNASConnectionState.connected,
      );
      provider.updateConnectionState(
        'server-2',
        TrueNASConnectionState.disconnected,
      );

      expect(provider.connectedServers, ['server-1']);
      expect(
        provider.getStatus('server-2')!.state,
        TrueNASConnectionState.disconnected,
      );
    });
  });

  group('ConnectionStatusProvider - updatePingStatus', () {
    test('creates a status entry defaulting to disconnected', () {
      final sent = DateTime(2026, 1, 1, 12);
      final received = DateTime(2026, 1, 1, 12, 0, 1);

      provider.updatePingStatus(
        'server-1',
        pingSent: sent,
        pongReceived: received,
        latency: const Duration(milliseconds: 250),
      );

      final status = provider.getStatus('server-1')!;
      expect(status.state, TrueNASConnectionState.disconnected);
      expect(status.lastPing, sent);
      expect(status.lastPong, received);
      expect(status.latency, const Duration(milliseconds: 250));
    });

    test('preserves the existing state and error when only pinging', () {
      provider.updateConnectionState(
        'server-1',
        TrueNASConnectionState.connected,
      );

      provider.updatePingStatus(
        'server-1',
        pongReceived: DateTime(2026, 1, 2),
        latency: const Duration(milliseconds: 10),
      );

      final status = provider.getStatus('server-1')!;
      expect(status.state, TrueNASConnectionState.connected);
      expect(status.latency, const Duration(milliseconds: 10));
    });

    test('notifies listeners', () {
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.updatePingStatus(
        'server-1',
        latency: const Duration(seconds: 1),
      );

      expect(notifications, 1);
    });

    test('preserves connectionUrl and isLocalConnection set by an earlier '
        'updateConnectionState call', () {
      provider.updateConnectionState(
        'server-1',
        TrueNASConnectionState.connected,
        connectionUrl: 'https://nas.local',
        isLocalConnection: true,
      );

      provider.updatePingStatus(
        'server-1',
        pongReceived: DateTime(2026, 1, 2),
        latency: const Duration(milliseconds: 10),
      );

      final status = provider.getStatus('server-1')!;
      expect(status.connectionUrl, 'https://nas.local');
      expect(status.isLocalConnection, isTrue);
    });
  });

  group('ConnectionStatusProvider - removeServer', () {
    test('removes the tracked status and notifies', () {
      provider.updateConnectionState(
        'server-1',
        TrueNASConnectionState.connected,
      );

      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.removeServer('server-1');

      expect(provider.getStatus('server-1'), isNull);
      expect(notifications, 1);
    });

    test('is a no-op for an unknown server id', () {
      provider.removeServer('unknown');
      expect(provider.getStatus('unknown'), isNull);
    });
  });

  group('ConnectionStatusProvider - clearAll', () {
    test('clears every tracked status', () {
      provider.updateConnectionState(
        'server-1',
        TrueNASConnectionState.connected,
      );
      provider.updateConnectionState(
        'server-2',
        TrueNASConnectionState.connected,
      );

      provider.clearAll();

      expect(provider.getStatus('server-1'), isNull);
      expect(provider.getStatus('server-2'), isNull);
      expect(provider.connectedServers, isEmpty);
    });
  });

  group('ConnectionStatusProvider - connectedServers', () {
    test('lists only servers currently in the connected state', () {
      provider.updateConnectionState('a', TrueNASConnectionState.connected);
      provider.updateConnectionState('b', TrueNASConnectionState.connecting);
      provider.updateConnectionState('c', TrueNASConnectionState.connected);

      expect(provider.connectedServers, unorderedEquals(['a', 'c']));
    });
  });

  group('ConnectionStatusProvider - healthyConnectionCount', () {
    test('counts only connected servers with a recent pong', () {
      provider.updateConnectionState('a', TrueNASConnectionState.connected);
      provider.updateConnectionState('b', TrueNASConnectionState.connecting);

      expect(provider.healthyConnectionCount, 1);
    });

    test('excludes a connected server whose pong is stale', () {
      provider.updateConnectionState('a', TrueNASConnectionState.connected);
      // Overwrite the heartbeat directly to simulate one that has gone stale
      // while the state is still reported as connected.
      provider.updatePingStatus(
        'a',
        pongReceived: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      final stale = provider.getStatus('a')!;
      expect(stale.state, TrueNASConnectionState.connected);
      expect(stale.isHealthy, isFalse);
      expect(provider.healthyConnectionCount, 0);
    });
  });

  group('ConnectionStatus.isHealthy', () {
    test('is false without a state of connected', () {
      final status = ConnectionStatus(
        state: TrueNASConnectionState.connecting,
        lastPing: DateTime.now(),
        lastPong: DateTime.now(),
      );
      expect(status.isHealthy, isFalse);
    });

    test('is false when connected but lastPong is null', () {
      final status = ConnectionStatus(
        state: TrueNASConnectionState.connected,
        lastPing: DateTime.now(),
      );
      expect(status.isHealthy, isFalse);
    });

    test('is false when connected but lastPong is stale', () {
      final status = ConnectionStatus(
        state: TrueNASConnectionState.connected,
        lastPing: DateTime.now(),
        lastPong: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(status.isHealthy, isFalse);
    });

    test('copyWith overrides only the provided fields', () {
      final base = ConnectionStatus(
        state: TrueNASConnectionState.connected,
        lastPing: DateTime(2026, 1, 1),
        connectionUrl: 'https://a',
      );

      final updated = base.copyWith(state: TrueNASConnectionState.error);

      expect(updated.state, TrueNASConnectionState.error);
      expect(updated.lastPing, base.lastPing);
      expect(updated.connectionUrl, 'https://a');
    });
  });
}
