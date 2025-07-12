import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/api_client_manager.dart';
import 'package:truehub/services/truenas_api_client.dart';

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
  });
}
