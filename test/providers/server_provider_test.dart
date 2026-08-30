import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/services/api_client_manager.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/fake_api_client.dart';
import '../helpers/test_providers.dart';

void main() {
  late AppDatabase database;
  late ServerProvider serverProvider;
  late UnifiedServerService mockServerService;
  late NasServer testServer;

  setUp(() async {
    // Clean up any leftover state and set up test environment
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();

    // Create a database instance for this test
    database = AppDatabase.forTesting(NativeDatabase.memory());

    // Create a shared mock service instance with the database
    mockServerService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    serverProvider = ServerProvider(mockServerService);

    testServer = NasServer.create(
      name: 'Test Server',
      host: '192.168.1.100',
      localUrl: 'http://192.168.1.200:8080',
      trustedWifiSsids: ['HomeWiFi'],
      port: 443,
      username: 'admin',
      password: 'password',
      useHttps: true,
      allowUntrustedCertificates: false,
    );

    await serverProvider.addServer(testServer, 'password');
  });

  tearDown(() async {
    mockServerService.dispose();
    await database.close();

    // Clear any static state that might interfere with other tests
    await TestProviders.cleanupTestEnvironment();
  });

  group('ServerProvider', () {
    test('should set and get default server', () async {
      // Initially no default server
      expect(serverProvider.defaultServer, isNull);

      // Set default server
      await serverProvider.setDefaultServer(testServer.id);
      await serverProvider.loadServersAndAutoSelect();

      // Verify default server is set
      final defaultServer = serverProvider.defaultServer;
      expect(defaultServer, isNotNull);
      expect(defaultServer?.id, testServer.id);
      expect(defaultServer?.isDefault, isTrue);
    });

    test('should clear default server', () async {
      // Set server as default first
      await serverProvider.setDefaultServer(testServer.id);
      await serverProvider.loadServersAndAutoSelect();
      expect(serverProvider.defaultServer, isNotNull);

      // Clear default server
      await serverProvider.clearDefaultServer();

      // Reload servers to refresh the provider state after clearing default
      await serverProvider.loadServersAndAutoSelect();

      // Verify no default server (the provider may still auto-select the single server,
      // but it should not be marked as default in the database)
      final servers = serverProvider.servers;
      final defaultServers = servers.where((s) => s.isDefault).toList();
      expect(
        defaultServers,
        isEmpty,
        reason: 'No servers should be marked as default',
      );
    });

    test('should auto-select single server', () async {
      // Since we have one test server from setUp, it should be auto-selected
      // Auto-select should pick the only server
      await serverProvider.loadServersAndAutoSelect();
      expect(serverProvider.selectedServer, isNotNull);
      expect(serverProvider.selectedServer?.id, testServer.id);
    });

    test(
      'should handle default server operations with multiple servers',
      () async {
        // Add a second server
        final secondServer = NasServer.create(
          name: 'Second Server',
          host: '192.168.1.101',
          username: 'admin',
          password: 'password',
        );
        await serverProvider.addServer(secondServer, 'password2');

        // Set second server as default - should not throw
        await serverProvider.setDefaultServer(secondServer.id);

        // Load servers and auto-select - should not throw
        await serverProvider.loadServersAndAutoSelect();
        expect(serverProvider.selectedServer, isNotNull);

        // Provider should have multiple servers
        expect(serverProvider.servers.length, greaterThanOrEqualTo(2));
      },
    );

    test('should update server and refresh selected server', () async {
      // Set the test server as active
      serverProvider.selectServer(testServer);
      expect(serverProvider.selectedServer?.name, 'Test Server');

      // Update the server
      final updatedServer = testServer.copyWith(
        name: 'Updated Server Name',
        allowUntrustedCertificates: true,
        trustedWifiSsids: ['NewWiFi', 'OfficeWiFi'],
      );

      await serverProvider.updateServer(updatedServer);

      // Verify the selected server is refreshed
      expect(serverProvider.selectedServer?.name, 'Updated Server Name');
      expect(serverProvider.selectedServer?.allowUntrustedCertificates, isTrue);
      expect(
        serverProvider.selectedServer?.trustedWifiSsids,
        contains('NewWiFi'),
      );
      expect(
        serverProvider.selectedServer?.trustedWifiSsids,
        contains('OfficeWiFi'),
      );
    });

    test('should refresh selected server after update', () async {
      // Set the test server as active
      serverProvider.selectServer(testServer);
      final originalServer = serverProvider.selectedServer;

      // Update the server directly in mock service (simulating external update)
      final updatedServer = testServer.copyWith(
        name: 'Externally Updated Server',
        port: 8080,
        useHttps: false,
      );
      await mockServerService.updateServerConfig(updatedServer);

      // Refresh the selected server
      await serverProvider.refreshSelectedServer();

      // Verify the selected server is refreshed with new data
      // Note: The refreshSelectedServer calls getServer which should return the updated server
      final refreshedServer = serverProvider.selectedServer;
      expect(refreshedServer, isNotNull);
      expect(refreshedServer?.id, originalServer?.id);
      // The server should be updated by the refresh operation
      expect(refreshedServer?.name, 'Externally Updated Server');
    });

    test('should handle refreshing when no server is selected', () async {
      // Clear any selected server first
      serverProvider.clearSelectedServer();

      // Refresh should not throw an error even when no server is selected
      await serverProvider.refreshSelectedServer();

      // This test verifies the method handles null selectedServer gracefully
      // (Auto-selection might still occur due to stream updates)
    });

    test('should handle refreshing when selected server is deleted', () async {
      // Set the test server as active
      serverProvider.selectServer(testServer);
      expect(serverProvider.selectedServer, isNotNull);

      // Delete the server through the provider (which handles selected server cleanup)
      await serverProvider.deleteServer(testServer.id);

      // Selected server should be null after deletion
      expect(serverProvider.selectedServer, isNull);
    });

    test(
      'should close the cached API client when a server is deleted',
      () async {
        // Select the server first: `selectServer` unconditionally releases
        // whatever client the *previous* selection held (see its "Release
        // previous client if any" step), including when reselecting the
        // already-selected server. Seeding the mock client before this call
        // would have it wiped out by that release before the assertion below
        // ever sees it.
        await serverProvider.selectServer(testServer);

        // Seed the mock manager with a cached client for this server, the way
        // a real `getClient()` call from `selectServer` would. The mock's
        // `getClient` does not itself register a client on a cache miss, so
        // without this the `hasClient` assertion below would pass trivially
        // regardless of whether `deleteServer` actually closes the client.
        TestProviders.mockApiClientManager.addMockClient(
          testServer.id,
          FakeApiClient(),
        );
        expect(ApiClientManager.hasClient(testServer.id), isTrue);

        // Deleting the server must not leave a stale client (and its
        // websocket/keepalive timer) behind for a server that no longer exists.
        await serverProvider.deleteServer(testServer.id);

        expect(ApiClientManager.hasClient(testServer.id), isFalse);

        // Restore the test server for other tests relying on setUp state.
        await serverProvider.addServer(testServer, 'password');
      },
    );

    test('should update server and maintain consistency', () async {
      // Add another server
      final server2 = NasServer.create(
        name: 'Server 2',
        host: '192.168.1.101',
        username: 'admin',
        password: 'password',
      );
      await serverProvider.addServer(server2, 'password2');

      // Set first server as active
      serverProvider.selectServer(testServer);
      expect(serverProvider.selectedServer?.name, 'Test Server');

      // Update the first server
      final updatedServer = testServer.copyWith(
        name: 'Updated Test Server',
        host: '192.168.1.150',
        localUrl: 'http://192.168.1.250:9000',
        trustedWifiSsids: ['UpdatedWiFi'],
      );

      await serverProvider.updateServer(updatedServer);

      // Verify the update was successful by checking if servers list contains the update
      final servers = serverProvider.servers;
      final updatedServerInList = servers.firstWhere(
        (s) => s.id == testServer.id,
      );
      expect(updatedServerInList.name, 'Updated Test Server');
      expect(updatedServerInList.host, '192.168.1.150');

      // Verify selected server is not null (the specific values may vary due to authentication flow)
      expect(serverProvider.selectedServer, isNotNull);
      expect(serverProvider.selectedServer?.id, testServer.id);
    });

    test('should handle updating server with all new fields', () async {
      // Set the test server as active
      serverProvider.selectServer(testServer);

      // Update server with all possible changes
      final updatedServer = testServer.copyWith(
        name: 'Completely Updated Server',
        host: 'new.example.com',
        localUrl: 'https://local.example.com:8443',
        trustedWifiSsids: ['WiFi1', 'WiFi2', 'WiFi3'],
        port: 8443,
        username: 'newuser',
        password: 'newpassword',
        useHttps: true,
        allowUntrustedCertificates: true,
      );

      await serverProvider.updateServer(updatedServer);

      // Verify all fields are updated
      final selected = serverProvider.selectedServer!;
      expect(selected.name, 'Completely Updated Server');
      expect(selected.host, 'new.example.com');
      expect(selected.localUrl, 'https://local.example.com:8443');
      expect(selected.trustedWifiSsids, ['WiFi1', 'WiFi2', 'WiFi3']);
      expect(selected.port, 8443);
      expect(selected.username, 'newuser');
      // Password is stored in keychain, not in the server object
      // expect(selected.password, 'newpassword');
      expect(selected.useHttps, isTrue);
      expect(selected.allowUntrustedCertificates, isTrue);
    });

    test('should notify listeners when server is updated', () async {
      // Set the test server as active
      serverProvider.selectServer(testServer);

      int notificationCount = 0;
      serverProvider.addListener(() {
        notificationCount++;
      });

      // Update the server
      final updatedServer = testServer.copyWith(
        name: 'Notification Test Server',
      );
      await serverProvider.updateServer(updatedServer);

      // Verify listeners were notified
      expect(notificationCount, greaterThan(0));
    });

    test('should handle concurrent updates correctly', () async {
      // Set the test server as active
      serverProvider.selectServer(testServer);

      // Simulate concurrent updates
      final futures = <Future<void>>[];

      for (int i = 0; i < 5; i++) {
        futures.add(
          serverProvider.updateServer(
            testServer.copyWith(name: 'Concurrent Update $i'),
          ),
        );
      }

      // Wait for all updates to complete
      await Future.wait(futures);

      // Verify server was updated (the last update should win)
      final selected = serverProvider.selectedServer!;
      expect(selected.name, startsWith('Concurrent Update'));
    });
  });

  group('Database Integration', () {
    test('should persist server updates to service', () async {
      // Select the test server first so we have something to update
      serverProvider.selectServer(testServer);

      // Update server through provider
      final updatedServer = testServer.copyWith(
        name: 'Database Test Server',
        allowUntrustedCertificates: true,
        trustedWifiSsids: ['DatabaseWiFi'],
      );

      await serverProvider.updateServer(updatedServer);

      // Verify the update was persisted by reading directly from mock service
      final serverFromService = await mockServerService.getServer(
        testServer.id,
      );
      expect(serverFromService, isNotNull);
      expect(serverFromService!.name, 'Database Test Server');
      expect(serverFromService.allowUntrustedCertificates, isTrue);
      expect(serverFromService.trustedWifiSsids, contains('DatabaseWiFi'));
    });

    test('should handle service errors gracefully', () async {
      // Select the test server first so we have something to update
      serverProvider.selectServer(testServer);

      // This test would need a more sophisticated mock that can simulate failures
      // For now, we'll just verify the provider doesn't crash with valid operations
      final updatedServer = testServer.copyWith(name: 'Error Test Server');

      // Should complete without throwing
      await serverProvider.updateServer(updatedServer);

      // Verify the update succeeded by checking the service directly
      final serverFromService = await mockServerService.getServer(
        testServer.id,
      );
      expect(serverFromService, isNotNull);
      expect(serverFromService!.name, 'Error Test Server');
    });
  });

  group('Additional Coverage Tests', () {
    test(
      'isLoadingServers flips to false once the initial load completes',
      () async {
        final freshProvider = ServerProvider(mockServerService);
        addTearDown(freshProvider.dispose);

        expect(freshProvider.isLoadingServers, isTrue);

        await freshProvider.loadServersAndAutoSelect();

        expect(freshProvider.isLoadingServers, isFalse);
      },
    );

    test('should handle authentication state changes', () async {
      // Test authentication stream
      expect(
        serverProvider.authenticationStream,
        isA<Stream<AuthenticationStatus>>(),
      );

      // Test current auth status
      final authStatus = serverProvider.currentAuthStatus;
      expect(authStatus.state, isA<AuthenticationState>());

      // Test legacy getters
      expect(serverProvider.authState, isA<AuthenticationState>());
      expect(serverProvider.isAuthenticated, isA<bool>());
      expect(serverProvider.requiresAuthentication, isA<bool>());
      expect(serverProvider.isAuthenticating, isA<bool>());
    });

    test('should handle server health and user info', () async {
      // Test initial state
      expect(serverProvider.serverHealth, isNull);
      expect(serverProvider.isLoadingHealth, isFalse);
      expect(serverProvider.healthError, isNull);
      expect(serverProvider.currentUser, isNull);
      expect(serverProvider.isLoadingUser, isFalse);
      expect(serverProvider.userError, isNull);
    });

    test('should handle server list operations', () async {
      // Test initial server list
      expect(serverProvider.servers, isA<List<NasServer>>());

      // Load servers to ensure provider is in sync with database
      await serverProvider.loadServersAndAutoSelect();

      // We should have 1 server from setUp
      expect(serverProvider.servers.length, 1);

      // Add multiple servers
      final server2 = NasServer.create(
        name: 'Server 2',
        host: '192.168.1.101',
        username: 'admin',
        password: 'password',
      );
      await serverProvider.addServer(server2, 'password2');

      // Wait a bit for the stream to update
      await Future.delayed(const Duration(milliseconds: 100));

      // Reload servers to ensure we have the latest
      await serverProvider.loadServersAndAutoSelect();

      // Now we should have 2 servers
      expect(serverProvider.servers.length, 2);
    });

    test('should handle default server operations', () async {
      // Load servers first to ensure clean state
      await serverProvider.loadServersAndAutoSelect();

      // Initially no default server (even though one is selected)
      expect(serverProvider.defaultServer, isNull);

      // Set default server
      await serverProvider.setDefaultServer(testServer.id);
      await serverProvider.loadServersAndAutoSelect();
      expect(serverProvider.defaultServer, isNotNull);
      expect(serverProvider.defaultServer?.id, testServer.id);

      // Clear default server
      await serverProvider.clearDefaultServer();
      await serverProvider.loadServersAndAutoSelect();

      // After clearing, no server should be marked as default in the database
      // The provider may still have a selected server, but it shouldn't be marked as default
      final servers = serverProvider.servers;
      final defaultServers = servers.where((s) => s.isDefault).toList();
      expect(defaultServers, isEmpty);
    });

    test('should handle server selection and clearing', () async {
      // Clear any existing selection first
      serverProvider.clearSelectedServer();

      // Select server
      serverProvider.selectServer(testServer);
      expect(serverProvider.selectedServer, isNotNull);

      // Clear selected server
      serverProvider.clearSelectedServer();
      // Note: Auto-selection may occur due to server stream updates
      // The important thing is that clearSelectedServer() executes without error
    });

    test('should handle refresh operations', () async {
      // Clear any existing selection first
      serverProvider.clearSelectedServer();

      // Test refresh with no selected server (should not crash)
      await serverProvider.refreshSelectedServer();

      // Select server and refresh
      serverProvider.selectServer(testServer);
      await serverProvider.refreshSelectedServer();
      expect(serverProvider.selectedServer, isNotNull);
    });

    test('should properly dispose resources', () async {
      // Reuse the fixture database rather than opening a second one -
      // each test should own exactly one live database instance.
      final testProvider = await TestProviders.createServerProvider(
        database: database,
      );

      // Should not throw
      testProvider.dispose();
      // Don't close the shared database here - it's managed by tearDown
    });

    test(
      'should not crash when disposed while auto-select/auth is in flight',
      () async {
        // ServerProvider's constructor starts a fire-and-forget auto-select
        // chain (see _initializeProvider) that addServer() does not await.
        // Disposing immediately after addServer(), before that chain settles,
        // used to throw "Cannot add new events after calling close" from
        // _emitAuthStatus once the dangling continuation resumed. Regression
        // coverage for #104.
        final testProvider = await TestProviders.createServerProvider(
          database: database,
        );
        final raceServer = NasServer.create(
          name: 'Race Server',
          host: '192.168.1.101',
          username: 'admin',
          password: 'password',
        );

        await testProvider.addServer(raceServer, 'password');
        testProvider.dispose();

        // Give the dangling auto-select/authenticate continuation a chance
        // to resume and reach _emitAuthStatus - it must no-op instead of
        // throwing.
        await Future<void>.delayed(const Duration(milliseconds: 200));
      },
    );

    test('should handle edge cases in auto-selection', () async {
      // Test auto-selection with clean provider state
      // Clear the existing servers first to test the edge case
      await serverProvider.deleteServer(testServer.id);

      // Auto-select with no servers should not crash
      await serverProvider.loadServersAndAutoSelect();
      expect(serverProvider.selectedServer, isNull);

      // Restore the test server for other tests
      await serverProvider.addServer(testServer, 'password');
    });
  });
}
