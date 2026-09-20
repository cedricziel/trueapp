import 'package:flutter/cupertino.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData? icon;

  /// Replaces [icon] when both are given.
  final Widget? leading;
  final String title;
  final String message;

  const EmptyStateWidget({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    required this.message,
  }) : assert(icon != null || leading != null, 'Provide an icon or leading');

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            leading ??
                Icon(
                  icon,
                  size: 48,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey2.resolveFrom(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
