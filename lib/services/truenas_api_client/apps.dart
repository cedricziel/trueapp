part of '../truenas_api_client.dart';

mixin _AppsOps on _ClientTransport implements AppsApi {
  @override
  Future<List<App>> getAvailableApps() async {
    try {
      return await _traced('truenas.apps.available', () async {
        final result = await _sendRequest('app.available');
        return _parseAppList(result, App.fromJson, method: 'app.available');
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<App>> getInstalledApps() async {
    try {
      return await _traced('truenas.apps.installed', () async {
        final result = await _sendRequest('app.query');
        return _parseAppList(
          result,
          _convertTrueNasAppToApp,
          method: 'app.query',
        );
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Parses a list-of-apps response entry by entry, so one app the server
  /// describes in an unexpected shape doesn't take the whole list down with
  /// it. TrueNAS has changed individual fields across releases more than
  /// once (`last_update`, `last_updated`, ...) and every such change used to
  /// surface as a bare "Connection error" for *all* apps. A skipped entry is
  /// logged with its name and cause; only when nothing at all could be
  /// parsed does this throw, since that means the whole response shape is
  /// off rather than one entry.
  List<App> _parseAppList(
    Object? result,
    App Function(Map<String, dynamic>) parse, {
    required String method,
  }) {
    if (result is! List) {
      throw FormatException(
        '$method: expected a list of apps, got ${result.runtimeType}',
      );
    }

    final apps = <App>[];
    Object? firstFailure;
    StackTrace? firstStackTrace;
    String? firstFailedName;
    var skipped = 0;
    for (final entry in result) {
      try {
        if (entry is! Map) {
          throw FormatException(
            'expected an app object, got ${entry.runtimeType}',
          );
        }
        apps.add(parse(Map<String, dynamic>.from(entry)));
      } catch (e, stackTrace) {
        skipped++;
        if (firstFailure == null) {
          firstFailure = e;
          firstStackTrace = stackTrace;
          firstFailedName = entry is Map ? entry['name']?.toString() : null;
        }
      }
    }

    // One record per response, not per entry: a field that changed shape in
    // a newer TrueNAS fails every entry the same way, and the catalog is
    // re-fetched on every refresh.
    if (skipped > 0) {
      _log.warn(
        'Skipped unparsable app entries',
        attributes: {
          'method': method,
          'skipped': skipped,
          'total': result.length,
          'first_failed_name': firstFailedName,
          'first_failure': '$firstFailure',
        },
      );
      _telemetry?.getLogger().error(
        'TrueNAS API: $method returned app entries that could not be '
        'parsed; skipped them',
        error: firstFailure,
        stackTrace: firstStackTrace,
        attributes: {
          'server.id': _server.id,
          'truenas.method': method,
          'truenas.apps.skipped': skipped,
          'truenas.apps.total': result.length,
          'truenas.app.name': firstFailedName ?? '',
        },
      );
    }

    if (apps.isEmpty && skipped > 0) {
      throw FormatException(
        '$method: none of the $skipped app entries could be parsed: '
        '$firstFailure',
      );
    }
    return apps;
  }

  /// Convert TrueNAS app query response to our App model
  App _convertTrueNasAppToApp(Map<String, dynamic> trueNasApp) {
    // Extract upgrade info from the response
    final upgradeInfo = AppUpgradeInfo(
      upgradeAvailable: trueNasApp['upgrade_available'] as bool? ?? false,
      availableVersion: trueNasApp['latest_version'] as String?,
      currentVersion: trueNasApp['version'] as String?,
      upgradeNotes: null, // Not available in TrueNAS response
      canUpgrade:
          (trueNasApp['upgrade_available'] as bool? ?? false) &&
          (trueNasApp['state'] as String?) == 'RUNNING',
    );

    // Extract resource usage from limits (not real-time usage)
    AppResourceUsage? resourceUsage;
    final resources = trueNasApp['resources'] as Map<String, dynamic>?;
    if (resources != null) {
      final limits = resources['limits'] as Map<String, dynamic>?;
      if (limits != null) {
        resourceUsage = AppResourceUsage(
          cpuUsage: 0.0, // Not available in real-time
          memoryUsage: 0, // Not available in real-time
          memoryLimit: (limits['memory'] as num?)?.toInt() ?? 0,
          networkRxBytes: 0.0, // Not available
          networkTxBytes: 0.0, // Not available
          lastUpdated: DateTime.now(),
        );
      }
    }

    // Extract port information from active_workloads
    final activeWorkloads =
        trueNasApp['active_workloads'] as Map<String, dynamic>?;
    final usedPorts = <AppPortInfo>[];
    if (activeWorkloads != null) {
      final usedPortsData =
          activeWorkloads['used_ports'] as List<dynamic>? ?? [];
      for (final portData in usedPortsData) {
        usedPorts.add(AppPortInfo.fromJson(portData as Map<String, dynamic>));
      }
    }

    // Extract portal information
    final portals =
        (trueNasApp['portals'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, value.toString()),
        ) ??
        <String, String>{};

    // Extract metadata for app information
    final metadata = trueNasApp['metadata'] as Map<String, dynamic>?;

    // Extract commonly used values
    final appName = trueNasApp['name'] as String? ?? '';
    final appState = trueNasApp['state'] as String?;
    final isHealthy = appState == 'RUNNING';
    final healthError = !isHealthy
        ? 'App is ${appState?.toLowerCase() ?? 'stopped'}'
        : null;

    return App(
      name: appName,
      title: metadata?['title'] as String? ?? appName,
      description: metadata?['description'] as String? ?? '',
      installed: true, // These are installed apps
      healthy: isHealthy,
      healthyError: healthError,
      latestVersion: trueNasApp['latest_version'] as String? ?? '',
      latestAppVersion: metadata?['app_version'] as String? ?? '',
      latestHumanVersion: trueNasApp['human_version'] as String? ?? '',
      iconUrl: metadata?['icon'] as String?,
      categories:
          (metadata?['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      home: metadata?['home'] as String?,
      tags:
          (metadata?['keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      screenshots:
          (metadata?['screenshots'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      sources:
          (metadata?['sources'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      appReadme: null, // Not available in this response
      maintainers:
          (metadata?['maintainers'] as List<dynamic>?)
              ?.map((e) => AppMaintainer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdate: null, // Not available in this response format
      recommended: false, // Not available in this response
      catalog: 'community', // Default, not available in this response
      train: metadata?['train'] as String? ?? 'community',
      resourceUsage: resourceUsage,
      upgradeInfo: upgradeInfo,
      usedPorts: usedPorts,
      portals: portals,
    );
  }

  @override
  Future<List<String>> getAppCategories() async {
    try {
      return await _traced('truenas.apps.categories', () async {
        final result = await _sendRequest('app.categories');
        return (result as List<dynamic>).cast<String>();
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<bool> upgradeApp(String appName, {String? version}) async {
    try {
      await _ensureAuthenticated();
      // The TrueNAS API takes just the app name as a string parameter
      final result = await _request('app.upgrade', [appName]);
      // The upgrade method returns the app object on success, so we check if it's not null
      return result != null;
    } catch (e) {
      _log.error(
        'Failed to upgrade app',
        error: e,
        attributes: {'app.name': appName},
      );
      return false;
    }
  }

  @override
  Future<bool> startApp(String appName) async {
    try {
      await _ensureAuthenticated();
      final result = await _request('app.start', [appName]);
      return result != null;
    } catch (e) {
      _log.error(
        'Failed to start app',
        error: e,
        attributes: {'app.name': appName},
      );
      return false;
    }
  }

  @override
  Future<bool> stopApp(String appName) async {
    try {
      await _ensureAuthenticated();
      final result = await _request('app.stop', [appName]);
      return result != null;
    } catch (e) {
      _log.error(
        'Failed to stop app',
        error: e,
        attributes: {'app.name': appName},
      );
      return false;
    }
  }

  @override
  Future<bool> restartApp(String appName) async {
    try {
      await _ensureAuthenticated();
      final result = await _request('app.restart', [appName]);
      return result != null;
    } catch (e) {
      _log.error(
        'Failed to restart app',
        error: e,
        attributes: {'app.name': appName},
      );
      return false;
    }
  }
}
