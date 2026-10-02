import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:truehub/models/nas_server.dart' as models;
import 'package:truehub/services/database.dart';

part 'servers_dao.g.dart';

@DriftAccessor(tables: [NasServers])
class ServersDao extends DatabaseAccessor<AppDatabase> with _$ServersDaoMixin {
  ServersDao(super.attachedDatabase);

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
        username: Value(server.username),
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

    // Note: Credentials are now handled by ServerSyncService, not stored here
  }

  Future<void> updateServer(models.NasServer server) async {
    // Update server metadata in database
    await (update(nasServers)..where((tbl) => tbl.id.equals(server.id))).write(
      NasServersCompanion(
        name: Value(server.name),
        host: Value(server.host),
        username: Value(server.username),
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

    // Note: Credentials are now handled by ServerSyncService, not stored here
  }

  /// Inserts or updates [server] in the local `nas_servers` table without
  /// requiring it to be absent first.
  ///
  /// On Apple platforms server metadata is owned by CloudKit
  /// (`CloudKitServerRepository`), which never writes to this SQLite
  /// database - but `app_configs.server_id` still enforces a foreign key
  /// against `nas_servers` here (see the `PRAGMA foreign_keys = ON` above).
  /// Callers that are about to write `app_configs` rows for a server use
  /// this to mirror it in first as a foreign-key anchor, regardless of
  /// which repository is actually authoritative for its metadata.
  Future<void> upsertServerAnchor(models.NasServer server) async {
    await into(nasServers).insertOnConflictUpdate(
      NasServersCompanion(
        id: Value(server.id),
        name: Value(server.name),
        host: Value(server.host),
        username: Value(server.username),
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
  }

  Future<void> deleteServer(String id) async {
    // Delete server from database
    await (delete(nasServers)..where((tbl) => tbl.id.equals(id))).go();

    // Note: Credentials are now handled by ServerSyncService, not deleted here
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
      username: row.username, // Username is non-sensitive metadata stored in DB
      password:
          '', // Password is stored securely in keychain, retrieved separately
      useHttps: row.useHttps,
      allowUntrustedCertificates: row.allowUntrustedCertificates,
      lastConnected: row.lastConnected,
      isActive: row.isActive,
      isDefault: row.isDefault,
    );
  }
}
