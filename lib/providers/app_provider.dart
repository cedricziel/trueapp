import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/connection_error.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/models/app_config.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/services/api_client_manager.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/providers/server_provider.dart';

/// The result of a settled future: exactly one of [value] or [error] is set.
class _Outcome<T> {
  final T? value;
  final Object? error;

  const _Outcome.success(this.value) : error = null;
  const _Outcome.failure(this.error) : value = null;
}

/// The catalog side of a load, started alongside the installed-apps request
/// and merged in a second phase once installed apps are already visible.
typedef _CatalogRequests = ({
  Future<_Outcome<List<App>>> available,
  Future<_Outcome<List<String>>> categories,
});

class AppProvider extends ChangeNotifier {
  final AppDatabase Function() _databaseRef;
  final UnifiedServerService _serverService;
  ApiClientInterface? _apiClient;
  String? _currentServerId;
  NasServer? _currentServer;
  List<AppConfig> _appConfigs = [];
  List<String> _categories = [];
  bool _isLoading = false;
  bool _isCatalogLoading = false;
  ConnectionError? _connectionError;
  ConnectionError? _catalogError;

  /// Bumped by every load, server switch and dispose, so a catalog phase
  /// that finishes late can tell it no longer belongs to the current state.
  int _loadGeneration = 0;
  StreamSubscription<Map<String, AppResourceUsage>>? _appStatsSubscription;
  final Map<String, AppResourceUsage> _lastKnownResourceUsage = {};

  /// [databaseRef] is looked up on every access instead of being captured
  /// once, so callers that recreate the database (e.g. after a "clear
  /// database" operation disposes [AppDatabase.instance]) are picked up
  /// transparently instead of leaving this provider pinned to a closed
  /// instance. [database] remains as a convenience for callers (mainly
  /// tests) that already hold a fixed, never-disposed instance to inject;
  /// prefer [databaseRef] for anything backed by the app-wide singleton.
  AppProvider({
    AppDatabase Function()? databaseRef,
    AppDatabase? database,
    required UnifiedServerService serverService,
  }) : assert(
         databaseRef != null || database != null,
         'AppProvider requires either databaseRef or database',
       ),
       _databaseRef = databaseRef ?? (() => database!),
       _serverService = serverService;

  AppDatabase get _database => _databaseRef();

  List<AppConfig> get appConfigs => _appConfigs;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;

  /// True while the catalog (`app.available` / `app.categories`) is still
  /// being fetched or merged after the installed apps are already loaded.
  bool get isCatalogLoading => _isCatalogLoading;

  ConnectionError? get connectionError => _connectionError;
  String? get error => _connectionError?.shortMessage;

  /// The underlying cause of [error], when known - e.g. the middleware's
  /// reason text or the parse failure - for showing alongside the short
  /// message so a failure can actually be diagnosed from the screen.
  String? get errorDetails => _connectionError?.technicalDetails;

  /// Set when the installed apps loaded fine but the catalog side
  /// (`app.available` / `app.categories`) failed. The load is then only
  /// degraded, not failed: installed apps stay usable and any previously
  /// synced catalog entries remain visible, so this is surfaced per-tab
  /// rather than as [connectionError].
  ConnectionError? get catalogError => _catalogError;

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

    _loadGeneration++;
    _currentServerId = server?.id;
    _currentServer = server;
    _apiClient = null;
    _appConfigs = [];
    _categories = [];
    _connectionError = null;
    _catalogError = null;
    _isCatalogLoading = false;

    if (server != null) {
      try {
        // Load credentials for the server
        final serverWithCredentials =
            await ServerProvider.loadServerCredentials(server, _serverService);

        if (serverWithCredentials != null) {
          _apiClient = await ApiClientManager.getClient(serverWithCredentials);
        } else {
          if (kDebugMode) {
            print(
              'AppProvider: No credentials available for server ${server.id}',
            );
          }
        }
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

    _loadGeneration++;
    _currentServerId = server.id;
    _currentServer = server;
    _appConfigs = [];
    _categories = [];
    _connectionError = null;
    _catalogError = null;
    _isCatalogLoading = false;

    try {
      // Load credentials for the server
      final serverWithCredentials = await ServerProvider.loadServerCredentials(
        server,
        _serverService,
      );

      if (serverWithCredentials != null) {
        _apiClient = await ApiClientManager.getClient(serverWithCredentials);
      } else {
        if (kDebugMode) {
          print(
            'AppProvider: No credentials available for server ${server.id}',
          );
        }
      }
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
    final generation = ++_loadGeneration;

    _isLoading = true;
    _isCatalogLoading = false;
    _connectionError = null;
    _catalogError = null;
    notifyListeners();

    // The catalog requests are fired alongside the installed-apps request
    // but merged in a second phase (see [_loadCatalog]), so installed apps
    // are shown the moment they arrive. `app.available` is by far the
    // biggest and slowest response (the whole catalog, readmes included -
    // megabytes over a cellular link) and must not hold the user's own apps
    // hostage. Its failures are allowed too: installed apps (`app.query`)
    // are the essential part, the catalog is not.
    _CatalogRequests? catalog;
    try {
      final apiClient = _apiClient;
      if (apiClient != null) {
        catalog = (
          available: _settle(apiClient.getAvailableApps()),
          categories: _settle(apiClient.getAppCategories()),
        );
        await _loadInstalledAppsOnline(apiClient);

        // Subscribe to app stats for real-time resource usage
        _subscribeToAppStats();
      } else {
        // Offline mode: Load from database only
        await _loadPersistedAppConfigs();
      }

      // Clear any previous errors on successful load
      _connectionError = null;
    } on ConnectionException catch (e) {
      _connectionError = e.error;
      // Fall back to offline data if available. This fallback has its own
      // try/catch so a failure here (e.g. a database that is unavailable)
      // records a ConnectionError instead of escaping loadApps().
      await _tryLoadPersistedAppConfigs();
    } catch (e) {
      // Handle unexpected errors
      _connectionError = ConnectionError.unknown(details: e.toString());
      // Fall back to offline data if available. See note above.
      await _tryLoadPersistedAppConfigs();
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // The catalog is only worth merging on top of a successful installed
    // load. Its futures are settled, so leaving them behind leaks no error.
    if (catalog != null && _connectionError == null) {
      await _loadCatalog(generation, catalog);
    }
  }

  Future<void> _loadInstalledAppsOnline(ApiClientInterface apiClient) async {
    final installedApps = await apiClient.getInstalledApps();

    await _syncAppsToDatabase(installedApps);
    await _loadPersistedAppConfigs();

    if (kDebugMode) {
      print(
        'AppProvider: Synced ${installedApps.length} installed apps to '
        'database',
      );
    }
  }

  /// Second phase of [loadApps]: waits for the catalog requests started
  /// there and merges them on top of the already-synced installed apps.
  /// [generation] identifies the load this belongs to - a server switch or
  /// a newer load in the meantime makes this catalog stale, and it is then
  /// dropped rather than merged into the wrong server's state.
  Future<void> _loadCatalog(int generation, _CatalogRequests catalog) async {
    _isCatalogLoading = true;
    notifyListeners();

    try {
      final available = await catalog.available;
      final categories = await catalog.categories;
      if (generation != _loadGeneration) return;

      if (categories.value != null) {
        _categories = categories.value!;
      }

      final catalogFailure = available.error ?? categories.error;
      if (catalogFailure != null) {
        _catalogError = _toConnectionError(catalogFailure);
        if (kDebugMode) {
          print(
            'AppProvider: catalog load failed, keeping installed apps: '
            '${_catalogError!.technicalDetails ?? _catalogError!.message}',
          );
        }
      }

      // Installed apps were synced first and carry the richer data
      // (resource usage, upgrade info, portals); the catalog only adds the
      // apps that are not installed.
      final installedNames = _appConfigs
          .where((config) => config.installed == true)
          .map((config) => config.appName)
          .toSet();
      final availableApps = (available.value ?? const <App>[])
          .where((app) => !installedNames.contains(app.name))
          .toList();

      await _syncAppsToDatabase(availableApps);
      if (generation != _loadGeneration) return;
      await _loadPersistedAppConfigs();

      if (kDebugMode) {
        print(
          'AppProvider: Synced ${availableApps.length} available apps to '
          'database',
        );
      }
    } catch (e) {
      if (generation == _loadGeneration) {
        _catalogError = _toConnectionError(e);
      }
    } finally {
      if (generation == _loadGeneration) {
        _isCatalogLoading = false;
        notifyListeners();
      }
    }
  }

  /// Turns [future] into one that never fails, capturing its outcome as an
  /// [_Outcome] instead.
  Future<_Outcome<T>> _settle<T>(Future<T> future) => future
      .then<_Outcome<T>>(_Outcome.success)
      .catchError((Object e) => _Outcome<T>.failure(e));

  ConnectionError _toConnectionError(Object error) {
    if (error is ConnectionException) return error.error;
    return ConnectionError.unknown(details: error.toString());
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

  /// Fallback wrapper around [_loadPersistedAppConfigs] used from the
  /// catch blocks in [loadApps]. Swallows its own errors (recording a
  /// ConnectionError instead) so a broken database doesn't let a failure
  /// escape loadApps() while it is already handling one.
  Future<void> _tryLoadPersistedAppConfigs() async {
    try {
      await _loadPersistedAppConfigs();
    } catch (e) {
      _connectionError = ConnectionError.unknown(details: e.toString());
      if (kDebugMode) {
        print('AppProvider: Failed to load persisted app configs: $e');
      }
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
    // A catalog phase still in flight must not notify a disposed notifier.
    _loadGeneration++;

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
