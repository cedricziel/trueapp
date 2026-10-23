import 'package:truehub/models/app.dart';

/// A minimal [App] for tests that only care about identity and lifecycle
/// state; pass [upgradeInfo] or [healthy] when a test needs them.
App buildTestApp({
  String name = 'plex',
  String title = 'Plex Media Server',
  bool installed = true,
  AppState state = AppState.unknown,
  bool healthy = true,
  AppUpgradeInfo? upgradeInfo,
}) {
  return App(
    name: name,
    title: title,
    description: '',
    installed: installed,
    healthy: healthy,
    state: state,
    latestVersion: '1.0.0',
    latestAppVersion: '1.0.0',
    latestHumanVersion: '1.0.0',
    categories: const [],
    tags: const [],
    screenshots: const [],
    sources: const [],
    maintainers: const [],
    recommended: false,
    catalog: 'community',
    train: 'stable',
    upgradeInfo: upgradeInfo,
    usedPorts: const [],
    portals: const {},
  );
}
