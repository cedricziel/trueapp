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
    final (label, color, icon) = _describe(context);
    return StatusPill(label: label, color: color, icon: icon);
  }

  (String, Color, IconData?) _describe(BuildContext context) {
    final grey = CupertinoColors.systemGrey.resolveFrom(context);
    if (!app.installed) return ('Available', CupertinoColors.systemBlue, null);
    return switch (app.state) {
      AppState.running => (
        'Running',
        CupertinoColors.systemGreen,
        CupertinoIcons.checkmark_circle_fill,
      ),
      AppState.deploying => (
        'Deploying',
        CupertinoColors.systemOrange,
        CupertinoIcons.arrow_2_circlepath,
      ),
      AppState.stopping => (
        'Stopping',
        CupertinoColors.systemOrange,
        CupertinoIcons.arrow_2_circlepath,
      ),
      AppState.stopped => ('Stopped', grey, CupertinoIcons.stop_circle),
      AppState.crashed => (
        'Crashed',
        CupertinoColors.systemRed,
        CupertinoIcons.exclamationmark_triangle_fill,
      ),
      AppState.unknown => ('Installed', grey, null),
    };
  }
}
