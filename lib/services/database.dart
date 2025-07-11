import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:truenas_manager/models/nas_server.dart' as models;
import 'package:truenas_manager/services/secure_storage_service.dart';

part 'database.g.dart';

@DataClassName('NasServerData')
class NasServers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get host => text()();
  TextColumn get localUrl => text().nullable()();
  TextColumn get trustedWifiSsids => text().withDefault(const Constant('[]'))();
  IntColumn get port => integer().nullable()();
  BoolColumn get useHttps => boolean().withDefault(const Constant(true))();
  BoolColumn get allowUntrustedCertificates =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastConnected => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [NasServers])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'truenas_manager'));

  // Constructor for testing that accepts a custom QueryExecutor
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(nasServers, nasServers.isDefault);
      }
      if (from < 3) {
        await _migrateCredentialsToSecureStorage(m, from);
      }
    },
  );

  Future<void> _migrateCredentialsToSecureStorage(
    Migrator m,
    int fromVersion,
  ) async {
    // First, read all existing servers with their credentials before schema change
    if (fromVersion < 3) {
      try {
        // Query the old table structure with credentials
        final oldServers = await customSelect(
          'SELECT id, username, password FROM nas_servers',
        ).get();

        // Migrate each server's credentials to secure storage
        for (final server in oldServers) {
          final serverId = server.data['id'] as String;
          final username = server.data['username'] as String;
          final password = server.data['password'] as String;

          await SecureStorageService.migrateCredentials(
            serverId: serverId,
            username: username,
            password: password,
          );
        }

        // Drop the username and password columns
        await m.alterTable(
          TableMigration(
            nasServers,
            columnTransformer: {
              nasServers.id: nasServers.id,
              nasServers.name: nasServers.name,
              nasServers.host: nasServers.host,
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
        print(
          'Warning: Failed to migrate some credentials to secure storage: $e',
        );
      }
    }
  }

  Future<List<models.NasServer>> getAllServers() async {
    final query = select(nasServers);
    final rows = await query.get();
    return rows.map((row) => _mapRowToNasServer(row)).toList();
  }

  Future<models.NasServer?> getServer(String id) async {
    final query = select(nasServers)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row != null) {
      final server = _mapRowToNasServer(row);
      return server;
    } else {
      return null;
    }
  }

  Future<void> insertServer(models.NasServer server) async {
    // Store server metadata in database
    await into(nasServers).insert(
      NasServersCompanion(
        id: Value(server.id),
        name: Value(server.name),
        host: Value(server.host),
        localUrl: Value(server.localUrl),
        trustedWifiSsids: Value(jsonEncode(server.trustedWifiSsids)),
        port: Value(server.port),
        useHttps: Value(server.useHttps),
        allowUntrustedCertificates: Value(server.allowUntrustedCertificates),
        lastConnected: Value(server.lastConnected),
        isActive: Value(server.isActive),
        isDefault: Value(server.isDefault),
      ),
    );

    // Store credentials securely
    await SecureStorageService.storeCredentials(
      serverId: server.id,
      username: server.username,
      password: server.password,
    );
  }

  Future<void> updateServer(models.NasServer server) async {
    // Update server metadata in database
    await (update(nasServers)..where((tbl) => tbl.id.equals(server.id))).write(
      NasServersCompanion(
        name: Value(server.name),
        host: Value(server.host),
        localUrl: Value(server.localUrl),
        trustedWifiSsids: Value(jsonEncode(server.trustedWifiSsids)),
        port: Value(server.port),
        useHttps: Value(server.useHttps),
        allowUntrustedCertificates: Value(server.allowUntrustedCertificates),
        lastConnected: Value(server.lastConnected),
        isActive: Value(server.isActive),
        isDefault: Value(server.isDefault),
      ),
    );

    // Update credentials securely
    await SecureStorageService.storeCredentials(
      serverId: server.id,
      username: server.username,
      password: server.password,
    );
  }

  Future<void> deleteServer(String id) async {
    // Delete server from database
    await (delete(nasServers)..where((tbl) => tbl.id.equals(id))).go();

    // Delete credentials from secure storage
    await SecureStorageService.deleteCredentials(
      serverId: id,
      requireAuthentication:
          false, // No auth required for deletion during server removal
    );
  }

  Future<void> updateLastConnected(String id) async {
    await (update(nasServers)..where((tbl) => tbl.id.equals(id))).write(
      NasServersCompanion(lastConnected: Value(DateTime.now())),
    );
  }

  Future<models.NasServer?> getDefaultServer() async {
    final query = select(nasServers)
      ..where((tbl) => tbl.isDefault.equals(true));
    final row = await query.getSingleOrNull();
    return row != null ? _mapRowToNasServer(row) : null;
  }

  Future<void> setDefaultServer(String id) async {
    await transaction(() async {
      // First, clear any existing default server
      await (update(nasServers)..where((tbl) => tbl.isDefault.equals(true)))
          .write(NasServersCompanion(isDefault: const Value(false)));
      // Then set the new default server
      await (update(nasServers)..where((tbl) => tbl.id.equals(id))).write(
        NasServersCompanion(isDefault: const Value(true)),
      );
    });
  }

  Future<void> clearDefaultServer() async {
    await (update(nasServers)..where((tbl) => tbl.isDefault.equals(true)))
        .write(NasServersCompanion(isDefault: const Value(false)));
  }

  models.NasServer _mapRowToNasServer(NasServerData row) {
    final trustedWifiSsids = (jsonDecode(row.trustedWifiSsids) as List)
        .map((e) => e as String)
        .toList();

    return models.NasServer(
      id: row.id,
      name: row.name,
      host: row.host,
      localUrl: row.localUrl,
      trustedWifiSsids: trustedWifiSsids,
      port: row.port,
      username: '', // Credentials are now stored securely, retrieved separately
      password: '', // Credentials are now stored securely, retrieved separately
      useHttps: row.useHttps,
      allowUntrustedCertificates: row.allowUntrustedCertificates,
      lastConnected: row.lastConnected,
      isActive: row.isActive,
      isDefault: row.isDefault,
    );
  }

  /// Helper method to get server with credentials from secure storage
  Future<models.NasServer?> getServerWithCredentials(String id) async {
    final server = await getServer(id);
    if (server == null) return null;

    final credentials = await SecureStorageService.getCredentials(serverId: id);
    if (credentials == null) return null;

    return server.copyWith(
      username: credentials.username,
      password: credentials.password,
    );
  }
}
