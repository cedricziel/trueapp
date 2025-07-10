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

    // STEP 1: Start with a registered server
    testServer = NasServer.create(
      name: 'Original TrueNAS Server',
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

  group('Complete Server Edit Flow - Unit Test', () {
    test(
      'should complete full user journey: Registered Server → Navigate to Edit → Make Changes → Save → Verify Provider Update',
      () async {
        // STEP 1: Verify we have a registered server
        expect(serverProvider.servers.length, 1);
        expect(serverProvider.servers.first.name, 'Original TrueNAS Server');
        expect(serverProvider.servers.first.host, '192.168.1.100');
        expect(
          serverProvider.servers.first.allowUntrustedCertificates,
          isFalse,
        );
        expect(serverProvider.servers.first.trustedWifiSsids, ['HomeWiFi']);

        // STEP 2: User navigates from overview to edit by selecting the server
        // This simulates: Home Screen → Server Detail Screen → Edit Server Screen
        serverProvider.selectServer(testServer);

        // Verify server is selected
        expect(serverProvider.selectedServer, isNotNull);
        expect(serverProvider.selectedServer?.name, 'Original TrueNAS Server');

        // Track provider notifications
        int notificationCount = 0;
        void listener() {
          notificationCount++;
        }

        serverProvider.addListener(listener);

        // STEP 3: User makes changes (simulating what happens in EditServerScreen)
        final updatedServer = testServer.copyWith(
          name: 'Updated TrueNAS Server',
          host: '192.168.1.150',
          localUrl: 'https://192.168.1.250:8443',
          trustedWifiSsids: ['HomeWiFi', 'OfficeWiFi', 'GuestWiFi'],
          port: 8443,
          useHttps: true,
          allowUntrustedCertificates: true,
        );

        // STEP 4: User saves changes (calls serverProvider.updateServer)
        await serverProvider.updateServer(updatedServer);

        // STEP 5: Verify changes bubble up to the provider

        // 5a. Verify selected server is automatically updated
        expect(serverProvider.selectedServer, isNotNull);
        expect(serverProvider.selectedServer?.name, 'Updated TrueNAS Server');
        expect(serverProvider.selectedServer?.host, '192.168.1.150');
        expect(
          serverProvider.selectedServer?.localUrl,
          'https://192.168.1.250:8443',
        );
        expect(serverProvider.selectedServer?.port, 8443);
        expect(serverProvider.selectedServer?.useHttps, isTrue);
        expect(
          serverProvider.selectedServer?.allowUntrustedCertificates,
          isTrue,
        );
        expect(serverProvider.selectedServer?.trustedWifiSsids, [
          'HomeWiFi',
          'OfficeWiFi',
          'GuestWiFi',
        ]);

        // 5b. Verify servers list is updated
        expect(serverProvider.servers.length, 1);
        final updatedServerInList = serverProvider.servers.first;
        expect(updatedServerInList.name, 'Updated TrueNAS Server');
        expect(updatedServerInList.host, '192.168.1.150');
        expect(updatedServerInList.localUrl, 'https://192.168.1.250:8443');
        expect(updatedServerInList.port, 8443);
        expect(updatedServerInList.useHttps, isTrue);
        expect(updatedServerInList.allowUntrustedCertificates, isTrue);
        expect(updatedServerInList.trustedWifiSsids, [
          'HomeWiFi',
          'OfficeWiFi',
          'GuestWiFi',
        ]);

        // 5c. Verify changes are persisted in database
        final serverFromDb = await database.getServer(testServer.id);
        expect(serverFromDb, isNotNull);
        expect(serverFromDb!.name, 'Updated TrueNAS Server');
        expect(serverFromDb.host, '192.168.1.150');
        expect(serverFromDb.localUrl, 'https://192.168.1.250:8443');
        expect(serverFromDb.port, 8443);
        expect(serverFromDb.useHttps, isTrue);
        expect(serverFromDb.allowUntrustedCertificates, isTrue);
        expect(serverFromDb.trustedWifiSsids, [
          'HomeWiFi',
          'OfficeWiFi',
          'GuestWiFi',
        ]);

        // 5d. Verify provider notified listeners of changes
        expect(notificationCount, greaterThan(0));

        // Clean up
        serverProvider.removeListener(listener);
      },
    );

    test('should handle step-by-step field updates correctly', () async {
      // Start with selected server
      serverProvider.selectServer(testServer);

      // Track each individual update
      final updates = <String>[];
      void listener() {
        updates.add(serverProvider.selectedServer?.name ?? 'null');
      }

      serverProvider.addListener(listener);

      // Update 1: Change name only
      await serverProvider.updateServer(
        testServer.copyWith(name: 'Step 1 Update'),
      );
      expect(serverProvider.selectedServer?.name, 'Step 1 Update');
      expect(serverProvider.selectedServer?.host, '192.168.1.100'); // unchanged

      // Update 2: Change host
      await serverProvider.updateServer(
        serverProvider.selectedServer!.copyWith(host: '192.168.1.200'),
      );
      expect(serverProvider.selectedServer?.name, 'Step 1 Update');
      expect(serverProvider.selectedServer?.host, '192.168.1.200');

      // Update 3: Toggle certificate setting
      await serverProvider.updateServer(
        serverProvider.selectedServer!.copyWith(
          allowUntrustedCertificates: true,
        ),
      );
      expect(serverProvider.selectedServer?.allowUntrustedCertificates, isTrue);

      // Update 4: Add WiFi SSIDs
      await serverProvider.updateServer(
        serverProvider.selectedServer!.copyWith(
          trustedWifiSsids: ['HomeWiFi', 'OfficeWiFi', 'CafeWiFi'],
        ),
      );
      expect(serverProvider.selectedServer?.trustedWifiSsids, [
        'HomeWiFi',
        'OfficeWiFi',
        'CafeWiFi',
      ]);

      // Verify final state includes all changes
      expect(serverProvider.selectedServer?.name, 'Step 1 Update');
      expect(serverProvider.selectedServer?.host, '192.168.1.200');
      expect(serverProvider.selectedServer?.allowUntrustedCertificates, isTrue);
      expect(serverProvider.selectedServer?.trustedWifiSsids, [
        'HomeWiFi',
        'OfficeWiFi',
        'CafeWiFi',
      ]);

      // Verify all updates triggered notifications
      expect(updates.length, greaterThan(3));

      serverProvider.removeListener(listener);
    });

    test('should verify edit cancellation scenario', () async {
      serverProvider.selectServer(testServer);

      // Store original state
      final originalName = serverProvider.selectedServer!.name;
      final originalHost = serverProvider.selectedServer!.host;
      final originalCerts =
          serverProvider.selectedServer!.allowUntrustedCertificates;

      // Simulate user making changes but then cancelling
      // (In real UI, this would be discarding the form data)
      // The provider should remain unchanged since updateServer is never called

      // Verify provider state is unchanged
      expect(serverProvider.selectedServer?.name, originalName);
      expect(serverProvider.selectedServer?.host, originalHost);
      expect(
        serverProvider.selectedServer?.allowUntrustedCertificates,
        originalCerts,
      );

      // Verify database is unchanged
      final serverFromDb = await database.getServer(testServer.id);
      expect(serverFromDb!.name, originalName);
      expect(serverFromDb.host, originalHost);
      expect(serverFromDb.allowUntrustedCertificates, originalCerts);
    });

    test('should handle multiple servers correctly', () async {
      // Add a second server
      final server2 = NasServer.create(
        name: 'Second Server',
        host: '192.168.1.101',
        username: 'admin2',
        password: 'password2',
      );
      await serverProvider.addServer(server2);

      // Select first server and update it
      serverProvider.selectServer(testServer);
      await serverProvider.updateServer(
        testServer.copyWith(name: 'Updated First Server'),
      );

      // Verify only the selected server is affected
      expect(serverProvider.selectedServer?.name, 'Updated First Server');
      expect(serverProvider.servers.length, 2);

      final updatedFirstServer = serverProvider.servers.firstWhere(
        (s) => s.id == testServer.id,
      );
      final unchangedSecondServer = serverProvider.servers.firstWhere(
        (s) => s.id == server2.id,
      );

      expect(updatedFirstServer.name, 'Updated First Server');
      expect(unchangedSecondServer.name, 'Second Server');

      // Switch to second server and update it
      serverProvider.selectServer(server2);
      await serverProvider.updateServer(
        server2.copyWith(name: 'Updated Second Server'),
      );

      // Verify the selected server changed and was updated
      expect(serverProvider.selectedServer?.name, 'Updated Second Server');
      expect(serverProvider.selectedServer?.id, server2.id);

      // Verify both servers have their updates
      final finalFirstServer = serverProvider.servers.firstWhere(
        (s) => s.id == testServer.id,
      );
      final finalSecondServer = serverProvider.servers.firstWhere(
        (s) => s.id == server2.id,
      );

      expect(finalFirstServer.name, 'Updated First Server');
      expect(finalSecondServer.name, 'Updated Second Server');
    });

    test('should demonstrate URL composition with custom ports', () async {
      serverProvider.selectServer(testServer);

      // Test custom HTTPS port
      await serverProvider.updateServer(
        testServer.copyWith(useHttps: true, port: 8443),
      );

      expect(serverProvider.selectedServer?.useHttps, isTrue);
      expect(serverProvider.selectedServer?.port, 8443);
      expect(
        serverProvider.selectedServer?.baseUrl,
        'https://192.168.1.100:8443',
      );

      // Test custom HTTP port
      await serverProvider.updateServer(
        serverProvider.selectedServer!.copyWith(useHttps: false, port: 8080),
      );

      expect(serverProvider.selectedServer?.useHttps, isFalse);
      expect(serverProvider.selectedServer?.port, 8080);
      expect(
        serverProvider.selectedServer?.baseUrl,
        'http://192.168.1.100:8080',
      );
    });
  });
}
