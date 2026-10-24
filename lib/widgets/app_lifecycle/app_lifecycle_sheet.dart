import 'package:flutter/cupertino.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/widgets/app_lifecycle/app_lifecycle_action.dart';
import 'package:truehub/widgets/app_lifecycle/app_lifecycle_runner.dart';

/// Action-sheet entries for the lifecycle actions available to [app].
///
/// [sheetContext] closes the sheet; [hostContext] outlives it and owns the
/// dialogs the action shows afterwards.
List<Widget> appLifecycleSheetActions({
  required BuildContext sheetContext,
  required BuildContext hostContext,
  required App app,
}) {
  return [
    for (final action in AppLifecycleAction.availableFor(app))
      CupertinoActionSheetAction(
        isDestructiveAction: action.isDestructive,
        onPressed: () {
          Navigator.pop(sheetContext);
          runAppLifecycleAction(hostContext, app, action);
        },
        child: Text(action.label),
      ),
  ];
}

/// Opens an action sheet with just the lifecycle actions for [app]; does
/// nothing when none apply.
void showAppLifecycleSheet(BuildContext context, App app) {
  if (AppLifecycleAction.availableFor(app).isEmpty) return;
  showCupertinoModalPopup<void>(
    context: context,
    builder: (sheetContext) => CupertinoActionSheet(
      title: Text(app.effectiveDisplayName),
      actions: appLifecycleSheetActions(
        sheetContext: sheetContext,
        hostContext: context,
        app: app,
      ),
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.pop(sheetContext),
        child: const Text('Cancel'),
      ),
    ),
  );
}
