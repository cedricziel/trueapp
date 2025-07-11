import 'package:flutter/cupertino.dart';

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final IconData? icon;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.icon = CupertinoIcons.exclamationmark_triangle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon!, color: CupertinoColors.systemRed, size: 20),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: CupertinoColors.systemRed,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
