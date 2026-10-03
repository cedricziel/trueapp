import 'package:flutter/cupertino.dart';

class ServiceActionErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const ServiceActionErrorBanner({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemRed,
              ),
            ),
          ),
          CupertinoButton(
            key: const Key('services-action-error-dismiss'),
            padding: const EdgeInsets.all(8),
            minimumSize: Size.zero,
            onPressed: onDismiss,
            child: const Icon(
              CupertinoIcons.xmark,
              size: 16,
              color: CupertinoColors.systemRed,
            ),
          ),
        ],
      ),
    );
  }
}
