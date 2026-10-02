import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:truehub/providers/active_server_follower.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/connection_error.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/models/app_config.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/services/api_client_manager_interface.dart';
import 'package:truehub/services/apps/app_config_mapper.dart';
import 'package:truehub/services/apps/app_config_repository.dart';
import 'package:truehub/services/apps/app_stats_tracker.dart';
import 'package:truehub/services/apps/catalog_requests.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/server_client_session.dart';
import 'package:truehub/services/telemetry_service_interface.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/services/app_logger.dart';
import 'package:truehub/services/tray_status_ports.dart';

final _log = appLogger('providers.app');

class AppProvider extends ChangeNotifier
    with ActiveServerFollower
    implements TrayAppsSource {
  final AppConfigRepository _repository;
  final ServerClientSession _session;
  final TelemetryServiceInterface? _telemetryService;
  late final AppStatsTracker _stats;
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

  /// [daoSource] is resolved on every access rather than captured, so a
  /// source backed by an [AppDatabaseHolder] follows a recreated database
  /// (e.g. after "clear database") instead of pinning a closed one.
  AppProvider({
    required DaoSource daoSource,
    required UnifiedServerService serverService,
    required ApiClientManagerInterface clientManager,
    TelemetryServiceInterface? telemetryService,
    ValueListenable<NasServer?>? activeServer,
  }) : _repository = AppConfigRepository(
         daoSource: daoSource,
         serverService: serverService,
       ),
       _telemetryService = telemetryService,
       _session = ServerClientSession(
         owner: 'AppProvider',
         clientManager: clientManager,
         credentials: serverService,
         telemetry: telemetryService,
       ) {
    _stats = AppStatsTracker(
      onChanged: notifyListeners,
      telemetryService: telemetryService,
    );
    followActiveServer(activeServer);
  }

  ApiClientInterface? get _apiClient => _session.client;
  String? get _currentServerId => _session.serverId;
  AppConfigMapper get _mapper => AppConfigMapper(_currentServer);

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
  List<App> get apps {
    final mapper = _mapper;
    return _appConfigs
        .map(
          (config) => mapper.toApp(
            config,
            resourceUsage: _stats.usageFor(config.appName),
          ),
        )
        .toList();
  }

  @override
  Future<void> setServer(NasServer? server) async {
    _loadGeneration++;
    unawaited(_stats.unsubscribe(_apiClient));
    _stats.clear();
    _currentServer = server;
    _appConfigs = [];
    _categories = [];
    _connectionError = null;
    _catalogError = null;
    _isCatalogLoading = false;

    if (server == null) {
      await _session.disconnect();
    } else {
      if (!await _session.connect(server)) return;
      try {
        await _loadPersistedAppConfigs();
      } catch (e, stackTrace) {
        _telemetryService?.recordError(
          e,
          stackTrace,
          context: 'AppProvider.setServer',
        );
      }
    }
    notifyListeners();
  }

  Future<void> loadApps() async {
    final pendingSwitch = pendingServerSwitch;
    if (pendingSwitch != null) await pendingSwitch;
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
    CatalogRequests? catalog;
    try {
      final apiClient = _apiClient;
      if (apiClient != null) {
        catalog = CatalogRequests.start(apiClient);
        await _loadInstalledAppsOnline(apiClient);

        unawaited(_stats.subscribe(apiClient));
      } else {
        // Offline mode: Load from database only
        await _loadPersistedAppConfigs();
      }

      // Clear any previous errors on successful load
      _connectionError = null;
    } on ConnectionException catch (e, stackTrace) {
      _connectionError = e.error;
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'AppProvider.loadApps',
      );
      // Fall back to offline data if available. This fallback has its own
      // try/catch so a failure here (e.g. a database that is unavailable)
      // records a ConnectionError instead of escaping loadApps().
      await _tryLoadPersistedAppConfigs();
    } catch (e, stackTrace) {
      // Handle unexpected errors
      _connectionError = ConnectionError.unknown(details: e.toString());
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'AppProvider.loadApps',
      );
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

    _log.debug(
      'Synced ${installedApps.length} installed apps to '
      'database',
    );
  }

  /// Second phase of [loadApps]: waits for the catalog requests started
  /// there and merges them on top of the already-synced installed apps.
  /// [generation] identifies the load this belongs to - a server switch or
  /// a newer load in the meantime makes this catalog stale, and it is then
  /// dropped rather than merged into the wrong server's state.
  Future<void> _loadCatalog(int generation, CatalogRequests catalog) async {
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
        _log.warn(
          'catalog load failed, keeping installed apps: '
          '${_catalogError!.technicalDetails ?? _catalogError!.message}',
        );
        final catalogFailureStackTrace =
            (available.error != null
                ? available.stackTrace
                : categories.stackTrace) ??
            StackTrace.current;
        _telemetryService?.recordError(
          catalogFailure,
          catalogFailureStackTrace,
          context: 'AppProvider._loadCatalog (catalog fetch)',
        );
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

      _log.debug(
        'Synced ${availableApps.length} available apps to '
        'database',
      );
    } catch (e, stackTrace) {
      if (generation == _loadGeneration) {
        _catalogError = _toConnectionError(e);
      }
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'AppProvider._loadCatalog',
      );
    } finally {
      if (generation == _loadGeneration) {
        _isCatalogLoading = false;
        notifyListeners();
      }
    }
  }

  ConnectionError _toConnectionError(Object error) {
    if (error is ConnectionException) return error.error;
    return ConnectionError.unknown(details: error.toString());
  }

  Future<void> _syncAppsToDatabase(List<App> apps) async {
    final serverId = _currentServerId;
    if (serverId == null) return;
    await _repository.syncApps(
      serverId: serverId,
      server: _currentServer,
      apps: apps,
    );
  }

  Future<void> _loadPersistedAppConfigs() async {
    final serverId = _currentServerId;
    if (serverId == null) return;
    _appConfigs = await _repository.load(serverId);
  }

  /// Fallback wrapper around [_loadPersistedAppConfigs] used from the
  /// catch blocks in [loadApps]. Swallows its own errors (recording a
  /// ConnectionError instead) so a broken database doesn't let a failure
  /// escape loadApps() while it is already handling one.
  Future<void> _tryLoadPersistedAppConfigs() async {
    try {
      await _loadPersistedAppConfigs();
    } catch (e, stackTrace) {
      _connectionError = ConnectionError.unknown(details: e.toString());
      _log.error('Failed to load persisted app configs', error: e);
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'AppProvider._tryLoadPersistedAppConfigs',
      );
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

  Future<bool> upgradeApp(String appName, {String? version}) => _runAction(
    'upgrade',
    appName,
    (client) => client.upgradeApp(appName, version: version),
  );

  Future<bool> startApp(String appName) =>
      _runAction('start', appName, (client) => client.startApp(appName));

  Future<bool> stopApp(String appName) =>
      _runAction('stop', appName, (client) => client.stopApp(appName));

  Future<bool> restartApp(String appName) =>
      _runAction('restart', appName, (client) => client.restartApp(appName));

  /// Runs a lifecycle action against the API and reloads the apps on
  /// success. Failures are logged and reported, never thrown.
  Future<bool> _runAction(
    String verb,
    String appName,
    Future<bool> Function(ApiClientInterface client) action,
  ) async {
    final client = _apiClient;
    if (client == null) return false;

    try {
      final result = await action(client);
      if (result) {
        await loadApps();
      }
      return result;
    } catch (e, stackTrace) {
      _log.error(
        'Failed to $verb app',
        error: e,
        attributes: {'app.name': appName},
      );
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'AppProvider.${verb}App',
      );
      return false;
    }
  }

  Future<void> updateAppConfig(AppConfig config) async {
    await _repository.update(config);
    await _loadPersistedAppConfigs();
    notifyListeners();
  }

  Future<void> setAppFavorite(String appName, bool isFavorite) async {
    final serverId = _currentServerId;
    if (serverId == null) return;

    await _repository.setFavorite(serverId, appName, isFavorite);
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
    final url = getAppConfig(appName)?.primaryPort?.effectiveUrl;
    return url != null ? _mapper.interpolateUrl(url) : null;
  }

  List<String> getAppUrls(String appName) {
    final config = getAppConfig(appName);
    if (config == null) return [];
    final mapper = _mapper;
    return config.enabledPorts
        .map((port) => mapper.interpolateUrl(port.effectiveUrl))
        .toList();
  }

  bool isAppFavorite(String appName) {
    final config = getAppConfig(appName);
    return config?.isFavorite ?? false;
  }

  @override
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

    unawaited(_stats.unsubscribe(_apiClient));
    _stats.clear();

    _session.dispose();
    super.dispose();
  }
}
