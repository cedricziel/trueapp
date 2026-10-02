import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:truehub/services/app_logger.dart';
import 'package:truehub/services/database.dart';

final _log = appLogger('storage.database');

MigrationStrategy buildMigrationStrategy(AppDatabase db) {
  final nasServers = db.nasServers;
  final appConfigs = db.appConfigs;
  final appPortConfigs = db.appPortConfigs;

  return MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await _addColumnIfMissing(m, nasServers, nasServers.isDefault);
      }

      if (from < 3) {
        await _migrateCredentialsToSecureStorage(db, m, from);
      }

      if (from < 4) {
        await _createTableIfMissing(m, appConfigs);
        await _createTableIfMissing(m, appPortConfigs);
      }
      if (from < 5) {
        await _addColumnIfMissing(m, appConfigs, appConfigs.isFavorite);
      }
      if (from < 6) {
        await _addColumnIfMissing(m, appConfigs, appConfigs.title);
        await _addColumnIfMissing(m, appConfigs, appConfigs.description);
        await _addColumnIfMissing(m, appConfigs, appConfigs.installed);
        await _addColumnIfMissing(m, appConfigs, appConfigs.healthy);
        await _addColumnIfMissing(m, appConfigs, appConfigs.healthyError);
        await _addColumnIfMissing(m, appConfigs, appConfigs.version);
        await _addColumnIfMissing(m, appConfigs, appConfigs.appVersion);
        await _addColumnIfMissing(m, appConfigs, appConfigs.humanVersion);
        await _addColumnIfMissing(m, appConfigs, appConfigs.categories);
        await _addColumnIfMissing(m, appConfigs, appConfigs.home);
        await _addColumnIfMissing(m, appConfigs, appConfigs.tags);
        await _addColumnIfMissing(m, appConfigs, appConfigs.recommended);
        await _addColumnIfMissing(m, appConfigs, appConfigs.catalog);
        await _addColumnIfMissing(m, appConfigs, appConfigs.train);
        await _addColumnIfMissing(m, appConfigs, appConfigs.lastApiUpdate);
      }
      if (from < 7) {
        await _addColumnIfMissing(m, appConfigs, appConfigs.screenshots);
        await _addColumnIfMissing(m, appConfigs, appConfigs.sources);
        await _addColumnIfMissing(m, appConfigs, appConfigs.appReadme);
        await _addColumnIfMissing(m, appConfigs, appConfigs.maintainersJson);
        await _addColumnIfMissing(m, appConfigs, appConfigs.upgradeInfoJson);
        await _addColumnIfMissing(m, appConfigs, appConfigs.usedPortsJson);
      }
      if (from < 8) {
        // Clear out incorrectly set customUrl values from API portals
        // Only user-defined URLs should have customUrl set
        await db.customUpdate(
          'UPDATE app_port_configs SET custom_url = NULL WHERE custom_url IS NOT NULL',
        );
      }
      if (from < 9) {
        await _addColumnIfMissing(m, appPortConfigs, appPortConfigs.apiUrl);
      }
      if (from < 10) {
        // Re-add username column as non-sensitive metadata
        // Password remains in keychain only
        await _addColumnIfMissing(m, nasServers, nasServers.username);
      }
    },
    beforeOpen: (details) async {
      // SQLite ignores declared foreign keys (including onDelete: cascade)
      // unless this pragma is turned on per-connection - it defaults to off.
      await db.customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

/// Adds [column] to [table], tolerating "already exists" - self-healing
/// against a migration that already added it on an earlier, interrupted
/// run of this same `onUpgrade` step.
///
/// `_migrateCredentialsToSecureStorage`'s TableMigration swallows its own
/// exceptions (see the comment there), so a real-world failure there can
/// leave a column it was meant to carry over - `username` - missing even
/// though `onUpgrade` completes and stamps the new schema version. If a
/// later step then skipped re-adding that column on the assumption the
/// earlier one must have succeeded, every read afterwards would fail with
/// "no such column", unrecoverably: the app never runs this migration
/// again once the version already reads current. Always attempting the
/// column and only swallowing the "it's already there" case avoids that
/// trap without having to trust what an earlier step claims it did.
Future<void> _addColumnIfMissing(
  Migrator m,
  TableInfo table,
  GeneratedColumn column,
) async {
  try {
    await m.addColumn(table, column);
  } on SqliteException catch (e) {
    if (!e.toString().contains('duplicate column name')) rethrow;
  }
}

/// Creates [table], tolerating "already exists" - the createTable
/// counterpart to [_addColumnIfMissing], for the same self-healing reason.
Future<void> _createTableIfMissing(Migrator m, TableInfo table) async {
  try {
    await m.createTable(table);
  } on SqliteException catch (e) {
    if (!e.toString().contains('already exists')) rethrow;
  }
}

Future<void> _migrateCredentialsToSecureStorage(
  AppDatabase db,
  Migrator m,
  int fromVersion,
) async {
  final nasServers = db.nasServers;
  if (fromVersion < 3) {
    try {
      // Drop the username and password columns.
      //
      // TableMigration is drift's documented API for rewriting a table, and
      // the only way to drop a column on SQLite. Upstream still marks it
      // experimental, so the analyzer flags it; this migration already
      // shipped and cannot change.
      await m.alterTable(
        // ignore: experimental_member_use
        TableMigration(
          nasServers,
          columnTransformer: {
            nasServers.id: nasServers.id,
            nasServers.name: nasServers.name,
            nasServers.host: nasServers.host,
            // `username` was re-added (at v10) after this migration
            // shipped, so it never exists on the pre-v3 source table
            // this step reads from - default it explicitly instead of
            // letting TableMigration fall back to a same-name column
            // read that would fail with "no such column: username".
            nasServers.username: const Constant(''),
            nasServers.localUrl: nasServers.localUrl,
            nasServers.trustedWifiSsids: nasServers.trustedWifiSsids,
            nasServers.port: nasServers.port,
            nasServers.useHttps: nasServers.useHttps,
            nasServers.allowUntrustedCertificates:
                nasServers.allowUntrustedCertificates,
            nasServers.lastConnected: nasServers.lastConnected,
            nasServers.isActive: nasServers.isActive,
            nasServers.isDefault: nasServers.isDefault,
          },
        ),
      );
    } catch (e) {
      // Log error but don't fail migration
      _log.error(
        'Failed to migrate some credentials to secure storage',
        error: e,
      );
    }
  }
}
