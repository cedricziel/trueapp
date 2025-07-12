import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/models/connection_error.dart';
import 'package:truenas_manager/models/app.dart';
import 'package:truenas_manager/services/truenas_api_client.dart';
import 'package:truenas_manager/services/api_client_manager.dart';
import 'package:truenas_manager/providers/app_config_provider.dart';

class AppProvider extends ChangeNotifier {
  TrueNasApiClient? _apiClient;
  String? _currentServerId;
  List<App> _apps = [];
  List<String> _categories = [];
  bool _isLoading = false;
  ConnectionError? _connectionError;
  StreamSubscription<Map<String, AppResourceUsage>>? _appStatsSubscription;
  final Map<String, AppResourceUsage> _lastKnownResourceUsage = {};
  AppConfigProvider? _appConfigProvider;

  List<App> get apps => _apps;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  ConnectionError? get connectionError => _connectionError;
  String? get error => _connectionError?.shortMessage;

  List<App> get installedApps => _apps.where((app) => app.installed).toList();
  List<App> get availableApps => _apps.where((app) => !app.installed).toList();

  void setAppConfigProvider(AppConfigProvider? provider) {
    _appConfigProvider = provider;
  }

  Future<void> setServer(NasServer? server) async {
    // Release previous client if any
    if (_currentServerId != null) {
      await ApiClientManager.releaseClient(_currentServerId!);
    }

    _currentServerId = server?.id;
    _apiClient = null;
    _apps = [];
    _categories = [];
    _connectionError = null;

    if (server != null) {
      try {
        _apiClient = await ApiClientManager.getClient(server);
      } catch (e) {
        if (kDebugMode) {
          print('AppProvider: Failed to get API client: $e');
        }
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
    _apps = [];
    _categories = [];
    _connectionError = null;

    try {
      _apiClient = await ApiClientManager.getClient(server);
    } catch (e) {
      if (kDebugMode) {
        print('AppProvider: Failed to get API client: $e');
      }
    }
    notifyListeners();
  }

  Future<void> loadApps() async {
    if (_apiClient == null) return;

    _isLoading = true;
    _connectionError = null;
    notifyListeners();

    try {
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

      // Merge with app config data to include custom URLs and display names
      final appsWithConfig = <App>[];
      for (final app in allApps.values) {
        final appConfig = _appConfigProvider?.getAppConfig(app.name);
        if (appConfig != null) {
          appsWithConfig.add(
            App(
              name: app.name,
              title: app.title,
              description: app.description,
              installed: app.installed,
              healthy: app.healthy,
              healthyError: app.healthyError,
              latestVersion: app.latestVersion,
              latestAppVersion: app.latestAppVersion,
              latestHumanVersion: app.latestHumanVersion,
              iconUrl: app.iconUrl,
              categories: app.categories,
              home: app.home,
              tags: app.tags,
              screenshots: app.screenshots,
              sources: app.sources,
              appReadme: app.appReadme,
              maintainers: app.maintainers,
              lastUpdate: app.lastUpdate,
              recommended: app.recommended,
              catalog: app.catalog,
              train: app.train,
              resourceUsage: app.resourceUsage,
              upgradeInfo: app.upgradeInfo,
              usedPorts: app.usedPorts,
              portals: app.portals,
              customDisplayName: appConfig.displayName,
              customIconUrl: appConfig.iconUrl,
              primaryCustomUrl: appConfig.primaryPort?.effectiveUrl,
            ),
          );
        } else {
          appsWithConfig.add(app);
        }
      }

      _apps = appsWithConfig;

      // Sync portal URLs to database for installed apps
      if (_appConfigProvider != null) {
        await _appConfigProvider!.syncFromInstalledApps(installedApps);
        if (kDebugMode) {
          print(
            'AppProvider: Synced portal URLs for ${installedApps.length} installed apps',
          );
        }
      }

      // Subscribe to app stats for real-time resource usage
      _subscribeToAppStats();

      // Clear any previous errors on successful load
      _connectionError = null;
    } on ConnectionException catch (e) {
      _connectionError = e.error;
    } catch (e) {
      // Handle unexpected errors
      _connectionError = ConnectionError.unknown(details: e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshApps() async {
    await loadApps();
  }

  List<App> getAppsByCategory(String category) {
    return _apps.where((app) => app.categories.contains(category)).toList();
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
    bool hasUpdates = false;

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

    // Update app list with merged resource usage
    for (int i = 0; i < _apps.length; i++) {
      final app = _apps[i];

      if (app.installed) {
        // Get the current resource usage for this app (merged or initialize with zeros)
        final currentResourceUsage =
            _lastKnownResourceUsage[app.name] ??
            AppResourceUsage(
              cpuUsage: 0.0,
              memoryUsage: 0,
              memoryLimit: app.resourceUsage?.memoryLimit ?? 0,
              networkRxBytes: 0.0,
              networkTxBytes: 0.0,
              lastUpdated: DateTime.now(),
            );

        // Initialize with zeros if this is the first time
        if (_lastKnownResourceUsage[app.name] == null) {
          _lastKnownResourceUsage[app.name] = currentResourceUsage;
        }

        // Create updated app with current resource usage
        final updatedApp = App(
          name: app.name,
          title: app.title,
          description: app.description,
          installed: app.installed,
          healthy: app.healthy,
          healthyError: app.healthyError,
          latestVersion: app.latestVersion,
          latestAppVersion: app.latestAppVersion,
          latestHumanVersion: app.latestHumanVersion,
          iconUrl: app.iconUrl,
          categories: app.categories,
          home: app.home,
          tags: app.tags,
          screenshots: app.screenshots,
          sources: app.sources,
          appReadme: app.appReadme,
          maintainers: app.maintainers,
          lastUpdate: app.lastUpdate,
          recommended: app.recommended,
          catalog: app.catalog,
          train: app.train,
          resourceUsage: currentResourceUsage,
          upgradeInfo: app.upgradeInfo,
          usedPorts: app.usedPorts,
          portals: app.portals,
          customDisplayName: app.customDisplayName,
          customIconUrl: app.customIconUrl,
          primaryCustomUrl: app.primaryCustomUrl,
        );

        _apps[i] = updatedApp;
        hasUpdates = true;
      }
    }

    if (hasUpdates) {
      notifyListeners();
    }
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
