import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:truenas_manager/models/nas_server.dart' as models;

part 'database.g.dart';

@DataClassName('NasServerData')
class NasServers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get host => text()();
  TextColumn get localUrl => text().nullable()();
  TextColumn get trustedWifiSsids => text().withDefault(const Constant('[]'))();
  IntColumn get port => integer().nullable()();
  TextColumn get username => text()();
  TextColumn get password => text()();
  BoolColumn get useHttps => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastConnected => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [NasServers])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'truenas_manager'));

  // Constructor for testing that accepts a custom QueryExecutor
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from == 1) {
        await migrator.addColumn(nasServers, nasServers.localUrl);
        await migrator.addColumn(nasServers, nasServers.trustedWifiSsids);
      }
      if (from == 2) {
        await migrator.addColumn(nasServers, nasServers.trustedWifiSsids);
      }
    },
  );

  Future<List<models.NasServer>> getAllServers() async {
    final query = select(nasServers);
    final rows = await query.get();
    return rows.map((row) => _mapRowToNasServer(row)).toList();
  }

  Future<models.NasServer?> getServer(String id) async {
    final query = select(nasServers)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapRowToNasServer(row) : null;
  }

  Future<void> insertServer(models.NasServer server) async {
    await into(nasServers).insert(
      NasServersCompanion(
        id: Value(server.id),
        name: Value(server.name),
        host: Value(server.host),
        localUrl: Value(server.localUrl),
        trustedWifiSsids: Value(jsonEncode(server.trustedWifiSsids)),
        port: Value(server.port),
        username: Value(server.username),
        password: Value(server.password),
        useHttps: Value(server.useHttps),
        lastConnected: Value(server.lastConnected),
        isActive: Value(server.isActive),
      ),
    );
  }

  Future<void> updateServer(models.NasServer server) async {
    await (update(nasServers)..where((tbl) => tbl.id.equals(server.id))).write(
      NasServersCompanion(
        name: Value(server.name),
        host: Value(server.host),
        localUrl: Value(server.localUrl),
        trustedWifiSsids: Value(jsonEncode(server.trustedWifiSsids)),
        port: Value(server.port),
        username: Value(server.username),
        password: Value(server.password),
        useHttps: Value(server.useHttps),
        lastConnected: Value(server.lastConnected),
        isActive: Value(server.isActive),
      ),
    );
  }

  Future<void> deleteServer(String id) async {
    await (delete(nasServers)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> updateLastConnected(String id) async {
    await (update(nasServers)..where((tbl) => tbl.id.equals(id))).write(
      NasServersCompanion(lastConnected: Value(DateTime.now())),
    );
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
      username: row.username,
      password: row.password,
      useHttps: row.useHttps,
      lastConnected: row.lastConnected,
      isActive: row.isActive,
    );
  }
}
