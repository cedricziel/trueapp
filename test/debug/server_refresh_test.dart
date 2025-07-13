import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart' as models;
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/services/sqlite_server_repository.dart';
import 'package:truenas_native_plugins/truenas_native_plugins.dart'
    show MockKeychainService;
import 'package:drift/native.dart';

void main() {
  group('Server Provider Refresh Test', () {
    late AppDatabase database;
    late ServerProvider serverProvider;
    late UnifiedServerService unifiedServerService;

    setUp(() async {
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
      await database.close();
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
      bool listenerCalled = false;

      // Create a simple, isolated listener that won't cause side effects
      void testListener() {
        listenerCalled = true;
      }

      // Add a listener to the provider
      serverProvider.addListener(testListener);

      try {
        // Create and add a server
        final testServer = models.NasServer.create(
          name: 'Test Server',
          host: 'test.example.com',
          port: 443,
          username: 'admin',
          password: 'password',
          useHttps: true,
        );

        await database.insertServer(testServer);
        listenerCalled = false; // Reset flag after initial setup

        // Update the server
        final updatedServer = testServer.copyWith(name: 'Updated Name');
        await serverProvider.updateServer(updatedServer);

        // Verify listeners were notified
        expect(listenerCalled, true);
      } finally {
        // Clean up listener to prevent issues
        serverProvider.removeListener(testListener);
      }
    });
  });
}
