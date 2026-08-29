import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart' as models;
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/services/sqlite_server_repository.dart';
import 'package:truenas_native_plugins/truenas_native_plugins.dart'
    show MockKeychainService;
import 'package:drift/native.dart';
import '../helpers/test_providers.dart';

void main() {
  group('Server Provider Refresh Test', () {
    late AppDatabase database;
    late ServerProvider serverProvider;
    late UnifiedServerService unifiedServerService;
    late Timer timeout;

    setUp(() async {
      // Clean up any leftover state first
      await TestProviders.cleanupTestEnvironment();

      // Set up test environment with mocks
      TestProviders.setupTestEnvironment();

      timeout = Timer(
        const Duration(seconds: 10),
        () => fail(
          'Test timed out, likely due to hanging database operations or network calls',
        ),
      );

      // Create a unique database instance for complete isolation
      database = AppDatabase.forTesting(NativeDatabase.memory());

      // Create real service with SQLite repository and mock keychain
      final sqliteRepository = SqliteServerRepository(database);
      final mockKeychain = MockKeychainService();
      unifiedServerService = UnifiedServerService(
        repository: sqliteRepository,
        keychain: mockKeychain,
      );
      await unifiedServerService.initialize();

      serverProvider = ServerProvider(unifiedServerService);
    });

    tearDown(() async {
      // Ensure complete cleanup in reverse order of creation
      serverProvider.dispose();
      unifiedServerService.dispose();
      await database.close();

      // Clear any static state that might interfere with other tests
      await TestProviders.cleanupTestEnvironment();

      timeout.cancel();
    });

    test('should refresh selectedServer when server is updated', () async {
      // Create a test server
      final testServer = models.NasServer.create(
        name: 'Original Name',
        host: 'test.example.com',
        port: 443,
        username: 'admin',
        password: 'password',
        useHttps: true,
      );

      await database.insertServer(testServer);
      await serverProvider.loadServersAndAutoSelect();

      // Select the server
      serverProvider.selectServer(testServer);
      expect(serverProvider.selectedServer?.name, 'Original Name');
      expect(serverProvider.selectedServer?.host, 'test.example.com');

      // Update the server through the provider (simulates edit screen save)
      final updatedServer = testServer.copyWith(
        name: 'Updated Name',
        host: 'updated.example.com',
      );

      await serverProvider.updateServer(updatedServer);

      // Verify the selectedServer was refreshed with new data
      expect(serverProvider.selectedServer?.name, 'Updated Name');
      expect(serverProvider.selectedServer?.host, 'updated.example.com');

      // Clean up
      serverProvider.clearSelectedServer();
    });

    test('should update server in database correctly', () async {
      // Create a test server with null port
      final testServer = models.NasServer.create(
        name: 'Test Server',
        host: 'test.example.com',
        port: null, // Test nullable port
        username: 'admin',
        password: 'password',
        useHttps: true,
      );

      await database.insertServer(testServer);

      // Update the server with new values including clearing port
      final updatedServer = testServer.copyWith(
        name: 'Updated Server',
        port: 8443,
      );

      await serverProvider.updateServer(updatedServer);

      // Verify the update worked in the database
      final savedServer = await database.getServer(testServer.id);
      expect(savedServer?.name, 'Updated Server');
      expect(savedServer?.port, 8443);

      // Now test clearing the port
      final clearedServer = savedServer!.copyWith(port: null, clearPort: true);

      await serverProvider.updateServer(clearedServer);

      // Verify port was cleared
      final finalServer = await database.getServer(testServer.id);
      expect(finalServer?.port, null);
    });

    test('should notify listeners when server is updated', () async {
      // This test was hanging when running with other tests due to authentication
      // triggering during updateServer. Simplified to test the core functionality.

      int notificationCount = 0;

      // Add a listener that counts notifications
      void countingListener() {
        notificationCount++;
      }

      serverProvider.addListener(countingListener);

      try {
        // Create a test server directly in database
        final testServer = models.NasServer.create(
          name: 'Listener Test Server',
          host: 'listener.test.com',
          port: 443,
          username: 'admin',
          password: 'password',
          useHttps: true,
        );

        await database.insertServer(testServer);

        // Select the server first to avoid authentication during update
        serverProvider.selectServer(testServer);

        // Reset counter after selection
        notificationCount = 0;

        // Update the server - this should trigger listener notification
        final updatedServer = testServer.copyWith(
          name: 'Updated Listener Server',
        );
        await serverProvider.updateServer(updatedServer);

        // Verify listeners were notified at least once
        expect(
          notificationCount,
          greaterThan(0),
          reason: 'Listener should be notified when server is updated',
        );
      } finally {
        // Always clean up listener
        serverProvider.removeListener(countingListener);

        // Clear selected server to prevent lingering API clients
        serverProvider.clearSelectedServer();

        // Ensure API clients are cleaned up
        await TestProviders.cleanupTestEnvironment();
      }
    }, timeout: const Timeout(Duration(seconds: 5)));
  });
}
