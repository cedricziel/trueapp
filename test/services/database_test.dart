// Tests for [AppDatabase] (lib/services/database.dart): schema version,
// migrations and singleton disposal.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:truehub/services/database.dart';

void main() {
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
      final server = await database.serversDao.getServer('legacy-server');
      expect(server, isNotNull);
      expect(server!.username, '');
      expect(server.isDefault, isTrue);

      // The v5-v7 `if (from < X)` blocks added many nullable columns to
      // app_configs; the existing row should still be there afterwards.
      final config = await database.appConfigsDao.getAppConfig(
        'legacy-server',
        'plex',
      );
      expect(config, isNotNull);
      expect(config!.isFavorite, isFalse);
      expect(config.title, isNull);

      // `if (from < 8)` clears any pre-existing custom_url values from API
      // portals; `if (from < 9)` then adds the `api_url` column.
      final ports = await database.appConfigsDao.getAppPortConfigs(config.id);
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

        final server = await database.serversDao.getServer('s1');
        expect(server, isNotNull);
        expect(server!.username, '');
      },
    );

    test('upgrading from schema version 1 runs every migration step cleanly '
        'and preserves the existing row', () async {
      // Regression test for a bug where `if (from < 4) { await
      // m.createTable(appConfigs); ... }` creates app_configs/
      // app_port_configs using the *current* Dart table definition
      // (every column through the latest schema version), not the
      // narrower v4 shape - so the later `if (from < 5)` / `if (from <
      // 6)` / `if (from < 7)` / `if (from < 9)` blocks were trying to
      // `m.addColumn` those same columns again onto a table that
      // already had them, which SQLite rejects as a duplicate column.
      // Likewise `_migrateCredentialsToSecureStorage`'s TableMigration
      // (from < 3) targets the current nas_servers shape, which
      // includes `username` - re-added at v10 - so `if (from < 10) {
      // addColumn(username) }` was also a duplicate for anyone who'd
      // just gone through that step. This reproduces the whole chain
      // with a schema v1-shaped database (pre-dating the v2
      // `isDefault` column and the v3 credentials migration).
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

      expect(database.schemaVersion, 10);

      final server = await database.serversDao.getServer('s1');
      expect(server, isNotNull);
      expect(server!.username, '');
      expect(server.isActive, isTrue);
      expect(server.isDefault, isFalse);

      // The tables app_configs/app_port_configs are usable afterwards,
      // with every column through v10 present exactly once.
      final configId = await database.appConfigsDao.insertAppConfig(
        AppConfigsCompanion.insert(serverId: 's1', appName: 'plex'),
      );
      await database.appConfigsDao.insertAppPortConfig(
        AppPortConfigsCompanion.insert(
          appConfigId: configId,
          portNumber: 32400,
        ),
      );
      final config = await database.appConfigsDao.getAppConfig('s1', 'plex');
      expect(config, isNotNull);
      expect(config!.isFavorite, isFalse);
      final ports = await database.appConfigsDao.getAppPortConfigs(configId);
      expect(ports, hasLength(1));
      expect(ports.single.apiUrl, isNull);
    });

    test('recovers a missing username column even when the from < 3 '
        'credentials TableMigration step failed and was swallowed', () async {
      // `_migrateCredentialsToSecureStorage` catches every exception from
      // its TableMigration and merely logs it (that behavior predates
      // this PR and is called out as unable to change), so a real-world
      // failure there - a locked file, a stray leftover temp table from
      // a previous crashed migration attempt, anything - leaves
      // nas_servers without a `username` column while onUpgrade still
      // completes and stamps schema_version 10. If the `from < 10` step
      // that (re-)adds `username` were skipped whenever `from < 3` (on
      // the assumption the TableMigration above it must have already
      // added it), every subsequent read would fail with "no such
      // column: username" - unrecoverably, since the app would never
      // run this migration again once schema_version reads 10.
      //
      // Reproduces the "TableMigration failed" half of that chain by
      // pre-creating the temp table drift's TableMigration internally
      // creates and drops (`tmp_for_copy_nas_servers`), so its own
      // `CREATE TABLE` collides and throws.
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
      raw.execute('''
          CREATE TABLE tmp_for_copy_nas_servers (poisoned INTEGER);
        ''');
      raw.execute('PRAGMA user_version = 1;');
      raw.execute('''
          INSERT INTO nas_servers (id, name, host) VALUES ('s1', 'S', 'h.example.com')
        ''');

      final database = AppDatabase.forTesting(NativeDatabase.opened(raw));
      addTearDown(database.close);

      expect(database.schemaVersion, 10);

      final server = await database.serversDao.getServer('s1');
      expect(server, isNotNull);
      expect(server!.username, '');
    });
  });
}
