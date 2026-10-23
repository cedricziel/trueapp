import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/providers/app_provider.dart';

/// Confirms, runs and reports an upgrade of [app].
void showAppUpgradeFlow(BuildContext context, App app) {
  showCupertinoDialog(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text('Upgrade ${app.title}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Current version: ${app.upgradeInfo?.currentVersion ?? 'Unknown'}',
          ),
          const SizedBox(height: 8),
          Text(
            'Available version: ${app.upgradeInfo?.availableVersion ?? 'Latest'}',
          ),
          if (app.upgradeInfo?.upgradeNotes != null) ...[
            const SizedBox(height: 16),
            Text(
              'Release notes:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              app.upgradeInfo!.upgradeNotes!,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.of(dialogContext).pop();
            _performUpgrade(context, app);
          },
          child: const Text('Upgrade'),
        ),
      ],
    ),
  );
}

void _performUpgrade(BuildContext context, App app) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final appProvider = context.read<AppProvider>();

  showCupertinoDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const CupertinoAlertDialog(
      title: Text('Upgrading...'),
      content: Padding(
        padding: EdgeInsets.all(16.0),
        child: CupertinoActivityIndicator(),
      ),
    ),
  );

  String title;
  String message;
  try {
    final success = await appProvider.upgradeApp(app.name);
    title = success ? 'Success' : 'Error';
    message = success
        ? '${app.title} has been upgraded successfully.'
        : 'Failed to upgrade ${app.title}. Please try again.';
  } catch (e) {
    title = 'Error';
    message = 'An error occurred while upgrading ${app.title}: $e';
  }

  if (!navigator.mounted) return;
  navigator.pop();
  showCupertinoDialog(
    context: navigator.context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
