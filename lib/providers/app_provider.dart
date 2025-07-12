import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/models/connection_error.dart';
import 'package:truenas_manager/models/app.dart';
import 'package:truenas_manager/models/app_config.dart';
import 'package:truenas_manager/services/truenas_api_client.dart';
import 'package:truenas_manager/services/api_client_manager.dart';
import 'package:truenas_manager/services/database.dart';

class AppProvider extends ChangeNotifier {
  final AppDatabase _database;
  TrueNasApiClient? _apiClient;
  String? _currentServerId;
  NasServer? _currentServer;
  List<AppConfig> _appConfigs = [];
  List<String> _categories = [];
  bool _isLoading = false;
  ConnectionError? _connectionError;
  StreamSubscription<Map<String, AppResourceUsage>>? _appStatsSubscription;
  final Map<String, AppResourceUsage> _lastKnownResourceUsage = {};

  AppProvider({required AppDatabase database}) : _database = database;

  List<AppConfig> get appConfigs => _appConfigs;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  ConnectionError? get connectionError => _connectionError;
  String? get error => _connectionError?.shortMessage;

  List<AppConfig> get installedApps =>
      _appConfigs.where((app) => app.installed == true).toList();
  List<AppConfig> get availableApps =>
      _appConfigs.where((app) => app.installed != true).toList();
  List<AppConfig> get enabledApps =>
      _appConfigs.where((app) => app.isEnabled).toList();
  List<AppConfig> get favoriteApps =>
      _appConfigs.where((app) => app.isFavorite).toList();

  // Legacy getter for backward compatibility - converts AppConfig to App-like interface
  List<App> get apps => _appConfigs.map(_appConfigToApp).toList();

  Future<void> setServer(NasServer? server) async {
    // Release previous client if any
    if (_currentServerId != null) {
      await ApiClientManager.releaseClient(_currentServerId!);
    }

    _currentServerId = server?.id;
    _currentServer = server;
    _apiClient = null;
    _appConfigs = [];
    _categories = [];
    _connectionError = null;

    if (server != null) {
      try {
        _apiClient = await ApiClientManager.getClient(server);
        // Load persisted app configs for offline access
        await _loadPersistedAppConfigs();
      } catch (e) {
        if (kDebugMode) {
          print('AppProvider: Failed to get API client: $e');
        }
        // Even if API client fails, load persisted configs for offline access
        await _loadPersistedAppConfigs();
      }
    }
    notifyListeners();
  }

  Future<void> setApiClient(NasServer server) async {
    // Release previous client if any
    if (_currentServerId != null) {
      await ApiClientManager.releaseClient(_currentServerId!);
    }

    _currentServerId = server.id;
    _currentServer = server;
    _appConfigs = [];
    _categories = [];
    _connectionError = null;

    try {
      _apiClient = await ApiClientManager.getClient(server);
      // Load persisted app configs for offline access
      await _loadPersistedAppConfigs();
    } catch (e) {
      if (kDebugMode) {
        print('AppProvider: Failed to get API client: $e');
      }
      // Even if API client fails, load persisted configs for offline access
      await _loadPersistedAppConfigs();
    }
    notifyListeners();
  }

  Future<void> loadApps() async {
    if (_currentServerId == null) return;

    _isLoading = true;
    _connectionError = null;
    notifyListeners();

    try {
      if (_apiClient != null) {
        // Online mode: Load fresh data from API and sync to database
        await _loadAppsOnline();
      } else {
        // Offline mode: Load from database only
        await _loadPersistedAppConfigs();
      }

      // Subscribe to app stats for real-time resource usage (if online)
      if (_apiClient != null) {
        _subscribeToAppStats();
      }

      // Clear any previous errors on successful load
      _connectionError = null;
    } on ConnectionException catch (e) {
      _connectionError = e.error;
      // Fall back to offline data if available
      await _loadPersistedAppConfigs();
    } catch (e) {
      // Handle unexpected errors
      _connectionError = ConnectionError.unknown(details: e.toString());
      // Fall back to offline data if available
      await _loadPersistedAppConfigs();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAppsOnline() async {
    if (_apiClient == null || _currentServerId == null) return;

    // Load available apps, installed apps, and categories in parallel
    final results = await Future.wait([
      _apiClient!.getAvailableApps(),
      _apiClient!.getInstalledApps(),
      _apiClient!.getAppCategories(),
    ]);

    final availableApps = results[0] as List<App>;
    final installedApps = results[1] as List<App>;
    _categories = results[2] as List<String>;

    // Merge installed and available apps, prioritizing installed app data
    final allApps = <String, App>{};

    // Add available apps first
    for (final app in availableApps) {
      allApps[app.name] = app;
    }

    // Override with installed app data (which includes resource usage and upgrade info)
    for (final app in installedApps) {
      allApps[app.name] = app;
    }

    // Sync all app data to database as unified AppConfig records
    await _syncAppsToDatabase(allApps.values.toList());

    // Load the updated app configs from database (which now includes merged data)
    await _loadPersistedAppConfigs();

    if (kDebugMode) {
      print(
        'AppProvider: Synced ${allApps.length} apps to database (${installedApps.length} installed, ${availableApps.length} available)',
      );
    }
  }

  Future<void> _syncAppsToDatabase(List<App> apps) async {
    if (_currentServerId == null) return;

    for (final app in apps) {
      // Get existing config if any
      final existingConfig = await _database.getFullAppConfig(
        _currentServerId!,
        app.name,
      );

      if (existingConfig != null) {
        // Update existing config with fresh API data while preserving user customizations
        final updatedConfig = existingConfig
            .updateFromApp(app)
            .copyWith(
              // Preserve user customizations
              displayName: existingConfig.displayName,
              iconUrl: existingConfig.iconUrl ?? app.iconUrl,
              isEnabled: existingConfig.isEnabled,
              isFavorite: existingConfig.isFavorite,
              ports:
                  existingConfig.ports, // Preserve existing port configurations
            );
        await _database.updateFullAppConfig(updatedConfig);
      } else {
        // Create new config from app data
        final newConfig = AppConfig.fromApp(
          serverId: _currentServerId!,
          app: app,
        );
        await _database.insertFullAppConfig(newConfig);
      }

      // Sync portal URLs for installed apps
      if (app.installed) {
        await _syncPortalUrls(app);
      }
    }
  }

  Future<void> _loadPersistedAppConfigs() async {
    if (_currentServerId == null) return;

    _appConfigs = await _database.getFullAppConfigs(_currentServerId!);

    if (kDebugMode) {
      print('AppProvider: Loaded ${_appConfigs.length} persisted app configs');
    }
  }

  Future<void> refreshApps() async {
    await loadApps();
  }

  List<AppConfig> getAppsByCategory(String category) {
    return _appConfigs
        .where((app) => app.categories?.contains(category) == true)
        .toList();
  }

  Future<bool> upgradeApp(String appName, {String? version}) async {
    if (_apiClient == null) return false;

    try {
      final result = await _apiClient!.upgradeApp(appName, version: version);
      if (result) {
        // Refresh apps after successful upgrade
        await loadApps();
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('AppProvider: Failed to upgrade app $appName: $e');
      }
      return false;
    }
  }

  Future<bool> startApp(String appName) async {
    if (_apiClient == null) return false;

    try {
      final result = await _apiClient!.startApp(appName);
      if (result) {
        // Refresh apps after successful start
        await loadApps();
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('AppProvider: Failed to start app $appName: $e');
      }
      return false;
    }
  }

  Future<bool> stopApp(String appName) async {
    if (_apiClient == null) return false;

    try {
      final result = await _apiClient!.stopApp(appName);
      if (result) {
        // Refresh apps after successful stop
        await loadApps();
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('AppProvider: Failed to stop app $appName: $e');
      }
      return false;
    }
  }

  Future<bool> restartApp(String appName) async {
    if (_apiClient == null) return false;

    try {
      final result = await _apiClient!.restartApp(appName);
      if (result) {
        // Refresh apps after successful restart
        await loadApps();
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('AppProvider: Failed to restart app $appName: $e');
      }
      return false;
    }
  }

  void _subscribeToAppStats() async {
    if (_apiClient == null) return;

    // Cancel existing subscription if any
    await _appStatsSubscription?.cancel();

    try {
      // Subscribe to app stats from the API client
      await _apiClient!.subscribeToAppStats();

      // Listen to the app stats stream and update resource usage
      _appStatsSubscription = _apiClient!.appStatsStream.listen(
        (appStatsMap) {
          if (kDebugMode) {
            print(
              'AppProvider: Received app stats for ${appStatsMap.length} apps',
            );
          }

          // Update resource usage for each app
          _updateAppResourceUsage(appStatsMap);
        },
        onError: (error) {
          if (kDebugMode) {
            print('AppProvider: Error in app stats stream: $error');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('AppProvider: Failed to subscribe to app stats: $e');
      }
    }
  }

  void _updateAppResourceUsage(Map<String, AppResourceUsage> appStatsMap) {
    // Update the last known resource usage for each app in the new data
    for (final entry in appStatsMap.entries) {
      final appName = entry.key;
      final newResourceUsage = entry.value;

      // Merge with existing resource usage to preserve values not in this update
      final existingResourceUsage = _lastKnownResourceUsage[appName];
      if (existingResourceUsage != null) {
        // Only update fields that have actual values (not zeros)
        _lastKnownResourceUsage[appName] = AppResourceUsage(
          cpuUsage: newResourceUsage.cpuUsage > 0
              ? newResourceUsage.cpuUsage
              : existingResourceUsage.cpuUsage,
          memoryUsage: newResourceUsage.memoryUsage > 0
              ? newResourceUsage.memoryUsage
              : existingResourceUsage.memoryUsage,
          memoryLimit: newResourceUsage.memoryLimit > 0
              ? newResourceUsage.memoryLimit
              : existingResourceUsage.memoryLimit,
          networkRxBytes: newResourceUsage.networkRxBytes > 0
              ? newResourceUsage.networkRxBytes
              : existingResourceUsage.networkRxBytes,
          networkTxBytes: newResourceUsage.networkTxBytes > 0
              ? newResourceUsage.networkTxBytes
              : existingResourceUsage.networkTxBytes,
          lastUpdated: DateTime.now(),
        );
      } else {
        // First time seeing this app, store as is
        _lastKnownResourceUsage[appName] = newResourceUsage;
      }
    }

    // Note: Real-time resource usage is now maintained in memory only
    // The AppConfig models in _appConfigs retain their persisted state
    // while resource usage updates are applied when converting to App via _appConfigToApp
    notifyListeners();
  }

  Future<void> _unsubscribeFromAppStats() async {
    await _appStatsSubscription?.cancel();
    _appStatsSubscription = null;

    if (_apiClient != null) {
      try {
        await _apiClient!.unsubscribeFromAppStats();
      } catch (e) {
        if (kDebugMode) {
          print('AppProvider: Failed to unsubscribe from app stats: $e');
        }
      }
    }
  }

  // Helper methods for working with AppConfig/App conversions and management
  Future<void> _syncPortalUrls(App app) async {
    if (_currentServerId == null) return;

    final existingConfig = await _database.getFullAppConfig(
      _currentServerId!,
      app.name,
    );
    if (existingConfig?.id == null) return;

    // Get existing port configs for this app
    final existingPorts = await _database.getAppPortConfigs(
      existingConfig!.id!,
    );
    final existingPortsMap = <int, AppPortConfigData>{};
    for (final port in existingPorts) {
      existingPortsMap[port.portNumber] = port;
    }

    final processedPorts = <int>{};
    bool hasPrimary = existingPorts.any((port) => port.isPrimary);

    // Sync from app.portals (new structured data)
    for (final portal in app.portals.entries) {
      final uri = Uri.tryParse(portal.value);
      if (uri != null && uri.hasPort) {
        processedPorts.add(uri.port);
        final existingPort = existingPortsMap[uri.port];

        if (existingPort == null) {
          await _database.insertAppPortConfig(
            AppPortConfigsCompanion(
              appConfigId: Value(existingConfig.id!),
              portNumber: Value(uri.port),
              protocol: Value(uri.scheme),
              serviceName: Value(portal.key),
              apiUrl: Value(
                portal.value,
              ), // Store API URL separately from custom URL
              isPrimary: Value(!hasPrimary), // First port becomes primary
            ),
          );
          if (!hasPrimary) hasPrimary = true;
        }
      }
    }
  }

  App _appConfigToApp(AppConfig config) {
    // Get real-time resource usage if available
    final resourceUsage = _lastKnownResourceUsage[config.appName];

    return App(
      name: config.appName,
      title: config.title ?? config.appName,
      description: config.description ?? '',
      installed: config.installed ?? false,
      healthy: config.healthy ?? true,
      healthyError: config.healthyError,
      latestVersion: config.version ?? '',
      latestAppVersion: config.appVersion ?? '',
      latestHumanVersion: config.humanVersion ?? '',
      iconUrl: config.iconUrl,
      categories: config.categories ?? [],
      home: config.home,
      tags: config.tags ?? [],
      screenshots: config.screenshots ?? [],
      sources: config.sources ?? [],
      appReadme: config.appReadme,
      maintainers: config.maintainers,
      lastUpdate: config.lastApiUpdate,
      recommended: config.recommended ?? false,
      catalog: config.catalog ?? '',
      train: config.train ?? '',
      resourceUsage: resourceUsage, // Include real-time resource usage
      upgradeInfo: config.upgradeInfo,
      usedPorts: config.usedPorts,
      portals: _buildPortalsFromConfig(config),
      customDisplayName: config.displayName,
      customIconUrl: config.iconUrl,
      primaryCustomUrl: config.primaryPort?.customUrl != null
          ? _interpolateUrl(config.primaryPort!.customUrl!)
          : null,
    );
  }

  String _interpolateUrl(String url) {
    if (_currentServer == null) return url;

    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    // Replace localhost with actual server host
    String host = uri.host;
    if (host == 'localhost' || host == '127.0.0.1') {
      host = _currentServer!.host;
    }

    // Replace tcp protocol with http/https based on server config
    String scheme = uri.scheme;
    if (scheme == 'tcp') {
      scheme = _currentServer!.useHttps ? 'https' : 'http';
    }

    // Reconstruct the URL with proper host and protocol
    return Uri(
      scheme: scheme,
      host: host,
      port: uri.port,
      path: uri.path,
      query: uri.query.isEmpty ? null : uri.query,
      fragment: uri.fragment.isEmpty ? null : uri.fragment,
    ).toString();
  }

  Map<String, String> _buildPortalsFromConfig(AppConfig config) {
    final portals = <String, String>{};
    for (final port in config.enabledPorts) {
      // Include all enabled ports - prioritize custom URL, then API URL, then default
      final rawUrl = port.effectiveUrl;
      final interpolatedUrl = _interpolateUrl(rawUrl);
      portals[port.serviceName ?? 'Port ${port.portNumber}'] = interpolatedUrl;
    }
    return portals;
  }

  // App configuration management methods
  Future<void> updateAppConfig(AppConfig config) async {
    await _database.updateFullAppConfig(config);
    await _loadPersistedAppConfigs();
    notifyListeners();
  }

  Future<void> setAppFavorite(String appName, bool isFavorite) async {
    if (_currentServerId == null) return;

    await _database.setAppFavorite(_currentServerId!, appName, isFavorite);
    await _loadPersistedAppConfigs();
    notifyListeners();
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
    final url = config?.primaryPort?.effectiveUrl;
    return url != null ? _interpolateUrl(url) : null;
  }

  List<String> getAppUrls(String appName) {
    final config = getAppConfig(appName);
    if (config == null) return [];
    return config.enabledPorts
        .map((port) => _interpolateUrl(port.effectiveUrl))
        .toList();
  }

  bool isAppFavorite(String appName) {
    final config = getAppConfig(appName);
    return config?.isFavorite ?? false;
  }

  List<AppConfig> getAppsWithPortals() {
    return _appConfigs.where((config) {
      return config.ports.isNotEmpty &&
          config.ports.any((port) => port.customUrl != null || port.isPrimary);
    }).toList();
  }

  @override
  void dispose() {
    // Unsubscribe from app stats
    _unsubscribeFromAppStats();

    // Clear cached resource usage
    _lastKnownResourceUsage.clear();

    if (_currentServerId != null) {
      // Note: We can't await in dispose, so we do a fire-and-forget cleanup
      ApiClientManager.releaseClient(_currentServerId!);
    }
    super.dispose();
  }
}
