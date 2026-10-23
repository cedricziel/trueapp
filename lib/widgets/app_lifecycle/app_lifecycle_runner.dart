import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/providers/app_provider.dart';
import 'package:truehub/widgets/app_lifecycle/app_lifecycle_action.dart';
import 'package:truehub/widgets/app_lifecycle/app_upgrade_flow.dart';

/// Runs [action] against [app]: confirms first where the action is
/// disruptive, shows progress while the request runs, and reports a failure.
/// On success the provider reloads the apps, which updates the UI.
Future<void> runAppLifecycleAction(
  BuildContext context,
  App app,
  AppLifecycleAction action,
) async {
  if (action == AppLifecycleAction.upgrade) {
    showAppUpgradeFlow(context, app);
    return;
  }

  final navigator = Navigator.of(context, rootNavigator: true);
  final provider = context.read<AppProvider>();
  final name = app.effectiveDisplayName;

  if (action.needsConfirmation &&
      !await _confirm(navigator.context, action, name)) {
    return;
  }
  if (!navigator.mounted) return;

  showCupertinoDialog<void>(
    context: navigator.context,
    barrierDismissible: false,
    builder: (_) => CupertinoAlertDialog(
      title: Text('${action.progressLabel} $name...'),
      content: const Padding(
        padding: EdgeInsets.all(16),
        child: CupertinoActivityIndicator(),
      ),
    ),
  );

  final success = await action.run(provider, app.name);

  if (!navigator.mounted) return;
  navigator.pop();
  if (!success) {
    await showCupertinoDialog<void>(
      context: navigator.context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text("Couldn't ${action.verb} $name"),
        content: const Text('Something went wrong. Please try again.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

Future<bool> _confirm(
  BuildContext context,
  AppLifecycleAction action,
  String name,
) async {
  final confirmed = await showCupertinoDialog<bool>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text('${action.label} $name?'),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: action.isDestructive,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(action.label),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
