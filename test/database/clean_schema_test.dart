import 'package:flutter_test/flutter_test.dart';
import 'package:truenas_manager/models/nas_server.dart' as models;
import 'package:truenas_manager/services/database.dart';
import 'package:drift/native.dart';

void main() {
  group('Clean Schema v3 Tests', () {
    test('should create database with schema v3 and nullable ports', () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());

      // Verify schema version is 3 (secure storage implementation)
      expect(database.schemaVersion, 3);

      // Test inserting server with null port
      final serverWithoutPort = models.NasServer.create(
        name: 'Server without Port',
        host: 'test.example.com',
        port: null,
        username: 'admin',
        password: 'password',
        useHttps: true,
      );

      await database.insertServer(serverWithoutPort);

      // Verify it was saved correctly
      final savedServer = await database.getServer(serverWithoutPort.id);
      expect(savedServer?.port, null);

      // Test inserting server with port
      final serverWithPort = models.NasServer.create(
        name: 'Server with Port',
        host: 'test2.example.com',
        port: 8443,
        username: 'admin',
        password: 'password',
        useHttps: true,
      );

      await database.insertServer(serverWithPort);

      // Test updating port to null
      final updatedServer = serverWithPort.copyWith(
        port: null,
        clearPort: true,
      );

      await database.updateServer(updatedServer);

      final finalServer = await database.getServer(serverWithPort.id);
      expect(finalServer?.port, null);

      // Verify all servers
      final allServers = await database.getAllServers();
      expect(allServers.length, 2);
      expect(allServers.every((s) => s.port == null), true);

      await database.close();
    });

    test('should handle all field combinations correctly', () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());

      // Test server with all nullable fields as null
      final minimalServer = models.NasServer.create(
        name: 'Minimal Server',
        host: 'minimal.example.com',
        port: null,
        username: 'admin',
        password: 'password',
        useHttps: true,
      );

      await database.insertServer(minimalServer);

      // Test server with all fields populated
      final fullServer = models.NasServer.create(
        name: 'Full Server',
        host: 'full.example.com',
        localUrl: 'http://192.168.1.100:8080',
        trustedWifiSsids: ['HomeWiFi', 'OfficeWiFi'],
        port: 9000,
        username: 'admin',
        password: 'password',
        useHttps: false,
        allowUntrustedCertificates: true,
      );

      await database.insertServer(fullServer);

      // Verify both servers were saved correctly
      final servers = await database.getAllServers();
      expect(servers.length, 2);

      final minimal = servers.firstWhere((s) => s.name == 'Minimal Server');
      expect(minimal.port, null);
      expect(minimal.localUrl, null);
      expect(minimal.trustedWifiSsids, isEmpty);

      final full = servers.firstWhere((s) => s.name == 'Full Server');
      expect(full.port, 9000);
      expect(full.localUrl, 'http://192.168.1.100:8080');
      expect(full.trustedWifiSsids, ['HomeWiFi', 'OfficeWiFi']);
      expect(full.allowUntrustedCertificates, true);

      await database.close();
    });
  });
}
