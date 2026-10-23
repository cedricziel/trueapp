import 'package:flutter/cupertino.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/widgets/section_card.dart';

/// Shows an app's running state, or "Available" for apps that are only in the
/// catalog.
class AppStateBadge extends StatelessWidget {
  final App app;

  const AppStateBadge({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    if (!app.installed) {
      return const StatusPill(
        label: 'Available',
        color: CupertinoColors.systemBlue,
      );
    }
    return switch (app.state) {
      AppState.running => const StatusPill(
        label: 'Running',
        color: CupertinoColors.systemGreen,
        icon: CupertinoIcons.checkmark_circle_fill,
      ),
      AppState.deploying => const StatusPill(
        label: 'Deploying',
        color: CupertinoColors.systemOrange,
        icon: CupertinoIcons.arrow_2_circlepath,
      ),
      AppState.stopping => const StatusPill(
        label: 'Stopping',
        color: CupertinoColors.systemOrange,
        icon: CupertinoIcons.arrow_2_circlepath,
      ),
      AppState.stopped => const StatusPill(
        label: 'Stopped',
        color: CupertinoColors.systemGrey,
        icon: CupertinoIcons.stop_circle,
      ),
      AppState.crashed => const StatusPill(
        label: 'Crashed',
        color: CupertinoColors.systemRed,
        icon: CupertinoIcons.exclamationmark_triangle_fill,
      ),
      AppState.unknown => const StatusPill(
        label: 'Installed',
        color: CupertinoColors.systemGrey,
      ),
    };
  }
}
