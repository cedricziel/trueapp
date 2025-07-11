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

        if (app.home != null) {
          final uri = Uri.tryParse(app.home!);
          if (uri != null && uri.hasPort) {
            await _database.insertAppPortConfig(
              AppPortConfigsCompanion(
                appConfigId: Value(configId),
                portNumber: Value(uri.port),
                protocol: Value(uri.scheme),
                serviceName: const Value('Web UI'),
                isPrimary: const Value(true),
              ),
            );
          }
        }
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

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
