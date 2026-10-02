import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/connection_error.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/api_client_manager_impl.dart';
import 'package:truehub/services/truenas_api_client.dart';

import '../helpers/fake_telemetry_service.dart';

void main() {
  group('ApiClientManager', () {
    late NasServer testServer1;
    late NasServer testServer2;
    late ApiClientManagerImpl manager;

    setUp(() {
      testServer1 = NasServer(
        id: 'test-server-1',
        name: 'Test Server 1',
        host: 'test1.example.com',
        username: 'testuser',
        password: 'testpass',
        isDefault: false,
        trustedWifiSsids: [],
        localUrl: null,
      );

      testServer2 = NasServer(
        id: 'test-server-2',
        name: 'Test Server 2',
        host: 'test2.example.com',
        username: 'testuser',
        password: 'testpass',
        isDefault: false,
        trustedWifiSsids: [],
        localUrl: null,
      );

      manager = ApiClientManagerImpl();
    });

    tearDown(() async {
      // Clean up after each test
      await manager.closeAllClients();
    });

    test('should create and reuse client for same server', () async {
      // First request for client
      final client1 = await manager.getClient(testServer1);
      expect(client1, isA<TrueNasApiClient>());
      expect(manager.hasClient(testServer1.id), isTrue);
      expect(manager.getClientCount(), equals(1));

      // Second request for same server should return same client
      final client2 = await manager.getClient(testServer1);
      expect(client2, same(client1));
      expect(manager.getClientCount(), equals(1));

      // Ref count should be 2
      final refCounts = manager.getRefCounts();
      expect(refCounts[testServer1.id], equals(2));
    });

    test('should create separate clients for different servers', () async {
      final client1 = await manager.getClient(testServer1);
      final client2 = await manager.getClient(testServer2);

      expect(client1, isA<TrueNasApiClient>());
      expect(client2, isA<TrueNasApiClient>());
      expect(client1, isNot(same(client2)));
      expect(manager.getClientCount(), equals(2));

      final activeServerIds = manager.getActiveServerIds();
      expect(activeServerIds, containsAll([testServer1.id, testServer2.id]));
    });

    test('should maintain reference count correctly', () async {
      // Get client twice
      await manager.getClient(testServer1);
      await manager.getClient(testServer1);

      var refCounts = manager.getRefCounts();
      expect(refCounts[testServer1.id], equals(2));

      // Release once
      await manager.releaseClient(testServer1.id);
      refCounts = manager.getRefCounts();
      expect(refCounts[testServer1.id], equals(1));
      expect(manager.hasClient(testServer1.id), isTrue);

      // Release again - should close client
      await manager.releaseClient(testServer1.id);
      expect(manager.hasClient(testServer1.id), isFalse);
      expect(manager.getClientCount(), equals(0));
    });

    test('should force close client regardless of ref count', () async {
      // Get client multiple times
      await manager.getClient(testServer1);
      await manager.getClient(testServer1);
      await manager.getClient(testServer1);

      var refCounts = manager.getRefCounts();
      expect(refCounts[testServer1.id], equals(3));

      // Force close should close immediately
      await manager.closeClient(testServer1.id);
      expect(manager.hasClient(testServer1.id), isFalse);
      expect(manager.getClientCount(), equals(0));
    });

    test('should close all clients', () async {
      await manager.getClient(testServer1);
      await manager.getClient(testServer2);

      expect(manager.getClientCount(), equals(2));

      await manager.closeAllClients();

      expect(manager.getClientCount(), equals(0));
      expect(manager.hasClient(testServer1.id), isFalse);
      expect(manager.hasClient(testServer2.id), isFalse);
    });

    test('should handle release of non-existent client gracefully', () async {
      // Should not throw when releasing non-existent client
      await manager.releaseClient('non-existent-id');
      expect(manager.getClientCount(), equals(0));
    });

    test('should handle close of non-existent client gracefully', () async {
      // Should not throw when closing non-existent client
      await manager.closeClient('non-existent-id');
      expect(manager.getClientCount(), equals(0));
    });

    test('should get existing client without increasing ref count', () async {
      await manager.getClient(testServer1);

      var refCounts = manager.getRefCounts();
      expect(refCounts[testServer1.id], equals(1));

      final existingClient = manager.getExistingClient(testServer1.id);
      expect(existingClient, isNotNull);

      // Ref count should remain the same
      refCounts = manager.getRefCounts();
      expect(refCounts[testServer1.id], equals(1));
    });

    test('should return null for non-existent client', () async {
      final existingClient = manager.getExistingClient('non-existent-id');
      expect(existingClient, isNull);
    });

    group('ensureAllConnectionsAlive', () {
      test('returns an empty map when there are no active clients', () async {
        final failures = await manager.ensureAllConnectionsAlive();
        expect(failures, isEmpty);
      });

      test(
        'collects a per-server failure when a client cannot reconnect',
        () async {
          // 127.0.0.1 on a port nothing listens on: the OS refuses the
          // connection immediately (no DNS lookup, no external network
          // needed), so ensureConnectionAlive()'s real reconnection attempt
          // fails fast and deterministically instead of timing out.
          final unreachableServer = NasServer(
            id: 'unreachable-server',
            name: 'Unreachable Server',
            host: '127.0.0.1',
            port: 1,
            useHttps: false,
            username: 'testuser',
            password: 'testpass',
            isDefault: false,
            trustedWifiSsids: const [],
            localUrl: null,
          );

          await manager.getClient(unreachableServer);

          final failures = await manager.ensureAllConnectionsAlive().timeout(
            const Duration(seconds: 20),
          );

          expect(failures.keys, [unreachableServer.id]);
          expect(failures[unreachableServer.id], isA<ConnectionException>());
        },
        timeout: const Timeout(Duration(seconds: 25)),
      );

      test(
        'only reports failures for servers whose client is still cached',
        () async {
          // getActiveServerIds() only contains servers with a live client,
          // so a serverId that was never fetched is simply skipped (the
          // `if (client == null) return;` guard) rather than reported as a
          // failure.
          expect(manager.getActiveServerIds(), isEmpty);
          final failures = await manager.ensureAllConnectionsAlive();
          expect(failures, isEmpty);
        },
      );
    });

    group('forceRecreateClient', () {
      test(
        'closes the existing client and returns a fresh one with ref count 1',
        () async {
          final original = await manager.getClient(testServer1);
          await manager.getClient(testServer1); // ref count -> 2
          expect(manager.getRefCounts()[testServer1.id], 2);

          final recreated = await manager.forceRecreateClient(testServer1);

          expect(recreated, isNot(same(original)));
          expect(manager.hasClient(testServer1.id), isTrue);
          expect(manager.getRefCounts()[testServer1.id], 1);
        },
      );

      test('works even when there was no existing client to close', () async {
        expect(manager.hasClient(testServer1.id), isFalse);

        final client = await manager.forceRecreateClient(testServer1);

        expect(client, isA<TrueNasApiClient>());
        expect(manager.hasClient(testServer1.id), isTrue);
      });
    });

    test(
      'passes injected telemetry through to the clients it creates',
      () async {
        final telemetryManager = ApiClientManagerImpl(
          telemetry: FakeTelemetryService(),
        );
        addTearDown(telemetryManager.closeAllClients);

        final client = await telemetryManager.getClient(testServer1);
        expect(client, isA<TrueNasApiClient>());
      },
    );

    group('clearAllForTesting', () {
      test('closes every client and resets manager state', () async {
        await manager.getClient(testServer1);
        await manager.getClient(testServer2);
        expect(manager.getClientCount(), 2);

        await manager.clearAllForTesting();

        expect(manager.getClientCount(), 0);
        expect(manager.getActiveServerIds(), isEmpty);
        expect(manager.getRefCounts(), isEmpty);
      });

      test('is safe to call with nothing to clear', () async {
        await expectLater(manager.clearAllForTesting(), completes);
        expect(manager.getClientCount(), 0);
      });
    });
  });
}
