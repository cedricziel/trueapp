// Tests for [AppDatabase] (lib/services/database.dart): the drift-backed
// local store for server metadata and per-server app configuration.
//
// Every test uses `createTestDatabase()` (test/helpers/test_database.dart),
// a private in-memory database closed automatically at the end of the test.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:truehub/models/app_config.dart' as app_models;
import 'package:truehub/models/nas_server.dart' as models;
import 'package:truehub/services/database.dart';

import '../helpers/test_database.dart';

/// Inserts a minimal server and returns its id, so app-config tests have a
/// valid `serverId` foreign key to point at without repeating boilerplate.
Future<String> _seedServer(AppDatabase database, {String? name}) async {
  final server = models.NasServer.create(
    name: name ?? 'Seed Server',
    host: 'seed.example.com',
    port: null,
    username: 'admin',
    password: 'irrelevant-for-the-database-layer',
  );
  await database.insertServer(server);
  return server.id;
}

void main() {
  group('NasServers CRUD', () {
    test('getAllServers returns an empty list on a fresh database', () async {
      final database = createTestDatabase();
      expect(await database.getAllServers(), isEmpty);
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

      await database.insertServer(server);
      final fetched = await database.getServer(server.id);

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
      expect(await database.getServer('missing'), isNull);
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
      await database.insertServer(server);

      expect((await database.getServer(server.id))?.trustedWifiSsids, isEmpty);
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
      await database.insertServer(server);

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
      await database.updateServer(updated);

      final fetched = await database.getServer(server.id);
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
      await database.insertServer(server);

      await database.updateServer(server.copyWith(port: null, clearPort: true));

      expect((await database.getServer(server.id))?.port, isNull);
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

      await database.updateServer(phantom);

      expect(await database.getAllServers(), isEmpty);
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
      await database.insertServer(server);

      await database.deleteServer(server.id);

      expect(await database.getServer(server.id), isNull);
      expect(await database.getAllServers(), isEmpty);
    });

    test('deleteServer for an unknown id does not throw', () async {
      final database = createTestDatabase();
      await database.deleteServer('does-not-exist');
      expect(await database.getAllServers(), isEmpty);
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
      await database.insertServer(server);
      expect((await database.getServer(server.id))?.lastConnected, isNull);

      final before = DateTime.now().subtract(const Duration(seconds: 2));
      await database.updateLastConnected(server.id);
      final after = DateTime.now().add(const Duration(seconds: 2));

      final lastConnected = (await database.getServer(
        server.id,
      ))!.lastConnected!;
      expect(lastConnected.isAfter(before), isTrue);
      expect(lastConnected.isBefore(after), isTrue);
    });

    test('getDefaultServer returns null when no server is default', () async {
      final database = createTestDatabase();
      expect(await database.getDefaultServer(), isNull);
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
      await database.insertServer(first);
      await database.insertServer(second);

      expect((await database.getDefaultServer())?.id, first.id);

      await database.setDefaultServer(second.id);

      expect((await database.getDefaultServer())?.id, second.id);
      final defaultCount = (await database.getAllServers())
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
      await database.insertServer(server);

      await database.clearDefaultServer();

      expect(await database.getDefaultServer(), isNull);
      expect((await database.getServer(server.id))?.isDefault, isFalse);
    });
  });

  group('AppConfigs CRUD', () {
    test('getAppConfigs returns an empty list for an unknown server', () async {
      final database = createTestDatabase();
      expect(await database.getAppConfigs('missing-server'), isEmpty);
    });

    test('insertAppConfig returns the generated row id', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);

      final id = await database.insertAppConfig(
        AppConfigsCompanion.insert(serverId: serverId, appName: 'plex'),
      );

      expect(id, isPositive);
      final configs = await database.getAppConfigs(serverId);
      expect(configs, hasLength(1));
      expect(configs.single.id, id);
      expect(configs.single.appName, 'plex');
    });

    test('getAppConfig finds a row by serverId + appName', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      await database.insertAppConfig(
        AppConfigsCompanion.insert(serverId: serverId, appName: 'sonarr'),
      );

      final found = await database.getAppConfig(serverId, 'sonarr');
      expect(found, isNotNull);
      expect(found!.appName, 'sonarr');

      expect(await database.getAppConfig(serverId, 'radarr'), isNull);
      expect(await database.getAppConfig('other-server', 'sonarr'), isNull);
    });

    test('updateAppConfig changes stored fields', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      final id = await database.insertAppConfig(
        AppConfigsCompanion.insert(serverId: serverId, appName: 'plex'),
      );

      await database.updateAppConfig(
        id,
        const AppConfigsCompanion(
          displayName: Value('Plex Media Server'),
          isEnabled: Value(false),
        ),
      );

      final updated = await database.getAppConfig(serverId, 'plex');
      expect(updated!.displayName, 'Plex Media Server');
      expect(updated.isEnabled, isFalse);
    });

    test('updateAppConfig for an unknown id does not throw', () async {
      final database = createTestDatabase();
      await database.updateAppConfig(
        999999,
        const AppConfigsCompanion(displayName: Value('nope')),
      );
    });

    test('deleteAppConfig removes the row', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      final id = await database.insertAppConfig(
        AppConfigsCompanion.insert(serverId: serverId, appName: 'plex'),
      );

      await database.deleteAppConfig(id);

      expect(await database.getAppConfigs(serverId), isEmpty);
    });

    test('deleteAppConfig for an unknown id does not throw', () async {
      final database = createTestDatabase();
      await database.deleteAppConfig(999999);
    });

    test('deleting a server does NOT cascade-delete its app configs, because '
        "the connection never issues PRAGMA foreign_keys = ON, so SQLite "
        "doesn't enforce the declared onDelete: KeyAction.cascade behavior "
        '(true both here and in production - AppDatabase never sets that '
        'pragma)', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      await database.insertAppConfig(
        AppConfigsCompanion.insert(serverId: serverId, appName: 'plex'),
      );

      await database.deleteServer(serverId);

      // If foreign-key enforcement were active this would be empty -
      // instead the app_configs row is silently orphaned.
      expect(await database.getAppConfigs(serverId), hasLength(1));
    });
  });

  group('Favorite app methods', () {
    test('isAppFavorite is false when no app config exists yet', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      expect(await database.isAppFavorite(serverId, 'plex'), isFalse);
    });

    test('setAppFavorite creates a config when none exists', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);

      await database.setAppFavorite(serverId, 'plex', true);

      expect(await database.isAppFavorite(serverId, 'plex'), isTrue);
      final configs = await database.getAppConfigs(serverId);
      expect(configs, hasLength(1));
      expect(configs.single.appName, 'plex');
    });

    test('setAppFavorite updates an existing config', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      await database.insertAppConfig(
        AppConfigsCompanion.insert(serverId: serverId, appName: 'plex'),
      );

      await database.setAppFavorite(serverId, 'plex', true);
      expect(await database.isAppFavorite(serverId, 'plex'), isTrue);

      await database.setAppFavorite(serverId, 'plex', false);
      expect(await database.isAppFavorite(serverId, 'plex'), isFalse);

      // Still exactly one config row - the second call updated, not inserted.
      expect(await database.getAppConfigs(serverId), hasLength(1));
    });

    test('getFavoriteApps returns only favorites, sorted by appName', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      await database.setAppFavorite(serverId, 'zeta', true);
      await database.setAppFavorite(serverId, 'alpha', true);
      await database.setAppFavorite(serverId, 'not-a-favorite', false);

      final favorites = await database.getFavoriteApps(serverId);

      expect(favorites.map((c) => c.appName), ['alpha', 'zeta']);
    });
  });

  group('AppPortConfigs CRUD', () {
    Future<int> seedAppConfig(AppDatabase database, String serverId) {
      return database.insertAppConfig(
        AppConfigsCompanion.insert(serverId: serverId, appName: 'plex'),
      );
    }

    test('getAppPortConfigs returns an empty list initially', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      final appConfigId = await seedAppConfig(database, serverId);

      expect(await database.getAppPortConfigs(appConfigId), isEmpty);
    });

    test('insertAppPortConfig returns the generated id', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      final appConfigId = await seedAppConfig(database, serverId);

      final id = await database.insertAppPortConfig(
        AppPortConfigsCompanion.insert(
          appConfigId: appConfigId,
          portNumber: 32400,
        ),
      );

      expect(id, isPositive);
      final ports = await database.getAppPortConfigs(appConfigId);
      expect(ports, hasLength(1));
      expect(ports.single.portNumber, 32400);
    });

    test('updateAppPortConfig changes stored fields', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      final appConfigId = await seedAppConfig(database, serverId);
      final id = await database.insertAppPortConfig(
        AppPortConfigsCompanion.insert(
          appConfigId: appConfigId,
          portNumber: 32400,
        ),
      );

      await database.updateAppPortConfig(
        id,
        const AppPortConfigsCompanion(
          serviceName: Value('Plex'),
          isEnabled: Value(false),
        ),
      );

      final updated = (await database.getAppPortConfigs(appConfigId)).single;
      expect(updated.serviceName, 'Plex');
      expect(updated.isEnabled, isFalse);
    });

    test('updateAppPortConfig for an unknown id does not throw', () async {
      final database = createTestDatabase();
      await database.updateAppPortConfig(
        999999,
        const AppPortConfigsCompanion(serviceName: Value('nope')),
      );
    });

    test('deleteAppPortConfig removes the row', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      final appConfigId = await seedAppConfig(database, serverId);
      final id = await database.insertAppPortConfig(
        AppPortConfigsCompanion.insert(
          appConfigId: appConfigId,
          portNumber: 32400,
        ),
      );

      await database.deleteAppPortConfig(id);

      expect(await database.getAppPortConfigs(appConfigId), isEmpty);
    });

    test('deleteAppPortConfig for an unknown id does not throw', () async {
      final database = createTestDatabase();
      await database.deleteAppPortConfig(999999);
    });

    test('setPrimaryPort makes exactly one port primary', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      final appConfigId = await seedAppConfig(database, serverId);
      final firstPort = await database.insertAppPortConfig(
        AppPortConfigsCompanion.insert(
          appConfigId: appConfigId,
          portNumber: 32400,
          isPrimary: const Value(true),
        ),
      );
      final secondPort = await database.insertAppPortConfig(
        AppPortConfigsCompanion.insert(
          appConfigId: appConfigId,
          portNumber: 8080,
        ),
      );

      await database.setPrimaryPort(appConfigId, secondPort);

      final ports = await database.getAppPortConfigs(appConfigId);
      final primary = ports.where((p) => p.isPrimary).toList();
      expect(primary, hasLength(1));
      expect(primary.single.id, secondPort);
      expect(ports.firstWhere((p) => p.id == firstPort).isPrimary, isFalse);
    });

    test(
      'deleting an app config does NOT cascade-delete its port configs, for '
      'the same reason (foreign key enforcement is never turned on)',
      () async {
        final database = createTestDatabase();
        final serverId = await _seedServer(database);
        final appConfigId = await seedAppConfig(database, serverId);
        await database.insertAppPortConfig(
          AppPortConfigsCompanion.insert(
            appConfigId: appConfigId,
            portNumber: 32400,
          ),
        );

        await database.deleteAppConfig(appConfigId);

        expect(await database.getAppPortConfigs(appConfigId), hasLength(1));
      },
    );
  });

  group('getAppConfigsWithPorts', () {
    test('joins app configs with their ports', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      final appConfigId = await database.insertAppConfig(
        AppConfigsCompanion.insert(serverId: serverId, appName: 'plex'),
      );
      await database.insertAppPortConfig(
        AppPortConfigsCompanion.insert(
          appConfigId: appConfigId,
          portNumber: 32400,
          protocol: const Value('https'),
          isPrimary: const Value(true),
        ),
      );

      final rows = await database.getAppConfigsWithPorts(serverId);

      expect(rows, hasLength(1));
      expect(rows.single['app_name'], 'plex');
      expect(rows.single['port_number'], 32400);
      expect(rows.single['protocol'], 'https');
      // is_primary is stored as 0/1 in raw custom-select results.
      expect(rows.single['is_primary'], 1);
    });

    test('left-joins app configs that have no ports at all', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      await database.insertAppConfig(
        AppConfigsCompanion.insert(serverId: serverId, appName: 'sonarr'),
      );

      final rows = await database.getAppConfigsWithPorts(serverId);

      expect(rows, hasLength(1));
      expect(rows.single['app_name'], 'sonarr');
      expect(rows.single['port_id'], isNull);
      expect(rows.single['port_number'], isNull);
    });

    test('returns nothing for a server with no app configs', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      expect(await database.getAppConfigsWithPorts(serverId), isEmpty);
    });
  });

  group('AppConfigData <-> AppConfig model mapping', () {
    test('appConfigToCompanion leaves id absent when the model has none', () {
      final database = createTestDatabase();
      final config = app_models.AppConfig(
        serverId: 'server-1',
        appName: 'plex',
      );

      final companion = database.appConfigToCompanion(config);

      expect(companion.id, const Value.absent());
      expect(companion.serverId.value, 'server-1');
      expect(companion.appName.value, 'plex');
    });

    test('appConfigToCompanion carries an existing id through', () {
      final database = createTestDatabase();
      final config = app_models.AppConfig(
        id: 42,
        serverId: 'server-1',
        appName: 'plex',
      );

      expect(database.appConfigToCompanion(config).id, const Value(42));
    });

    test(
      'appConfigToCompanion JSON-encodes list fields, mapToAppConfig decodes them back',
      () async {
        final database = createTestDatabase();
        final config = app_models.AppConfig(
          serverId: 'server-1',
          appName: 'plex',
          categories: const ['media', 'entertainment'],
          tags: const ['popular'],
          screenshots: const ['https://example.com/1.png'],
          sources: const ['https://example.com/src'],
          maintainersJson: '[{"name":"someone"}]',
          upgradeInfoJson: '{"available":true}',
          usedPortsJson: '[{"port":32400}]',
        );

        final companion = database.appConfigToCompanion(config);
        expect(companion.categories.value, isNotNull);
        expect(companion.categories.value, '["media","entertainment"]');

        final id = await database.insertAppConfig(companion);
        final roundTripped = (await database.getAppConfigs('server-1')).single;
        final mapped = database.mapToAppConfig(roundTripped, const []);

        expect(mapped.id, id);
        expect(mapped.categories, ['media', 'entertainment']);
        expect(mapped.tags, ['popular']);
        expect(mapped.screenshots, ['https://example.com/1.png']);
        expect(mapped.sources, ['https://example.com/src']);
        expect(mapped.maintainersJson, '[{"name":"someone"}]');
        expect(mapped.upgradeInfoJson, '{"available":true}');
        expect(mapped.usedPortsJson, '[{"port":32400}]');
      },
    );

    test(
      'mapToAppConfig leaves list fields null when the row has none set',
      () async {
        final database = createTestDatabase();
        final serverId = await _seedServer(database);
        await database.insertAppConfig(
          AppConfigsCompanion.insert(serverId: serverId, appName: 'plex'),
        );
        final row = (await database.getAppConfigs(serverId)).single;

        final mapped = database.mapToAppConfig(row, const []);

        expect(mapped.categories, isNull);
        expect(mapped.tags, isNull);
        expect(mapped.screenshots, isNull);
        expect(mapped.sources, isNull);
      },
    );

    test('mapToAppPortConfig / appPortConfigToCompanion round trip', () {
      final database = createTestDatabase();
      const port = app_models.AppPortConfig(
        id: 7,
        portNumber: 32400,
        protocol: 'https',
        serviceName: 'Plex',
        customUrl: 'https://plex.example.com',
        apiUrl: 'https://api.example.com',
        isPrimary: true,
        isEnabled: false,
      );

      final companion = database.appPortConfigToCompanion(port, 3);
      expect(companion.id, const Value(7));
      expect(companion.appConfigId, const Value(3));
      expect(companion.portNumber.value, 32400);
      expect(companion.isPrimary.value, isTrue);
      expect(companion.isEnabled.value, isFalse);

      final companionWithoutId = database.appPortConfigToCompanion(
        const app_models.AppPortConfig(portNumber: 80),
        3,
      );
      expect(companionWithoutId.id, const Value.absent());
    });
  });

  group('Full app config methods (config + ports together)', () {
    test(
      'getFullAppConfig returns null when the config does not exist',
      () async {
        final database = createTestDatabase();
        final serverId = await _seedServer(database);
        expect(await database.getFullAppConfig(serverId, 'plex'), isNull);
      },
    );

    test('insertFullAppConfig inserts the config and all its ports', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      final config = app_models.AppConfig(
        serverId: serverId,
        appName: 'plex',
        displayName: 'Plex',
        ports: const [
          app_models.AppPortConfig(portNumber: 32400, isPrimary: true),
          app_models.AppPortConfig(portNumber: 8080),
        ],
      );

      final id = await database.insertFullAppConfig(config);

      final full = await database.getFullAppConfig(serverId, 'plex');
      expect(full, isNotNull);
      expect(full!.id, id);
      expect(full.displayName, 'Plex');
      expect(full.ports, hasLength(2));
      expect(full.ports.map((p) => p.portNumber), [32400, 8080]);
    });

    test(
      'getFullAppConfigs returns every config for a server with its ports',
      () async {
        final database = createTestDatabase();
        final serverId = await _seedServer(database);
        await database.insertFullAppConfig(
          app_models.AppConfig(
            serverId: serverId,
            appName: 'plex',
            ports: const [app_models.AppPortConfig(portNumber: 32400)],
          ),
        );
        await database.insertFullAppConfig(
          app_models.AppConfig(serverId: serverId, appName: 'sonarr'),
        );

        final all = await database.getFullAppConfigs(serverId);

        expect(all, hasLength(2));
        final plex = all.firstWhere((c) => c.appName == 'plex');
        expect(plex.ports, hasLength(1));
        final sonarr = all.firstWhere((c) => c.appName == 'sonarr');
        expect(sonarr.ports, isEmpty);
      },
    );

    test('updateFullAppConfig throws ArgumentError without an id', () async {
      final database = createTestDatabase();
      final config = app_models.AppConfig(
        serverId: 'server-1',
        appName: 'plex',
      );

      expect(
        () => database.updateFullAppConfig(config),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('updateFullAppConfig replaces the port list entirely', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      final id = await database.insertFullAppConfig(
        app_models.AppConfig(
          serverId: serverId,
          appName: 'plex',
          ports: const [app_models.AppPortConfig(portNumber: 32400)],
        ),
      );

      final existing = (await database.getFullAppConfig(serverId, 'plex'))!;
      await database.updateFullAppConfig(
        existing.copyWith(
          id: id,
          displayName: 'Plex Media Server',
          ports: const [
            app_models.AppPortConfig(portNumber: 8080),
            app_models.AppPortConfig(portNumber: 8081),
          ],
        ),
      );

      final updated = (await database.getFullAppConfig(serverId, 'plex'))!;
      expect(updated.displayName, 'Plex Media Server');
      expect(updated.ports.map((p) => p.portNumber), [8080, 8081]);
    });

    test('upsertAppConfig inserts when no config exists yet', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);

      await database.upsertAppConfig(
        app_models.AppConfig(serverId: serverId, appName: 'plex'),
      );

      final configs = await database.getFullAppConfigs(serverId);
      expect(configs, hasLength(1));
    });

    test('upsertAppConfig updates the existing config in place', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      await database.insertFullAppConfig(
        app_models.AppConfig(serverId: serverId, appName: 'plex'),
      );

      await database.upsertAppConfig(
        app_models.AppConfig(
          serverId: serverId,
          appName: 'plex',
          displayName: 'Plex (updated)',
        ),
      );

      final configs = await database.getFullAppConfigs(serverId);
      expect(configs, hasLength(1));
      expect(configs.single.displayName, 'Plex (updated)');
    });
  });

  group('Migrations reachable via AppDatabase.forTesting', () {
    /// Builds a database whose raw schema matches what a real installation
    /// at schema version 4 looked like (right after app configuration
    /// support was introduced), then wraps it with [AppDatabase.forTesting]
    /// so opening it drives the from-4-to-current onUpgrade path.
    AppDatabase openAsSchemaVersion4() {
      final raw = sqlite3.sqlite3.openInMemory();
      raw.execute('''
        CREATE TABLE nas_servers (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          host TEXT NOT NULL,
          local_url TEXT,
          trusted_wifi_ssids TEXT NOT NULL DEFAULT '[]',
          port INTEGER,
          use_https INTEGER NOT NULL DEFAULT 1,
          allow_untrusted_certificates INTEGER NOT NULL DEFAULT 0,
          last_connected INTEGER,
          is_active INTEGER NOT NULL DEFAULT 1,
          is_default INTEGER NOT NULL DEFAULT 0
        );
      ''');
      raw.execute('''
        CREATE TABLE app_configs (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          server_id TEXT NOT NULL REFERENCES nas_servers (id) ON DELETE CASCADE,
          app_name TEXT NOT NULL,
          display_name TEXT,
          icon_url TEXT,
          is_enabled INTEGER NOT NULL DEFAULT 1,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        );
      ''');
      raw.execute('''
        CREATE TABLE app_port_configs (
          id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          app_config_id INTEGER NOT NULL REFERENCES app_configs (id) ON DELETE CASCADE,
          port_number INTEGER NOT NULL,
          protocol TEXT NOT NULL DEFAULT 'http',
          service_name TEXT,
          custom_url TEXT,
          is_primary INTEGER NOT NULL DEFAULT 0,
          is_enabled INTEGER NOT NULL DEFAULT 1,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        );
      ''');
      raw.execute('PRAGMA user_version = 4;');
      raw.execute('''
        INSERT INTO nas_servers (id, name, host, is_default)
        VALUES ('legacy-server', 'Legacy', 'legacy.example.com', 1)
      ''');
      raw.execute('''
        INSERT INTO app_configs (id, server_id, app_name, created_at, updated_at)
        VALUES (1, 'legacy-server', 'plex', 0, 0)
      ''');
      raw.execute('''
        INSERT INTO app_port_configs
          (id, app_config_id, port_number, custom_url, created_at, updated_at)
        VALUES (1, 1, 32400, 'http://should-be-cleared.example.com', 0, 0)
      ''');

      return AppDatabase.forTesting(NativeDatabase.opened(raw));
    }

    test('upgrading from schema version 4 runs every later migration step '
        'cleanly and preserves existing rows', () async {
      final database = openAsSchemaVersion4();
      addTearDown(database.close);

      expect(database.schemaVersion, 10);

      // The v2/v3-era server row survives, and the v10 `username` column
      // added by `if (from < 10)` is readable with its default value.
      final server = await database.getServer('legacy-server');
      expect(server, isNotNull);
      expect(server!.username, '');
      expect(server.isDefault, isTrue);

      // The v5-v7 `if (from < X)` blocks added many nullable columns to
      // app_configs; the existing row should still be there afterwards.
      final config = await database.getAppConfig('legacy-server', 'plex');
      expect(config, isNotNull);
      expect(config!.isFavorite, isFalse);
      expect(config.title, isNull);

      // `if (from < 8)` clears any pre-existing custom_url values from API
      // portals; `if (from < 9)` then adds the `api_url` column.
      final ports = await database.getAppPortConfigs(config.id);
      expect(ports, hasLength(1));
      expect(ports.single.customUrl, isNull);
      expect(ports.single.apiUrl, isNull);
    });

    test(
      'upgrading from schema version 9 only adds the username column',
      () async {
        final raw = sqlite3.sqlite3.openInMemory();
        raw.execute('''
        CREATE TABLE nas_servers (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          host TEXT NOT NULL,
          local_url TEXT,
          trusted_wifi_ssids TEXT NOT NULL DEFAULT '[]',
          port INTEGER,
          use_https INTEGER NOT NULL DEFAULT 1,
          allow_untrusted_certificates INTEGER NOT NULL DEFAULT 0,
          last_connected INTEGER,
          is_active INTEGER NOT NULL DEFAULT 1,
          is_default INTEGER NOT NULL DEFAULT 0
        );
      ''');
        raw.execute('PRAGMA user_version = 9;');
        raw.execute('''
        INSERT INTO nas_servers (id, name, host) VALUES ('s1', 'S', 'h.example.com')
      ''');

        final database = AppDatabase.forTesting(NativeDatabase.opened(raw));
        addTearDown(database.close);

        final server = await database.getServer('s1');
        expect(server, isNotNull);
        expect(server!.username, '');
      },
    );

    test('upgrading from schema version 1 currently fails: createTable/'
        'addColumn migration steps assume the historical, not the current, '
        'shape of the table being touched', () async {
      // KNOWN PRE-EXISTING BUG (not introduced or fixed by this test file -
      // lib/services/database.dart was explicitly out of scope):
      //
      // `if (from < 4) { await m.createTable(appConfigs); ... }` creates
      // app_configs using the *current* Dart table definition (every
      // column through schema v7 - isFavorite, title, categories, ...),
      // not the narrower v4 shape. The later `if (from < 5)` /
      // `if (from < 6)` / `if (from < 7)` blocks then try to
      // `m.addColumn` those same columns again onto a table that already
      // has them, which SQLite rejects as a duplicate column. Any
      // installation still below schema version 4 (i.e. one that has not
      // been opened since very early releases) will fail to migrate to
      // the current schema version 10 with a SqliteException, rather
      // than silently succeeding. This reproduces that with a schema
      // v1-shaped database (also pre-dating the v2 `isDefault` column and
      // the v3 credentials migration).
      final raw = sqlite3.sqlite3.openInMemory();
      raw.execute('''
          CREATE TABLE nas_servers (
            id TEXT NOT NULL PRIMARY KEY,
            name TEXT NOT NULL,
            host TEXT NOT NULL,
            local_url TEXT,
            trusted_wifi_ssids TEXT NOT NULL DEFAULT '[]',
            port INTEGER,
            use_https INTEGER NOT NULL DEFAULT 1,
            allow_untrusted_certificates INTEGER NOT NULL DEFAULT 0,
            last_connected INTEGER,
            is_active INTEGER NOT NULL DEFAULT 1
          );
        ''');
      raw.execute('PRAGMA user_version = 1;');
      raw.execute('''
          INSERT INTO nas_servers (id, name, host) VALUES ('s1', 'S', 'h.example.com')
        ''');

      final database = AppDatabase.forTesting(NativeDatabase.opened(raw));
      addTearDown(database.close);

      await expectLater(database.getAllServers(), throwsA(anything));
    });
  });

  group('AppDatabase.disposeInstance', () {
    test('is safe to call when no singleton has been created', () async {
      await AppDatabase.disposeInstance();
    });
  });
}
