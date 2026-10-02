import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:truehub/models/app_config.dart' as app_models;
import 'package:truehub/services/database.dart';

part 'app_configs_dao.g.dart';

@DriftAccessor(tables: [AppConfigs, AppPortConfigs])
class AppConfigsDao extends DatabaseAccessor<AppDatabase>
    with _$AppConfigsDaoMixin {
  AppConfigsDao(super.attachedDatabase);

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
}
