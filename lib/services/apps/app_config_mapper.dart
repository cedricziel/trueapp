import 'package:truehub/models/app.dart';
import 'package:truehub/models/app_config.dart';
import 'package:truehub/models/nas_server.dart';

/// Turns persisted [AppConfig]s into display-ready [App]s and URLs, pointing
/// `localhost`/`tcp` portal URLs at the active [server].
class AppConfigMapper {
  final NasServer? server;

  const AppConfigMapper(this.server);

  App toApp(AppConfig config, {AppResourceUsage? resourceUsage}) {
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
      resourceUsage: resourceUsage,
      upgradeInfo: config.upgradeInfo,
      usedPorts: config.usedPorts,
      portals: portalsFor(config),
      customDisplayName: config.displayName,
      customIconUrl: config.iconUrl,
      primaryCustomUrl: config.primaryPort?.customUrl != null
          ? interpolateUrl(config.primaryPort!.customUrl!)
          : null,
    );
  }

  Map<String, String> portalsFor(AppConfig config) {
    final portals = <String, String>{};
    for (final port in config.enabledPorts) {
      portals[port.serviceName ?? 'Port ${port.portNumber}'] = interpolateUrl(
        port.effectiveUrl,
      );
    }
    return portals;
  }

  String interpolateUrl(String url) {
    final server = this.server;
    if (server == null) return url;

    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    var host = uri.host;
    if (host == 'localhost' || host == '127.0.0.1') {
      host = server.host;
    }

    var scheme = uri.scheme;
    if (scheme == 'tcp') {
      scheme = server.useHttps ? 'https' : 'http';
    }

    return Uri(
      scheme: scheme,
      host: host,
      port: uri.port,
      path: uri.path,
      query: uri.query.isEmpty ? null : uri.query,
      fragment: uri.fragment.isEmpty ? null : uri.fragment,
    ).toString();
  }
}
