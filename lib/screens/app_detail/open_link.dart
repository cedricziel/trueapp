import 'package:flutter/cupertino.dart';
import 'package:truehub/services/url_opener.dart';

Future<void> openLinkOrAlert(
  BuildContext context,
  UrlOpener urlOpener,
  String url,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  if (await urlOpener.open(url) || !navigator.mounted) return;

  showCupertinoDialog<void>(
    context: navigator.context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: const Text("Couldn't Open Link"),
      content: Text(url),
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
