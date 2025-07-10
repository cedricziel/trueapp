import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/providers/server_provider.dart';
import 'package:truenas_manager/services/database.dart';

void main() {
  late AppDatabase database;
  late ServerProvider serverProvider;
  late NasServer testServer;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    serverProvider = ServerProvider(database);

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

    await serverProvider.addServer(testServer);
  });

  tearDown(() async {
    await database.close();
  });

  group('ServerProvider', () {
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

      // Update the server directly in database (simulating external update)
      final updatedServer = testServer.copyWith(
        name: 'Externally Updated Server',
        port: 8080,
        useHttps: false,
      );
      await database.updateServer(updatedServer);

      // Refresh the selected server
      await serverProvider.refreshSelectedServer();

      // Verify the selected server is refreshed with new data
      expect(serverProvider.selectedServer?.name, 'Externally Updated Server');
      expect(serverProvider.selectedServer?.port, 8080);
      expect(serverProvider.selectedServer?.useHttps, isFalse);
      expect(serverProvider.selectedServer?.id, originalServer?.id);
    });

    test('should handle refreshing when no server is selected', () async {
      // Ensure no server is selected
      expect(serverProvider.selectedServer, isNull);

      // Refresh should not throw an error
      await serverProvider.refreshSelectedServer();
      expect(serverProvider.selectedServer, isNull);
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

    test('should update server and maintain consistency', () async {
      // Add another server
      final server2 = NasServer.create(
        name: 'Server 2',
        host: '192.168.1.101',
        username: 'admin',
        password: 'password',
      );
      await serverProvider.addServer(server2);

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

      // Verify the selected server is updated
      expect(serverProvider.selectedServer?.name, 'Updated Test Server');
      expect(serverProvider.selectedServer?.host, '192.168.1.150');
      expect(
        serverProvider.selectedServer?.localUrl,
        'http://192.168.1.250:9000',
      );
      expect(
        serverProvider.selectedServer?.trustedWifiSsids,
        contains('UpdatedWiFi'),
      );
      expect(
        serverProvider.selectedServer?.trustedWifiSsids,
        isNot(contains('HomeWiFi')),
      );

      // Verify the servers list is also updated
      final servers = serverProvider.servers;
      final updatedServerInList = servers.firstWhere(
        (s) => s.id == testServer.id,
      );
      expect(updatedServerInList.name, 'Updated Test Server');
      expect(updatedServerInList.host, '192.168.1.150');
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
      expect(selected.password, 'newpassword');
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
    test('should persist server updates to database', () async {
      // Update server through provider
      final updatedServer = testServer.copyWith(
        name: 'Database Test Server',
        allowUntrustedCertificates: true,
        trustedWifiSsids: ['DatabaseWiFi'],
      );

      await serverProvider.updateServer(updatedServer);

      // Verify the update was persisted by reading directly from database
      final serverFromDb = await database.getServer(testServer.id);
      expect(serverFromDb, isNotNull);
      expect(serverFromDb!.name, 'Database Test Server');
      expect(serverFromDb.allowUntrustedCertificates, isTrue);
      expect(serverFromDb.trustedWifiSsids, contains('DatabaseWiFi'));
    });

    test('should handle database errors gracefully', () async {
      // Attempt to update server with invalid data (simulate database constraint error)
      final updatedServer = testServer.copyWith(name: 'Error Test Server');

      // Close database to force an error
      await database.close();

      // This should throw an error since the database is closed
      expect(
        () async => await serverProvider.updateServer(updatedServer),
        throwsA(isA<StateError>()),
      );
    });
  });
}
