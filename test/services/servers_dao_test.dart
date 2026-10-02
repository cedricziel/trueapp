// Tests for [ServersDao] (lib/services/database/servers_dao.dart): server
// rows, the foreign-key anchor, and the default / last-connected state.

import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart' as models;
import 'package:truehub/services/database.dart';

import '../helpers/test_database.dart';

void main() {
  group('NasServers CRUD', () {
    test('getAllServers returns an empty list on a fresh database', () async {
      final database = createTestDatabase();
      expect(await database.serversDao.getAllServers(), isEmpty);
    });

    test('insertServer + getServer round-trips all fields', () async {
      final database = createTestDatabase();
      final server = models.NasServer.create(
        name: 'Tank',
        host: 'tank.example.com',
        localUrl: 'http://192.168.1.5',
        trustedWifiSsids: const ['Home', 'Office'],
        port: 8443,
        username: 'admin',
        password: 'super-secret',
        useHttps: true,
        allowUntrustedCertificates: true,
        isDefault: true,
      );

      await database.serversDao.insertServer(server);
      final fetched = await database.serversDao.getServer(server.id);

      expect(fetched, isNotNull);
      expect(fetched!.id, server.id);
      expect(fetched.name, 'Tank');
      expect(fetched.host, 'tank.example.com');
      expect(fetched.localUrl, 'http://192.168.1.5');
      expect(fetched.trustedWifiSsids, ['Home', 'Office']);
      expect(fetched.port, 8443);
      expect(fetched.username, 'admin');
      // The password never round-trips through the database - it lives only
      // in the keychain, so the mapped model always carries an empty string.
      expect(fetched.password, '');
      expect(fetched.useHttps, isTrue);
      expect(fetched.allowUntrustedCertificates, isTrue);
      expect(fetched.isDefault, isTrue);
      expect(fetched.isActive, isTrue);
    });

    test('getServer returns null for an unknown id', () async {
      final database = createTestDatabase();
      expect(await database.serversDao.getServer('missing'), isNull);
    });

    test('a server with an empty trustedWifiSsids list round-trips', () async {
      final database = createTestDatabase();
      final server = models.NasServer.create(
        name: 'No SSIDs',
        host: 'nossid.example.com',
        port: null,
        username: 'admin',
        password: 'pw',
      );
      await database.serversDao.insertServer(server);

      expect(
        (await database.serversDao.getServer(server.id))?.trustedWifiSsids,
        isEmpty,
      );
    });

    test('updateServer changes stored fields', () async {
      final database = createTestDatabase();
      final server = models.NasServer.create(
        name: 'Original',
        host: 'orig.example.com',
        port: 80,
        username: 'admin',
        password: 'pw',
        useHttps: false,
      );
      await database.serversDao.insertServer(server);

      final updated = server.copyWith(
        name: 'Renamed',
        host: 'renamed.example.com',
        localUrl: 'http://10.0.0.5',
        trustedWifiSsids: const ['NewSSID'],
        port: 443,
        username: 'root',
        useHttps: true,
        allowUntrustedCertificates: true,
        isActive: false,
      );
      await database.serversDao.updateServer(updated);

      final fetched = await database.serversDao.getServer(server.id);
      expect(fetched!.name, 'Renamed');
      expect(fetched.host, 'renamed.example.com');
      expect(fetched.localUrl, 'http://10.0.0.5');
      expect(fetched.trustedWifiSsids, ['NewSSID']);
      expect(fetched.port, 443);
      expect(fetched.username, 'root');
      expect(fetched.useHttps, isTrue);
      expect(fetched.allowUntrustedCertificates, isTrue);
      expect(fetched.isActive, isFalse);
    });

    test('updateServer clearing the port persists null', () async {
      final database = createTestDatabase();
      final server = models.NasServer.create(
        name: 'Ported',
        host: 'ported.example.com',
        port: 9000,
        username: 'admin',
        password: 'pw',
      );
      await database.serversDao.insertServer(server);

      await database.serversDao.updateServer(
        server.copyWith(port: null, clearPort: true),
      );

      expect((await database.serversDao.getServer(server.id))?.port, isNull);
    });

    test('updateServer for an unknown id affects nothing', () async {
      final database = createTestDatabase();
      final phantom = models.NasServer.create(
        name: 'Ghost',
        host: 'ghost.example.com',
        port: null,
        username: 'admin',
        password: 'pw',
      );

      await database.serversDao.updateServer(phantom);

      expect(await database.serversDao.getAllServers(), isEmpty);
    });

    test('deleteServer removes the row', () async {
      final database = createTestDatabase();
      final server = models.NasServer.create(
        name: 'Doomed',
        host: 'doomed.example.com',
        port: null,
        username: 'admin',
        password: 'pw',
      );
      await database.serversDao.insertServer(server);

      await database.serversDao.deleteServer(server.id);

      expect(await database.serversDao.getServer(server.id), isNull);
      expect(await database.serversDao.getAllServers(), isEmpty);
    });

    test('deleteServer for an unknown id does not throw', () async {
      final database = createTestDatabase();
      await database.serversDao.deleteServer('does-not-exist');
      expect(await database.serversDao.getAllServers(), isEmpty);
    });

    test('updateLastConnected stamps the current time', () async {
      final database = createTestDatabase();
      final server = models.NasServer.create(
        name: 'Server',
        host: 'server.example.com',
        port: null,
        username: 'admin',
        password: 'pw',
      );
      await database.serversDao.insertServer(server);
      expect(
        (await database.serversDao.getServer(server.id))?.lastConnected,
        isNull,
      );

      final before = DateTime.now().subtract(const Duration(seconds: 2));
      await database.serversDao.updateLastConnected(server.id);
      final after = DateTime.now().add(const Duration(seconds: 2));

      final lastConnected = (await database.serversDao.getServer(
        server.id,
      ))!.lastConnected!;
      expect(lastConnected.isAfter(before), isTrue);
      expect(lastConnected.isBefore(after), isTrue);
    });

    test('getDefaultServer returns null when no server is default', () async {
      final database = createTestDatabase();
      expect(await database.serversDao.getDefaultServer(), isNull);
    });

    test('setDefaultServer makes exactly one server the default', () async {
      final database = createTestDatabase();
      final first = models.NasServer.create(
        name: 'First',
        host: 'first.example.com',
        port: null,
        username: 'admin',
        password: 'pw',
        isDefault: true,
      );
      final second = models.NasServer.create(
        name: 'Second',
        host: 'second.example.com',
        port: null,
        username: 'admin',
        password: 'pw',
      );
      await database.serversDao.insertServer(first);
      await database.serversDao.insertServer(second);

      expect((await database.serversDao.getDefaultServer())?.id, first.id);

      await database.serversDao.setDefaultServer(second.id);

      expect((await database.serversDao.getDefaultServer())?.id, second.id);
      final defaultCount = (await database.serversDao.getAllServers())
          .where((s) => s.isDefault)
          .length;
      expect(defaultCount, 1);
    });

    test('clearDefaultServer removes the default flag', () async {
      final database = createTestDatabase();
      final server = models.NasServer.create(
        name: 'Default',
        host: 'default.example.com',
        port: null,
        username: 'admin',
        password: 'pw',
        isDefault: true,
      );
      await database.serversDao.insertServer(server);

      await database.serversDao.clearDefaultServer();

      expect(await database.serversDao.getDefaultServer(), isNull);
      expect(
        (await database.serversDao.getServer(server.id))?.isDefault,
        isFalse,
      );
    });
  });

  group('upsertServerAnchor', () {
    test('inserts a row for a server that does not exist yet', () async {
      final database = createTestDatabase();
      final server = models.NasServer.create(
        name: 'CloudKit Only',
        host: 'cloudkit.example.com',
        port: null,
        username: 'admin',
        password: 'irrelevant-for-the-database-layer',
      );

      await database.serversDao.upsertServerAnchor(server);

      final fetched = await database.serversDao.getServer(server.id);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'CloudKit Only');
    });

    test('updates an already-anchored server instead of throwing', () async {
      final database = createTestDatabase();
      final server = models.NasServer.create(
        name: 'Original Name',
        host: 'anchor.example.com',
        port: null,
        username: 'admin',
        password: 'pw',
      );
      await database.serversDao.upsertServerAnchor(server);

      final renamed = server.copyWith(name: 'Renamed');
      await database.serversDao.upsertServerAnchor(renamed);

      final fetched = await database.serversDao.getServer(server.id);
      expect(fetched?.name, 'Renamed');
      expect(await database.serversDao.getAllServers(), hasLength(1));
    });

    test('lets an app config for the anchored server be inserted afterwards, '
        'satisfying the foreign key that a CloudKit-only server would '
        'otherwise violate', () async {
      final database = createTestDatabase();
      final server = models.NasServer.create(
        name: 'CloudKit Only',
        host: 'cloudkit.example.com',
        port: null,
        username: 'admin',
        password: 'pw',
      );

      await database.serversDao.upsertServerAnchor(server);

      final id = await database.appConfigsDao.insertAppConfig(
        AppConfigsCompanion.insert(serverId: server.id, appName: 'ix-app'),
      );

      expect(id, isPositive);
    });
  });
}
