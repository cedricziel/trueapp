import 'package:truehub/models/app.dart';
import 'package:truehub/providers/app_provider.dart';

enum AppLifecycleAction {
  start(label: 'Start', progressLabel: 'Starting', verb: 'start'),
  stop(
    label: 'Stop',
    progressLabel: 'Stopping',
    verb: 'stop',
    isDestructive: true,
    needsConfirmation: true,
  ),
  restart(
    label: 'Restart',
    progressLabel: 'Restarting',
    verb: 'restart',
    needsConfirmation: true,
  ),
  upgrade(label: 'Upgrade', progressLabel: 'Upgrading', verb: 'upgrade');

  const AppLifecycleAction({
    required this.label,
    required this.progressLabel,
    required this.verb,
    this.isDestructive = false,
    this.needsConfirmation = false,
  });

  final String label;
  final String progressLabel;
  final String verb;
  final bool isDestructive;

  /// Upgrade has its own confirmation flow, so it leaves this false.
  final bool needsConfirmation;

  /// The actions that make sense for [app] right now, in menu order.
  static List<AppLifecycleAction> availableFor(App app) => [
    for (final action in values)
      if (action.isAvailableFor(app)) action,
  ];

  bool isAvailableFor(App app) => switch (this) {
    start => app.canStart,
    stop => app.canStop,
    restart => app.canRestart,
    upgrade =>
      app.installed &&
          (app.upgradeInfo?.upgradeAvailable ?? false) &&
          app.upgradeInfo!.canUpgrade,
  };

  Future<bool> run(AppProvider provider, String appName) => switch (this) {
    start => provider.startApp(appName),
    stop => provider.stopApp(appName),
    restart => provider.restartApp(appName),
    upgrade => provider.upgradeApp(appName),
  };
}
