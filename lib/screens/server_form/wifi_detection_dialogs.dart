import 'package:flutter/cupertino.dart';

void showNoWifiDetectedDialog(BuildContext context) {
  _showOkDialog(
    context,
    title: 'No Wi-Fi Detected',
    content:
        'Unable to detect current Wi-Fi network. This could be due to:\n\n'
        '• Not connected to Wi-Fi\n'
        '• Location permission not granted\n'
        '• Platform restrictions (macOS/iOS)\n\n'
        'You can still manually enter network names.',
  );
}

void showWifiDetectionErrorDialog(BuildContext context, Object error) {
  _showOkDialog(
    context,
    title: 'Wi-Fi Detection Error',
    content:
        'Failed to detect Wi-Fi network: ${error.toString()}\n\n'
        'You can still manually enter network names.',
  );
}

void _showOkDialog(
  BuildContext context, {
  required String title,
  required String content,
}) {
  showCupertinoDialog<void>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        CupertinoDialogAction(
          child: const Text('OK'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}
