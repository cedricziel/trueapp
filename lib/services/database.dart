import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart' as models;
import 'package:truehub/models/app_config.dart' as app_models;

part 'database.g.dart';

@DataClassName('NasServerData')
class NasServers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get host => text()();
  TextColumn get username => text().withDefault(
    const Constant(''),
  )(); // Username is non-sensitive metadata
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

@DataClassName('AppConfigData')
class AppConfigs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId =>
      text().references(NasServers, #id, onDelete: KeyAction.cascade)();
  TextColumn get appName => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get iconUrl => text().nullable()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  // Basic app metadata for offline access
  TextColumn get title => text().nullable()();
  TextColumn get description => text().nullable()();
  BoolColumn get installed => boolean().nullable()();
  BoolColumn get healthy => boolean().nullable()();
  TextColumn get healthyError => text().nullable()();
  TextColumn get version => text().nullable()();
  TextColumn get appVersion => text().nullable()();
  TextColumn get humanVersion => text().nullable()();
  TextColumn get categories => text().nullable()(); // JSON encoded list
  TextColumn get home => text().nullable()();
  TextColumn get tags => text().nullable()(); // JSON encoded list
  BoolColumn get recommended => boolean().nullable()();
  TextColumn get catalog => text().nullable()();
  TextColumn get train => text().nullable()();
  DateTimeColumn get lastApiUpdate => dateTime().nullable()();

  // Complete app metadata for full offline access
  TextColumn get screenshots => text().nullable()(); // JSON encoded list
  TextColumn get sources => text().nullable()(); // JSON encoded list
  TextColumn get appReadme => text().nullable()();
  TextColumn get maintainersJson =>
      text().nullable()(); // JSON encoded maintainers
  TextColumn get upgradeInfoJson =>
      text().nullable()(); // JSON encoded upgrade info
  TextColumn get usedPortsJson =>
      text().nullable()(); // JSON encoded used ports
}

@DataClassName('AppPortConfigData')
class AppPortConfigs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get appConfigId =>
      integer().references(AppConfigs, #id, onDelete: KeyAction.cascade)();
  IntColumn get portNumber => integer()();
  TextColumn get protocol => text().withDefault(const Constant('http'))();
  TextColumn get serviceName => text().nullable()();
  TextColumn get customUrl => text().nullable()();
  TextColumn get apiUrl => text().nullable()(); // URL from TrueNAS API portals
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [NasServers, AppConfigs, AppPortConfigs])
class AppDatabase extends _$AppDatabase {
  static AppDatabase? _instance;

  AppDatabase._() : super(driftDatabase(name: 'truenas_manager'));

  // Singleton pattern
  static AppDatabase get instance {
    return _instance ??= AppDatabase._();
  }

  // Constructor for testing that accepts a custom QueryExecutor
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 10;

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
      if (from < 4) {
        await m.createTable(appConfigs);
        await m.createTable(appPortConfigs);
      }
      if (from < 5) {
        await m.addColumn(appConfigs, appConfigs.isFavorite);
      }
      if (from < 6) {
        await m.addColumn(appConfigs, appConfigs.title);
        await m.addColumn(appConfigs, appConfigs.description);
        await m.addColumn(appConfigs, appConfigs.installed);
        await m.addColumn(appConfigs, appConfigs.healthy);
        await m.addColumn(appConfigs, appConfigs.healthyError);
        await m.addColumn(appConfigs, appConfigs.version);
        await m.addColumn(appConfigs, appConfigs.appVersion);
        await m.addColumn(appConfigs, appConfigs.humanVersion);
        await m.addColumn(appConfigs, appConfigs.categories);
        await m.addColumn(appConfigs, appConfigs.home);
        await m.addColumn(appConfigs, appConfigs.tags);
        await m.addColumn(appConfigs, appConfigs.recommended);
        await m.addColumn(appConfigs, appConfigs.catalog);
        await m.addColumn(appConfigs, appConfigs.train);
        await m.addColumn(appConfigs, appConfigs.lastApiUpdate);
      }
      if (from < 7) {
        await m.addColumn(appConfigs, appConfigs.screenshots);
        await m.addColumn(appConfigs, appConfigs.sources);
        await m.addColumn(appConfigs, appConfigs.appReadme);
        await m.addColumn(appConfigs, appConfigs.maintainersJson);
        await m.addColumn(appConfigs, appConfigs.upgradeInfoJson);
        await m.addColumn(appConfigs, appConfigs.usedPortsJson);
      }
      if (from < 8) {
        // Clear out incorrectly set customUrl values from API portals
        // Only user-defined URLs should have customUrl set
        await customUpdate(
          'UPDATE app_port_configs SET custom_url = NULL WHERE custom_url IS NOT NULL',
        );
      }
      if (from < 9) {
        await m.addColumn(appPortConfigs, appPortConfigs.apiUrl);
      }
      if (from < 10) {
        // Re-add username column as non-sensitive metadata
        // Password remains in keychain only
        await m.addColumn(nasServers, nasServers.username);
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
        // Migration to old SecureStorageService no longer needed
        // Note: Old server credentials are handled by UnifiedServerService
        // Credentials are now handled by ServerSyncService
        // Old servers with embedded credentials will be cleaned up

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
        if (kDebugMode) {
          // Only log in debug mode to avoid cluttering production logs
          // This can be replaced with a proper logging mechanism
          print(
            'Warning: Failed to migrate some credentials to secure storage: $e',
          );
        }
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

  /// Helper method to get server with credentials from secure storage
  /// DEPRECATED: Use ServerSyncService.getPassword() instead
  // Future<models.NasServer?> getServerWithCredentials(String id) async {
  //   // This method is no longer used - credentials are handled by ServerSyncService
  //   return await getServer(id);
  // }

  // App Configuration Methods
  Future<List<AppConfigData>> getAppConfigs(String serverId) async {
    final query = select(appConfigs)
      ..where((tbl) => tbl.serverId.equals(serverId));
    return await query.get();
  }

  Future<AppConfigData?> getAppConfig(String serverId, String appName) async {
    final query = select(appConfigs)
      ..where(
        (tbl) => tbl.serverId.equals(serverId) & tbl.appName.equals(appName),
      );
    return await query.getSingleOrNull();
  }

  Future<int> insertAppConfig(AppConfigsCompanion config) async {
    return await into(appConfigs).insert(config);
  }

  Future<void> updateAppConfig(int id, AppConfigsCompanion config) async {
    await (update(appConfigs)..where((tbl) => tbl.id.equals(id))).write(config);
  }

  Future<void> deleteAppConfig(int id) async {
    await (delete(appConfigs)..where((tbl) => tbl.id.equals(id))).go();
  }

  // App Port Configuration Methods
  Future<List<AppPortConfigData>> getAppPortConfigs(int appConfigId) async {
    final query = select(appPortConfigs)
      ..where((tbl) => tbl.appConfigId.equals(appConfigId));
    return await query.get();
  }

  Future<int> insertAppPortConfig(AppPortConfigsCompanion config) async {
    return await into(appPortConfigs).insert(config);
  }

  Future<void> updateAppPortConfig(
    int id,
    AppPortConfigsCompanion config,
  ) async {
    await (update(
      appPortConfigs,
    )..where((tbl) => tbl.id.equals(id))).write(config);
  }

  Future<void> deleteAppPortConfig(int id) async {
    await (delete(appPortConfigs)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> setPrimaryPort(int appConfigId, int portConfigId) async {
    await transaction(() async {
      // Clear any existing primary port for this app
      await (update(appPortConfigs)
            ..where((tbl) => tbl.appConfigId.equals(appConfigId)))
          .write(AppPortConfigsCompanion(isPrimary: const Value(false)));
      // Set the new primary port
      await (update(appPortConfigs)
            ..where((tbl) => tbl.id.equals(portConfigId)))
          .write(AppPortConfigsCompanion(isPrimary: const Value(true)));
    });
  }

  Future<List<Map<String, dynamic>>> getAppConfigsWithPorts(
    String serverId,
  ) async {
    final query = '''
      SELECT
        ac.*,
        apc.id as port_id,
        apc.port_number,
        apc.protocol,
        apc.service_name,
        apc.custom_url,
        apc.is_primary,
        apc.is_enabled as port_enabled
      FROM app_configs ac
      LEFT JOIN app_port_configs apc ON ac.id = apc.app_config_id
      WHERE ac.server_id = ?
      ORDER BY ac.app_name, apc.is_primary DESC, apc.port_number
    ''';

    final result = await customSelect(
      query,
      variables: [Variable.withString(serverId)],
    ).get();
    return result.map((row) => row.data).toList();
  }

  // Favorite app methods
  Future<List<AppConfigData>> getFavoriteApps(String serverId) async {
    final query = select(appConfigs)
      ..where(
        (tbl) => tbl.serverId.equals(serverId) & tbl.isFavorite.equals(true),
      )
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.appName)]);
    return await query.get();
  }

  Future<void> setAppFavorite(
    String serverId,
    String appName,
    bool isFavorite,
  ) async {
    // First, get or create the app config
    var appConfig = await getAppConfig(serverId, appName);

    if (appConfig == null) {
      // Create new app config if it doesn't exist
      await insertAppConfig(
        AppConfigsCompanion(
          serverId: Value(serverId),
          appName: Value(appName),
          isFavorite: Value(isFavorite),
        ),
      );
      return;
    }

    // Update existing app config
    await updateAppConfig(
      appConfig.id,
      AppConfigsCompanion(
        isFavorite: Value(isFavorite),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<bool> isAppFavorite(String serverId, String appName) async {
    final appConfig = await getAppConfig(serverId, appName);
    return appConfig?.isFavorite ?? false;
  }

  // Helper methods to convert between AppConfigData and AppConfig models
  app_models.AppConfig mapToAppConfig(
    AppConfigData data,
    List<app_models.AppPortConfig> ports,
  ) {
    return app_models.AppConfig(
      id: data.id,
      serverId: data.serverId,
      appName: data.appName,
      displayName: data.displayName,
      iconUrl: data.iconUrl,
      isEnabled: data.isEnabled,
      isFavorite: data.isFavorite,
      ports: ports,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      title: data.title,
      description: data.description,
      installed: data.installed,
      healthy: data.healthy,
      healthyError: data.healthyError,
      version: data.version,
      appVersion: data.appVersion,
      humanVersion: data.humanVersion,
      categories: data.categories != null
          ? (jsonDecode(data.categories!) as List).cast<String>()
          : null,
      home: data.home,
      tags: data.tags != null
          ? (jsonDecode(data.tags!) as List).cast<String>()
          : null,
      recommended: data.recommended,
      catalog: data.catalog,
      train: data.train,
      lastApiUpdate: data.lastApiUpdate,
      screenshots: data.screenshots != null
          ? (jsonDecode(data.screenshots!) as List).cast<String>()
          : null,
      sources: data.sources != null
          ? (jsonDecode(data.sources!) as List).cast<String>()
          : null,
      appReadme: data.appReadme,
      maintainersJson: data.maintainersJson,
      upgradeInfoJson: data.upgradeInfoJson,
      usedPortsJson: data.usedPortsJson,
    );
  }

  AppConfigsCompanion appConfigToCompanion(app_models.AppConfig config) {
    return AppConfigsCompanion(
      id: config.id != null ? Value(config.id!) : const Value.absent(),
      serverId: Value(config.serverId),
      appName: Value(config.appName),
      displayName: Value(config.displayName),
      iconUrl: Value(config.iconUrl),
      isEnabled: Value(config.isEnabled),
      isFavorite: Value(config.isFavorite),
      createdAt: config.createdAt != null
          ? Value(config.createdAt!)
          : const Value.absent(),
      updatedAt: Value(config.updatedAt ?? DateTime.now()),
      title: Value(config.title),
      description: Value(config.description),
      installed: Value(config.installed),
      healthy: Value(config.healthy),
      healthyError: Value(config.healthyError),
      version: Value(config.version),
      appVersion: Value(config.appVersion),
      humanVersion: Value(config.humanVersion),
      categories: Value(
        config.categories != null ? jsonEncode(config.categories) : null,
      ),
      home: Value(config.home),
      tags: Value(config.tags != null ? jsonEncode(config.tags) : null),
      recommended: Value(config.recommended),
      catalog: Value(config.catalog),
      train: Value(config.train),
      lastApiUpdate: Value(config.lastApiUpdate),
      screenshots: Value(
        config.screenshots != null ? jsonEncode(config.screenshots) : null,
      ),
      sources: Value(
        config.sources != null ? jsonEncode(config.sources) : null,
      ),
      appReadme: Value(config.appReadme),
      maintainersJson: Value(config.maintainersJson),
      upgradeInfoJson: Value(config.upgradeInfoJson),
      usedPortsJson: Value(config.usedPortsJson),
    );
  }

  app_models.AppPortConfig mapToAppPortConfig(AppPortConfigData data) {
    return app_models.AppPortConfig(
      id: data.id,
      portNumber: data.portNumber,
      protocol: data.protocol,
      serviceName: data.serviceName,
      customUrl: data.customUrl,
      apiUrl: data.apiUrl,
      isPrimary: data.isPrimary,
      isEnabled: data.isEnabled,
    );
  }

  AppPortConfigsCompanion appPortConfigToCompanion(
    app_models.AppPortConfig config,
    int appConfigId,
  ) {
    return AppPortConfigsCompanion(
      id: config.id != null ? Value(config.id!) : const Value.absent(),
      appConfigId: Value(appConfigId),
      portNumber: Value(config.portNumber),
      protocol: Value(config.protocol),
      serviceName: Value(config.serviceName),
      customUrl: Value(config.customUrl),
      apiUrl: Value(config.apiUrl),
      isPrimary: Value(config.isPrimary),
      isEnabled: Value(config.isEnabled),
      createdAt: const Value.absent(),
      updatedAt: Value(DateTime.now()),
    );
  }

  // Enhanced methods to work with full AppConfig models
  Future<app_models.AppConfig?> getFullAppConfig(
    String serverId,
    String appName,
  ) async {
    final configData = await getAppConfig(serverId, appName);
    if (configData == null) return null;

    final portData = await getAppPortConfigs(configData.id);
    final ports = portData.map(mapToAppPortConfig).toList();

    return mapToAppConfig(configData, ports);
  }

  Future<List<app_models.AppConfig>> getFullAppConfigs(String serverId) async {
    final configsData = await getAppConfigs(serverId);
    final configs = <app_models.AppConfig>[];

    for (final configData in configsData) {
      final portData = await getAppPortConfigs(configData.id);
      final ports = portData.map(mapToAppPortConfig).toList();
      configs.add(mapToAppConfig(configData, ports));
    }

    return configs;
  }

  Future<int> insertFullAppConfig(app_models.AppConfig config) async {
    return await transaction(() async {
      final configId = await insertAppConfig(appConfigToCompanion(config));

      for (final port in config.ports) {
        await insertAppPortConfig(appPortConfigToCompanion(port, configId));
      }

      return configId;
    });
  }

  Future<void> updateFullAppConfig(app_models.AppConfig config) async {
    if (config.id == null) {
      throw ArgumentError('AppConfig must have an ID to be updated');
    }

    await transaction(() async {
      await updateAppConfig(config.id!, appConfigToCompanion(config));

      // Delete existing port configs and recreate them
      await (delete(
        appPortConfigs,
      )..where((tbl) => tbl.appConfigId.equals(config.id!))).go();

      for (final port in config.ports) {
        await insertAppPortConfig(appPortConfigToCompanion(port, config.id!));
      }
    });
  }

  Future<void> upsertAppConfig(app_models.AppConfig config) async {
    final existing = await getAppConfig(config.serverId, config.appName);

    if (existing == null) {
      await insertFullAppConfig(config);
    } else {
      final updatedConfig = config.copyWith(id: existing.id);
      await updateFullAppConfig(updatedConfig);
    }
  }

  /// Dispose the database singleton instance
  static Future<void> disposeInstance() async {
    await _instance?.close();
    _instance = null;
  }
}
