import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:truenas_manager/models/app_config.dart';
import 'package:truenas_manager/models/app.dart';
import 'package:truenas_manager/services/database.dart';

class AppConfigProvider extends ChangeNotifier {
  final AppDatabase _database;
  String? _currentServerId;
  List<AppConfig> _appConfigs = [];
  bool _isLoading = false;

  AppConfigProvider({required AppDatabase database}) : _database = database;

  List<AppConfig> get appConfigs => _appConfigs;
  bool get isLoading => _isLoading;
  List<AppConfig> get enabledAppConfigs =>
      _appConfigs.where((config) => config.isEnabled).toList();
  List<AppConfig> get favoriteAppConfigs =>
      _appConfigs.where((config) => config.isFavorite).toList();

  Future<void> setServer(String? serverId) async {
    _currentServerId = serverId;
    _appConfigs = [];
    if (serverId != null) {
      await loadAppConfigs();
    }
    notifyListeners();
  }

  Future<void> loadAppConfigs() async {
    if (_currentServerId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final configsWithPorts = await _database.getAppConfigsWithPorts(
        _currentServerId!,
      );
      _appConfigs = _groupConfigsWithPorts(configsWithPorts);
    } catch (e) {
      if (kDebugMode) {
        print('AppConfigProvider: Failed to load app configs: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<AppConfig> _groupConfigsWithPorts(List<Map<String, dynamic>> rows) {
    final Map<int, AppConfig> configMap = {};
    final Map<int, List<AppPortConfig>> portMap = {};

    for (final row in rows) {
      final configId = row['id'] as int;

      if (!configMap.containsKey(configId)) {
        configMap[configId] = AppConfig(
          id: configId,
          serverId: row['server_id'] as String,
          appName: row['app_name'] as String,
          displayName: row['display_name'] as String?,
          iconUrl: row['icon_url'] as String?,
          isEnabled: (row['is_enabled'] as int?) == 1,
          isFavorite: (row['is_favorite'] as int?) == 1,
          createdAt: _parseDateTime(row['created_at']),
          updatedAt: _parseDateTime(row['updated_at']),
        );
        portMap[configId] = [];
      }

      if (row['port_id'] != null) {
        portMap[configId] = portMap[configId] ?? [];
        portMap[configId]!.add(
          AppPortConfig(
            id: row['port_id'] as int,
            portNumber: row['port_number'] as int,
            protocol: row['protocol'] as String,
            serviceName: row['service_name'] as String?,
            customUrl: row['custom_url'] as String?,
            isPrimary: (row['is_primary'] as int?) == 1,
            isEnabled: (row['port_enabled'] as int?) == 1,
          ),
        );
      }
    }

    return configMap.values
        .map((config) => config.copyWith(ports: portMap[config.id] ?? []))
        .toList();
  }

  Future<void> syncFromInstalledApps(List<App> installedApps) async {
    if (_currentServerId == null) return;

    for (final app in installedApps) {
      final existingConfig = await _database.getAppConfig(
        _currentServerId!,
        app.name,
      );

      if (existingConfig == null) {
        final configId = await _database.insertAppConfig(
          AppConfigsCompanion(
            serverId: Value(_currentServerId!),
            appName: Value(app.name),
            displayName: Value(app.title),
            iconUrl: Value(app.iconUrl),
          ),
        );

        // Sync portal URLs from TrueNAS API
        await _syncPortalUrls(configId, app);
      } else {
        // Update existing config with latest portal URLs
        await _syncPortalUrls(existingConfig.id, app);
      }
    }

    await loadAppConfigs();
  }

  Future<void> updateAppConfig(AppConfig config) async {
    if (config.id == null) return;

    await _database.updateAppConfig(
      config.id!,
      AppConfigsCompanion(
        displayName: Value(config.displayName),
        iconUrl: Value(config.iconUrl),
        isEnabled: Value(config.isEnabled),
        updatedAt: Value(DateTime.now()),
      ),
    );

    await loadAppConfigs();
  }

  Future<void> updatePortConfig(int appConfigId, AppPortConfig port) async {
    if (port.id == null) return;

    await _database.updateAppPortConfig(
      port.id!,
      AppPortConfigsCompanion(
        serviceName: Value(port.serviceName),
        customUrl: Value(port.customUrl),
        isEnabled: Value(port.isEnabled),
        updatedAt: Value(DateTime.now()),
      ),
    );

    if (port.isPrimary) {
      await _database.setPrimaryPort(appConfigId, port.id!);
    }

    await loadAppConfigs();
  }

  Future<void> addPortConfig(int appConfigId, AppPortConfig port) async {
    await _database.insertAppPortConfig(
      AppPortConfigsCompanion(
        appConfigId: Value(appConfigId),
        portNumber: Value(port.portNumber),
        protocol: Value(port.protocol),
        serviceName: Value(port.serviceName),
        customUrl: Value(port.customUrl),
        isPrimary: Value(port.isPrimary),
        isEnabled: Value(port.isEnabled),
      ),
    );

    if (port.isPrimary) {
      final configs = await _database.getAppPortConfigs(appConfigId);
      final newPortId = configs.last.id;
      await _database.setPrimaryPort(appConfigId, newPortId);
    }

    await loadAppConfigs();
  }

  Future<void> deletePortConfig(int portId) async {
    await _database.deleteAppPortConfig(portId);
    await loadAppConfigs();
  }

  Future<void> setPrimaryPort(int appConfigId, int portId) async {
    await _database.setPrimaryPort(appConfigId, portId);
    await loadAppConfigs();
  }

  AppConfig? getAppConfig(String appName) {
    try {
      return _appConfigs.firstWhere((config) => config.appName == appName);
    } catch (e) {
      return null;
    }
  }

  String? getPrimaryUrl(String appName) {
    final config = getAppConfig(appName);
    return config?.primaryPort?.effectiveUrl;
  }

  List<String> getAppUrls(String appName) {
    final config = getAppConfig(appName);
    if (config == null) return [];

    return config.enabledPorts.map((port) => port.effectiveUrl).toList();
  }

  Future<void> setAppFavorite(String appName, bool isFavorite) async {
    if (_currentServerId == null) return;

    await _database.setAppFavorite(_currentServerId!, appName, isFavorite);
    await loadAppConfigs();
  }

  bool isAppFavorite(String appName) {
    final config = getAppConfig(appName);
    return config?.isFavorite ?? false;
  }

  Future<List<AppConfig>> getFavoriteApps() async {
    if (_currentServerId == null) return [];

    final favoriteConfigs = await _database.getFavoriteApps(_currentServerId!);
    return favoriteConfigs.map((config) {
      return AppConfig(
        id: config.id,
        serverId: config.serverId,
        appName: config.appName,
        displayName: config.displayName,
        iconUrl: config.iconUrl,
        isEnabled: config.isEnabled,
        isFavorite: config.isFavorite,
        createdAt: config.createdAt,
        updatedAt: config.updatedAt,
      );
    }).toList();
  }

  Future<List<AppConfig>> getAppsWithPortals() async {
    if (_currentServerId == null) {
      if (kDebugMode) {
        print('getAppsWithPortals: No current server ID');
      }
      return [];
    }

    final configsWithPorts = await _database.getAppConfigsWithPorts(
      _currentServerId!,
    );
    if (kDebugMode) {
      print('getAppsWithPortals: Found ${configsWithPorts.length} config rows');
    }
    final appConfigsWithPortals = <AppConfig>[];

    // Group the results by app config ID
    final configMap = <int, List<Map<String, dynamic>>>{};
    for (final row in configsWithPorts) {
      final configId = row['id'] as int;
      configMap[configId] = configMap[configId] ?? [];
      configMap[configId]!.add(row);
    }

    for (final entry in configMap.entries) {
      final configId = entry.key;
      final rows = entry.value;
      final firstRow = rows.first;

      // Build port configs from the rows
      final ports = <AppPortConfig>[];
      for (final row in rows) {
        if (row['port_id'] != null) {
          ports.add(
            AppPortConfig(
              id: row['port_id'] as int,
              portNumber: row['port_number'] as int,
              protocol: row['protocol'] as String,
              serviceName: row['service_name'] as String?,
              customUrl: row['custom_url'] as String?,
              isPrimary: (row['is_primary'] as int?) == 1,
              isEnabled: (row['port_enabled'] as int?) == 1,
            ),
          );
        }
      }

      // Only include apps that have portal URLs (either custom URLs or primary ports)
      if (ports.isNotEmpty &&
          ports.any((port) => port.customUrl != null || port.isPrimary)) {
        appConfigsWithPortals.add(
          AppConfig(
            id: configId,
            serverId: firstRow['server_id'] as String,
            appName: firstRow['app_name'] as String,
            displayName: firstRow['display_name'] as String?,
            iconUrl: firstRow['icon_url'] as String?,
            isEnabled: (firstRow['is_enabled'] as int?) == 1,
            isFavorite: (firstRow['is_favorite'] as int?) == 1,
            ports: ports,
            createdAt: _parseDateTime(firstRow['created_at']),
            updatedAt: _parseDateTime(firstRow['updated_at']),
          ),
        );
      }
    }

    return appConfigsWithPortals;
  }

  Future<void> _syncPortalUrls(int appConfigId, App app) async {
    if (kDebugMode) {
      print('Syncing portal URLs for app: ${app.name}');
      print('  - Home URL: ${app.home}');
      print('  - Portals: ${app.portals}');
      print('  - Used Ports: ${app.usedPorts.length}');
    }

    // Get existing port configs for this app
    final existingPorts = await _database.getAppPortConfigs(appConfigId);

    // Create a map of existing ports by port number for efficient lookup
    final existingPortsMap = <int, AppPortConfigData>{};
    for (final port in existingPorts) {
      existingPortsMap[port.portNumber] = port;
    }

    // Track which ports we've processed to identify unused ones
    final processedPorts = <int>{};
    bool hasPrimary = existingPorts.any((port) => port.isPrimary);

    // Sync from app.home (legacy field)
    if (app.home != null) {
      final uri = Uri.tryParse(app.home!);
      if (uri != null && uri.hasPort) {
        processedPorts.add(uri.port);
        final existingPort = existingPortsMap[uri.port];

        if (existingPort == null) {
          await _database.insertAppPortConfig(
            AppPortConfigsCompanion(
              appConfigId: Value(appConfigId),
              portNumber: Value(uri.port),
              protocol: Value(uri.scheme),
              serviceName: const Value('Web UI'),
              isPrimary: Value(!hasPrimary), // First port becomes primary
            ),
          );
          if (!hasPrimary) hasPrimary = true;
        }
      }
    }

    // Sync from app.portals (new structured data)
    for (final portal in app.portals.entries) {
      final uri = Uri.tryParse(portal.value);
      if (uri != null && uri.hasPort) {
        processedPorts.add(uri.port);
        final existingPort = existingPortsMap[uri.port];

        if (existingPort == null) {
          await _database.insertAppPortConfig(
            AppPortConfigsCompanion(
              appConfigId: Value(appConfigId),
              portNumber: Value(uri.port),
              protocol: Value(uri.scheme),
              serviceName: Value(portal.key),
              customUrl: Value(portal.value),
              isPrimary: Value(!hasPrimary), // First port becomes primary
            ),
          );
          if (!hasPrimary) hasPrimary = true;
        } else {
          // Update existing port with latest information
          await _database.updateAppPortConfig(
            existingPort.id,
            AppPortConfigsCompanion(
              serviceName: Value(portal.key),
              customUrl: Value(portal.value),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
      }
    }

    // Sync from app.usedPorts (port information without URLs)
    for (final port in app.usedPorts) {
      if (port.hostPorts.isNotEmpty) {
        final hostPort = port.hostPorts.first.hostPort;
        processedPorts.add(hostPort);
        final existingPort = existingPortsMap[hostPort];

        if (existingPort == null) {
          await _database.insertAppPortConfig(
            AppPortConfigsCompanion(
              appConfigId: Value(appConfigId),
              portNumber: Value(hostPort),
              protocol: Value(port.protocol),
              serviceName: Value('${port.protocol.toUpperCase()} Service'),
              isPrimary: Value(!hasPrimary), // First port becomes primary
            ),
          );
          if (!hasPrimary) hasPrimary = true;
        }
      }
    }
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
