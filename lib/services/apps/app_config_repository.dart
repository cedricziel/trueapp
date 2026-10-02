import 'package:drift/drift.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/models/app_config.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/app_logger.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';

final _log = appLogger('services.app_config_repository');

/// Persists per-server [AppConfig]s: syncing fresh API data in while keeping
/// the user's customisations, and reading/updating them back.
///
/// [daoSource] is resolved on every access rather than captured, so a source
/// backed by an [AppDatabaseHolder] follows a recreated database (e.g. after
/// "clear database") instead of pinning a closed one.
class AppConfigRepository {
  final DaoSource _daoSource;
  final UnifiedServerService _serverService;

  AppConfigRepository({
    required DaoSource daoSource,
    required UnifiedServerService serverService,
  }) : _daoSource = daoSource,
       _serverService = serverService;

  Future<List<AppConfig>> load(String serverId) async {
    final configs = await _daoSource.appConfigsDao.getFullAppConfigs(serverId);
    _log.info('Loaded ${configs.length} persisted app configs');
    return configs;
  }

  Future<void> update(AppConfig config) =>
      _daoSource.appConfigsDao.updateFullAppConfig(config);

  Future<void> setFavorite(String serverId, String appName, bool isFavorite) =>
      _daoSource.appConfigsDao.setAppFavorite(serverId, appName, isFavorite);

  Future<void> syncApps({
    required String serverId,
    required NasServer? server,
    required List<App> apps,
  }) async {
    // app_configs.server_id has an enforced foreign key to nas_servers, but
    // on Apple platforms the current server may only exist in CloudKit (see
    // ServersDao.upsertServerAnchor) - mirror it in first so these inserts
    // don't fail with a foreign key violation. Re-check the server still
    // exists right before writing the anchor: if ServerProvider.deleteServer
    // already ran concurrently (it cleans up this same anchor row), writing
    // here would resurrect it - and the app_configs rows below - for a
    // server the user just deleted, with nothing left to clean them up
    // afterward.
    if (server != null) {
      final stillExists = await _serverService.getServer(server.id);
      if (stillExists == null) return;
      await _daoSource.serversDao.upsertServerAnchor(server);
    }

    final dao = _daoSource.appConfigsDao;
    for (final app in apps) {
      final existingConfig = await dao.getFullAppConfig(serverId, app.name);

      if (existingConfig != null) {
        final updatedConfig = existingConfig
            .updateFromApp(app)
            .copyWith(
              displayName: existingConfig.displayName,
              iconUrl: existingConfig.iconUrl ?? app.iconUrl,
              isEnabled: existingConfig.isEnabled,
              isFavorite: existingConfig.isFavorite,
              ports: existingConfig.ports,
            );
        await dao.updateFullAppConfig(updatedConfig);
      } else {
        await dao.insertFullAppConfig(
          AppConfig.fromApp(serverId: serverId, app: app),
        );
      }

      if (app.installed) {
        await _syncPortalUrls(serverId, app);
      }
    }
  }

  Future<void> _syncPortalUrls(String serverId, App app) async {
    final dao = _daoSource.appConfigsDao;
    final existingConfig = await dao.getFullAppConfig(serverId, app.name);
    if (existingConfig?.id == null) return;

    final existingPorts = await dao.getAppPortConfigs(existingConfig!.id!);
    final existingPortNumbers = {
      for (final port in existingPorts) port.portNumber,
    };
    var hasPrimary = existingPorts.any((port) => port.isPrimary);

    for (final portal in app.portals.entries) {
      final uri = Uri.tryParse(portal.value);
      if (uri == null || !uri.hasPort) continue;
      if (existingPortNumbers.contains(uri.port)) continue;

      await dao.insertAppPortConfig(
        AppPortConfigsCompanion(
          appConfigId: Value(existingConfig.id!),
          portNumber: Value(uri.port),
          protocol: Value(uri.scheme),
          serviceName: Value(portal.key),
          apiUrl: Value(portal.value),
          isPrimary: Value(!hasPrimary),
        ),
      );
      hasPrimary = true;
    }
  }
}
