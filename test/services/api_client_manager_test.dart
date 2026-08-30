import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/connection_error.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/api_client_manager.dart';
import 'package:truehub/services/truenas_api_client.dart';

import '../helpers/fake_telemetry_service.dart';
import '../helpers/mock_api_client_manager.dart';

void main() {
  group('ApiClientManager', () {
    late NasServer testServer1;
    late NasServer testServer2;

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

      // Clean up any existing clients before each test
      ApiClientManager.closeAllClients();
    });

    tearDown(() async {
      // Clean up after each test
      await ApiClientManager.closeAllClients();
    });

    test('should create and reuse client for same server', () async {
      // First request for client
      final client1 = await ApiClientManager.getClient(testServer1);
      expect(client1, isA<TrueNasApiClient>());
      expect(ApiClientManager.hasClient(testServer1.id), isTrue);
      expect(ApiClientManager.getClientCount(), equals(1));

      // Second request for same server should return same client
      final client2 = await ApiClientManager.getClient(testServer1);
      expect(client2, same(client1));
      expect(ApiClientManager.getClientCount(), equals(1));

      // Ref count should be 2
      final refCounts = ApiClientManager.getRefCounts();
      expect(refCounts[testServer1.id], equals(2));
    });

    test('should create separate clients for different servers', () async {
      final client1 = await ApiClientManager.getClient(testServer1);
      final client2 = await ApiClientManager.getClient(testServer2);

      expect(client1, isA<TrueNasApiClient>());
      expect(client2, isA<TrueNasApiClient>());
      expect(client1, isNot(same(client2)));
      expect(ApiClientManager.getClientCount(), equals(2));

      final activeServerIds = ApiClientManager.getActiveServerIds();
      expect(activeServerIds, containsAll([testServer1.id, testServer2.id]));
    });

    test('should maintain reference count correctly', () async {
      // Get client twice
      await ApiClientManager.getClient(testServer1);
      await ApiClientManager.getClient(testServer1);

      var refCounts = ApiClientManager.getRefCounts();
      expect(refCounts[testServer1.id], equals(2));

      // Release once
      await ApiClientManager.releaseClient(testServer1.id);
      refCounts = ApiClientManager.getRefCounts();
      expect(refCounts[testServer1.id], equals(1));
      expect(ApiClientManager.hasClient(testServer1.id), isTrue);

      // Release again - should close client
      await ApiClientManager.releaseClient(testServer1.id);
      expect(ApiClientManager.hasClient(testServer1.id), isFalse);
      expect(ApiClientManager.getClientCount(), equals(0));
    });

    test('should force close client regardless of ref count', () async {
      // Get client multiple times
      await ApiClientManager.getClient(testServer1);
      await ApiClientManager.getClient(testServer1);
      await ApiClientManager.getClient(testServer1);

      var refCounts = ApiClientManager.getRefCounts();
      expect(refCounts[testServer1.id], equals(3));

      // Force close should close immediately
      await ApiClientManager.closeClient(testServer1.id);
      expect(ApiClientManager.hasClient(testServer1.id), isFalse);
      expect(ApiClientManager.getClientCount(), equals(0));
    });

    test('should close all clients', () async {
      await ApiClientManager.getClient(testServer1);
      await ApiClientManager.getClient(testServer2);

      expect(ApiClientManager.getClientCount(), equals(2));

      await ApiClientManager.closeAllClients();

      expect(ApiClientManager.getClientCount(), equals(0));
      expect(ApiClientManager.hasClient(testServer1.id), isFalse);
      expect(ApiClientManager.hasClient(testServer2.id), isFalse);
    });

    test('should handle release of non-existent client gracefully', () async {
      // Should not throw when releasing non-existent client
      await ApiClientManager.releaseClient('non-existent-id');
      expect(ApiClientManager.getClientCount(), equals(0));
    });

    test('should handle close of non-existent client gracefully', () async {
      // Should not throw when closing non-existent client
      await ApiClientManager.closeClient('non-existent-id');
      expect(ApiClientManager.getClientCount(), equals(0));
    });

    test('should get existing client without increasing ref count', () async {
      await ApiClientManager.getClient(testServer1);

      var refCounts = ApiClientManager.getRefCounts();
      expect(refCounts[testServer1.id], equals(1));

      final existingClient = ApiClientManager.getExistingClient(testServer1.id);
      expect(existingClient, isNotNull);

      // Ref count should remain the same
      refCounts = ApiClientManager.getRefCounts();
      expect(refCounts[testServer1.id], equals(1));
    });

    test('should return null for non-existent client', () async {
      final existingClient = ApiClientManager.getExistingClient(
        'non-existent-id',
      );
      expect(existingClient, isNull);
    });

    group('ensureAllConnectionsAlive', () {
      test('returns an empty map when there are no active clients', () async {
        final failures = await ApiClientManager.ensureAllConnectionsAlive();
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

          await ApiClientManager.getClient(unreachableServer);

          final failures = await ApiClientManager.ensureAllConnectionsAlive()
              .timeout(const Duration(seconds: 20));

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
          expect(ApiClientManager.getActiveServerIds(), isEmpty);
          final failures = await ApiClientManager.ensureAllConnectionsAlive();
          expect(failures, isEmpty);
        },
      );
    });

    group('forceRecreateClient', () {
      test(
        'closes the existing client and returns a fresh one with ref count 1',
        () async {
          final original = await ApiClientManager.getClient(testServer1);
          await ApiClientManager.getClient(testServer1); // ref count -> 2
          expect(ApiClientManager.getRefCounts()[testServer1.id], 2);

          final recreated = await ApiClientManager.forceRecreateClient(
            testServer1,
          );

          expect(recreated, isNot(same(original)));
          expect(ApiClientManager.hasClient(testServer1.id), isTrue);
          expect(ApiClientManager.getRefCounts()[testServer1.id], 1);
        },
      );

      test('works even when there was no existing client to close', () async {
        expect(ApiClientManager.hasClient(testServer1.id), isFalse);

        final client = await ApiClientManager.forceRecreateClient(testServer1);

        expect(client, isA<TrueNasApiClient>());
        expect(ApiClientManager.hasClient(testServer1.id), isTrue);
      });
    });

    group('setConnectionStatusProvider', () {
      test('accepts a null provider without throwing', () {
        expect(
          () => ApiClientManager.setConnectionStatusProvider(null),
          returnsNormally,
        );
      });
    });

    group('setTelemetryService', () {
      test('accepts a null service without throwing', () {
        expect(
          () => ApiClientManager.setTelemetryService(null),
          returnsNormally,
        );
      });

      test('is passed through to clients created afterwards', () async {
        final telemetry = FakeTelemetryService();
        ApiClientManager.setTelemetryService(telemetry);
        addTearDown(() => ApiClientManager.setTelemetryService(null));

        // Nothing observable on ApiClientManagerInterface exposes the
        // telemetry service directly, so this only proves getClient()
        // doesn't blow up with one wired in - TrueNasApiClient's own tests
        // cover the telemetry behaviour itself.
        final client = await ApiClientManager.getClient(testServer1);
        expect(client, isA<TrueNasApiClient>());
      });

      test('static facade delegates to the underlying instance', () {
        final mock = MockApiClientManager();
        ApiClientManager.setInstance(mock);
        addTearDown(() => ApiClientManager.setInstance(null));

        final telemetry = FakeTelemetryService();
        ApiClientManager.setTelemetryService(telemetry);

        expect(mock.methodCalls, contains('setTelemetryService'));
        expect(mock.telemetry, same(telemetry));
      });
    });

    group('clearAllForTesting', () {
      test('closes every client and resets manager state', () async {
        await ApiClientManager.getClient(testServer1);
        await ApiClientManager.getClient(testServer2);
        expect(ApiClientManager.getClientCount(), 2);

        await ApiClientManager.clearAllForTesting();

        expect(ApiClientManager.getClientCount(), 0);
        expect(ApiClientManager.getActiveServerIds(), isEmpty);
        expect(ApiClientManager.getRefCounts(), isEmpty);
      });

      test('is safe to call with nothing to clear', () async {
        await expectLater(ApiClientManager.clearAllForTesting(), completes);
        expect(ApiClientManager.getClientCount(), 0);
      });
    });
  });
}
