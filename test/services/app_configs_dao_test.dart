// Tests for [AppConfigsDao] (lib/services/database/app_configs_dao.dart):
// app configs, port configs, favorites and the AppConfig model mapping.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
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
  await database.serversDao.insertServer(server);
  return server.id;
}

void main() {
  group('AppConfigs CRUD', () {
    test('getAppConfigs returns an empty list for an unknown server', () async {
      final database = createTestDatabase();
      expect(
        await database.appConfigsDao.getAppConfigs('missing-server'),
        isEmpty,
      );
    });

    test('insertAppConfig returns the generated row id', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);

      final id = await database.appConfigsDao.insertAppConfig(
        AppConfigsCompanion.insert(serverId: serverId, appName: 'plex'),
      );

      expect(id, isPositive);
      final configs = await database.appConfigsDao.getAppConfigs(serverId);
      expect(configs, hasLength(1));
      expect(configs.single.id, id);
      expect(configs.single.appName, 'plex');
    });

    test('getAppConfig finds a row by serverId + appName', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      await database.appConfigsDao.insertAppConfig(
        AppConfigsCompanion.insert(serverId: serverId, appName: 'sonarr'),
      );

      final found = await database.appConfigsDao.getAppConfig(
        serverId,
        'sonarr',
      );
      expect(found, isNotNull);
      expect(found!.appName, 'sonarr');

      expect(
        await database.appConfigsDao.getAppConfig(serverId, 'radarr'),
        isNull,
      );
      expect(
        await database.appConfigsDao.getAppConfig('other-server', 'sonarr'),
        isNull,
      );
    });

    test('updateAppConfig changes stored fields', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      final id = await database.appConfigsDao.insertAppConfig(
        AppConfigsCompanion.insert(serverId: serverId, appName: 'plex'),
      );

      await database.appConfigsDao.updateAppConfig(
        id,
        const AppConfigsCompanion(
          displayName: Value('Plex Media Server'),
          isEnabled: Value(false),
        ),
      );

      final updated = await database.appConfigsDao.getAppConfig(
        serverId,
        'plex',
      );
      expect(updated!.displayName, 'Plex Media Server');
      expect(updated.isEnabled, isFalse);
    });

    test('updateAppConfig for an unknown id does not throw', () async {
      final database = createTestDatabase();
      await database.appConfigsDao.updateAppConfig(
        999999,
        const AppConfigsCompanion(displayName: Value('nope')),
      );
    });

    test('deleteAppConfig removes the row', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      final id = await database.appConfigsDao.insertAppConfig(
        AppConfigsCompanion.insert(serverId: serverId, appName: 'plex'),
      );

      await database.appConfigsDao.deleteAppConfig(id);

      expect(await database.appConfigsDao.getAppConfigs(serverId), isEmpty);
    });

    test('deleteAppConfig for an unknown id does not throw', () async {
      final database = createTestDatabase();
      await database.appConfigsDao.deleteAppConfig(999999);
    });

    test('deleting a server cascade-deletes its app configs, per the declared '
        'onDelete: KeyAction.cascade', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      await database.appConfigsDao.insertAppConfig(
        AppConfigsCompanion.insert(serverId: serverId, appName: 'plex'),
      );

      await database.serversDao.deleteServer(serverId);

      expect(await database.appConfigsDao.getAppConfigs(serverId), isEmpty);
    });
  });

  group('Favorite app methods', () {
    test('isAppFavorite is false when no app config exists yet', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      expect(
        await database.appConfigsDao.isAppFavorite(serverId, 'plex'),
        isFalse,
      );
    });

    test('setAppFavorite creates a config when none exists', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);

      await database.appConfigsDao.setAppFavorite(serverId, 'plex', true);

      expect(
        await database.appConfigsDao.isAppFavorite(serverId, 'plex'),
        isTrue,
      );
      final configs = await database.appConfigsDao.getAppConfigs(serverId);
      expect(configs, hasLength(1));
      expect(configs.single.appName, 'plex');
    });

    test('setAppFavorite updates an existing config', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      await database.appConfigsDao.insertAppConfig(
        AppConfigsCompanion.insert(serverId: serverId, appName: 'plex'),
      );

      await database.appConfigsDao.setAppFavorite(serverId, 'plex', true);
      expect(
        await database.appConfigsDao.isAppFavorite(serverId, 'plex'),
        isTrue,
      );

      await database.appConfigsDao.setAppFavorite(serverId, 'plex', false);
      expect(
        await database.appConfigsDao.isAppFavorite(serverId, 'plex'),
        isFalse,
      );

      // Still exactly one config row - the second call updated, not inserted.
      expect(
        await database.appConfigsDao.getAppConfigs(serverId),
        hasLength(1),
      );
    });

    test('getFavoriteApps returns only favorites, sorted by appName', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      await database.appConfigsDao.setAppFavorite(serverId, 'zeta', true);
      await database.appConfigsDao.setAppFavorite(serverId, 'alpha', true);
      await database.appConfigsDao.setAppFavorite(
        serverId,
        'not-a-favorite',
        false,
      );

      final favorites = await database.appConfigsDao.getFavoriteApps(serverId);

      expect(favorites.map((c) => c.appName), ['alpha', 'zeta']);
    });
  });

  group('AppPortConfigs CRUD', () {
    Future<int> seedAppConfig(AppDatabase database, String serverId) {
      return database.appConfigsDao.insertAppConfig(
        AppConfigsCompanion.insert(serverId: serverId, appName: 'plex'),
      );
    }

    test('getAppPortConfigs returns an empty list initially', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      final appConfigId = await seedAppConfig(database, serverId);

      expect(
        await database.appConfigsDao.getAppPortConfigs(appConfigId),
        isEmpty,
      );
    });

    test('insertAppPortConfig returns the generated id', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      final appConfigId = await seedAppConfig(database, serverId);

      final id = await database.appConfigsDao.insertAppPortConfig(
        AppPortConfigsCompanion.insert(
          appConfigId: appConfigId,
          portNumber: 32400,
        ),
      );

      expect(id, isPositive);
      final ports = await database.appConfigsDao.getAppPortConfigs(appConfigId);
      expect(ports, hasLength(1));
      expect(ports.single.portNumber, 32400);
    });

    test('updateAppPortConfig changes stored fields', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      final appConfigId = await seedAppConfig(database, serverId);
      final id = await database.appConfigsDao.insertAppPortConfig(
        AppPortConfigsCompanion.insert(
          appConfigId: appConfigId,
          portNumber: 32400,
        ),
      );

      await database.appConfigsDao.updateAppPortConfig(
        id,
        const AppPortConfigsCompanion(
          serviceName: Value('Plex'),
          isEnabled: Value(false),
        ),
      );

      final updated = (await database.appConfigsDao.getAppPortConfigs(
        appConfigId,
      )).single;
      expect(updated.serviceName, 'Plex');
      expect(updated.isEnabled, isFalse);
    });

    test('updateAppPortConfig for an unknown id does not throw', () async {
      final database = createTestDatabase();
      await database.appConfigsDao.updateAppPortConfig(
        999999,
        const AppPortConfigsCompanion(serviceName: Value('nope')),
      );
    });

    test('deleteAppPortConfig removes the row', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      final appConfigId = await seedAppConfig(database, serverId);
      final id = await database.appConfigsDao.insertAppPortConfig(
        AppPortConfigsCompanion.insert(
          appConfigId: appConfigId,
          portNumber: 32400,
        ),
      );

      await database.appConfigsDao.deleteAppPortConfig(id);

      expect(
        await database.appConfigsDao.getAppPortConfigs(appConfigId),
        isEmpty,
      );
    });

    test('deleteAppPortConfig for an unknown id does not throw', () async {
      final database = createTestDatabase();
      await database.appConfigsDao.deleteAppPortConfig(999999);
    });

    test('setPrimaryPort makes exactly one port primary', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      final appConfigId = await seedAppConfig(database, serverId);
      final firstPort = await database.appConfigsDao.insertAppPortConfig(
        AppPortConfigsCompanion.insert(
          appConfigId: appConfigId,
          portNumber: 32400,
          isPrimary: const Value(true),
        ),
      );
      final secondPort = await database.appConfigsDao.insertAppPortConfig(
        AppPortConfigsCompanion.insert(
          appConfigId: appConfigId,
          portNumber: 8080,
        ),
      );

      await database.appConfigsDao.setPrimaryPort(appConfigId, secondPort);

      final ports = await database.appConfigsDao.getAppPortConfigs(appConfigId);
      final primary = ports.where((p) => p.isPrimary).toList();
      expect(primary, hasLength(1));
      expect(primary.single.id, secondPort);
      expect(ports.firstWhere((p) => p.id == firstPort).isPrimary, isFalse);
    });

    test('deleting an app config cascade-deletes its port configs, per the '
        'declared onDelete: KeyAction.cascade', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      final appConfigId = await seedAppConfig(database, serverId);
      await database.appConfigsDao.insertAppPortConfig(
        AppPortConfigsCompanion.insert(
          appConfigId: appConfigId,
          portNumber: 32400,
        ),
      );

      await database.appConfigsDao.deleteAppConfig(appConfigId);

      expect(
        await database.appConfigsDao.getAppPortConfigs(appConfigId),
        isEmpty,
      );
    });
  });

  group('getAppConfigsWithPorts', () {
    test('joins app configs with their ports', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      final appConfigId = await database.appConfigsDao.insertAppConfig(
        AppConfigsCompanion.insert(serverId: serverId, appName: 'plex'),
      );
      await database.appConfigsDao.insertAppPortConfig(
        AppPortConfigsCompanion.insert(
          appConfigId: appConfigId,
          portNumber: 32400,
          protocol: const Value('https'),
          isPrimary: const Value(true),
        ),
      );

      final rows = await database.appConfigsDao.getAppConfigsWithPorts(
        serverId,
      );

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
      await database.appConfigsDao.insertAppConfig(
        AppConfigsCompanion.insert(serverId: serverId, appName: 'sonarr'),
      );

      final rows = await database.appConfigsDao.getAppConfigsWithPorts(
        serverId,
      );

      expect(rows, hasLength(1));
      expect(rows.single['app_name'], 'sonarr');
      expect(rows.single['port_id'], isNull);
      expect(rows.single['port_number'], isNull);
    });

    test('returns nothing for a server with no app configs', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      expect(
        await database.appConfigsDao.getAppConfigsWithPorts(serverId),
        isEmpty,
      );
    });
  });

  group('AppConfigData <-> AppConfig model mapping', () {
    test('appConfigToCompanion leaves id absent when the model has none', () {
      final database = createTestDatabase();
      final config = app_models.AppConfig(
        serverId: 'server-1',
        appName: 'plex',
      );

      final companion = database.appConfigsDao.appConfigToCompanion(config);

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

      expect(
        database.appConfigsDao.appConfigToCompanion(config).id,
        const Value(42),
      );
    });

    test(
      'appConfigToCompanion JSON-encodes list fields, mapToAppConfig decodes them back',
      () async {
        final database = createTestDatabase();
        final serverId = await _seedServer(database);
        final config = app_models.AppConfig(
          serverId: serverId,
          appName: 'plex',
          categories: const ['media', 'entertainment'],
          tags: const ['popular'],
          screenshots: const ['https://example.com/1.png'],
          sources: const ['https://example.com/src'],
          maintainersJson: '[{"name":"someone"}]',
          upgradeInfoJson: '{"available":true}',
          usedPortsJson: '[{"port":32400}]',
        );

        final companion = database.appConfigsDao.appConfigToCompanion(config);
        expect(companion.categories.value, isNotNull);
        expect(companion.categories.value, '["media","entertainment"]');

        final id = await database.appConfigsDao.insertAppConfig(companion);
        final roundTripped = (await database.appConfigsDao.getAppConfigs(
          serverId,
        )).single;
        final mapped = database.appConfigsDao.mapToAppConfig(
          roundTripped,
          const [],
        );

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
        await database.appConfigsDao.insertAppConfig(
          AppConfigsCompanion.insert(serverId: serverId, appName: 'plex'),
        );
        final row = (await database.appConfigsDao.getAppConfigs(
          serverId,
        )).single;

        final mapped = database.appConfigsDao.mapToAppConfig(row, const []);

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

      final companion = database.appConfigsDao.appPortConfigToCompanion(
        port,
        3,
      );
      expect(companion.id, const Value(7));
      expect(companion.appConfigId, const Value(3));
      expect(companion.portNumber.value, 32400);
      expect(companion.isPrimary.value, isTrue);
      expect(companion.isEnabled.value, isFalse);

      final companionWithoutId = database.appConfigsDao
          .appPortConfigToCompanion(
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
        expect(
          await database.appConfigsDao.getFullAppConfig(serverId, 'plex'),
          isNull,
        );
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

      final id = await database.appConfigsDao.insertFullAppConfig(config);

      final full = await database.appConfigsDao.getFullAppConfig(
        serverId,
        'plex',
      );
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
        await database.appConfigsDao.insertFullAppConfig(
          app_models.AppConfig(
            serverId: serverId,
            appName: 'plex',
            ports: const [app_models.AppPortConfig(portNumber: 32400)],
          ),
        );
        await database.appConfigsDao.insertFullAppConfig(
          app_models.AppConfig(serverId: serverId, appName: 'sonarr'),
        );

        final all = await database.appConfigsDao.getFullAppConfigs(serverId);

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
        () => database.appConfigsDao.updateFullAppConfig(config),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('updateFullAppConfig replaces the port list entirely', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      final id = await database.appConfigsDao.insertFullAppConfig(
        app_models.AppConfig(
          serverId: serverId,
          appName: 'plex',
          ports: const [app_models.AppPortConfig(portNumber: 32400)],
        ),
      );

      final existing = (await database.appConfigsDao.getFullAppConfig(
        serverId,
        'plex',
      ))!;
      await database.appConfigsDao.updateFullAppConfig(
        existing.copyWith(
          id: id,
          displayName: 'Plex Media Server',
          ports: const [
            app_models.AppPortConfig(portNumber: 8080),
            app_models.AppPortConfig(portNumber: 8081),
          ],
        ),
      );

      final updated = (await database.appConfigsDao.getFullAppConfig(
        serverId,
        'plex',
      ))!;
      expect(updated.displayName, 'Plex Media Server');
      expect(updated.ports.map((p) => p.portNumber), [8080, 8081]);
    });

    test('upsertAppConfig inserts when no config exists yet', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);

      await database.appConfigsDao.upsertAppConfig(
        app_models.AppConfig(serverId: serverId, appName: 'plex'),
      );

      final configs = await database.appConfigsDao.getFullAppConfigs(serverId);
      expect(configs, hasLength(1));
    });

    test('upsertAppConfig updates the existing config in place', () async {
      final database = createTestDatabase();
      final serverId = await _seedServer(database);
      await database.appConfigsDao.insertFullAppConfig(
        app_models.AppConfig(serverId: serverId, appName: 'plex'),
      );

      await database.appConfigsDao.upsertAppConfig(
        app_models.AppConfig(
          serverId: serverId,
          appName: 'plex',
          displayName: 'Plex (updated)',
        ),
      );

      final configs = await database.appConfigsDao.getFullAppConfigs(serverId);
      expect(configs, hasLength(1));
      expect(configs.single.displayName, 'Plex (updated)');
    });
  });
}
