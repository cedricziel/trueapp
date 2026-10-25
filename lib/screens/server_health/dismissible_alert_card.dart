import 'package:flutter/cupertino.dart';
import 'package:truehub/models/alert.dart';

/// An alert in the health list. Swiping it left dismisses it, or restores it
/// when it is already dismissed.
class DismissibleAlertCard extends StatelessWidget {
  final Alert alert;

  /// Called after a swipe; the card stays in place until the list rebuilds
  /// without it, so the parent's state is the single source of truth.
  final VoidCallback onToggleDismissed;

  const DismissibleAlertCard({
    super.key,
    required this.alert,
    required this.onToggleDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final restoring = alert.dismissed;
    return Dismissible(
      key: ValueKey(alert.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onToggleDismissed();
        return false;
      },
      background: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: restoring
              ? CupertinoColors.systemBlue
              : CupertinoColors.systemRed,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            restoring ? 'Restore' : 'Dismiss',
            style: const TextStyle(
              color: CupertinoColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      child: Opacity(opacity: restoring ? 0.55 : 1, child: _card(context)),
    );
  }

  Widget _card(BuildContext context) {
    final color = switch (alert.level) {
      AlertLevel.critical => CupertinoColors.systemRed,
      AlertLevel.error => CupertinoColors.systemOrange,
      AlertLevel.warning => CupertinoColors.systemYellow,
      AlertLevel.info || AlertLevel.unknown => CupertinoColors.systemBlue,
    };

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.message,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (alert.occurredAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _formatRelativeTime(alert.occurredAt!),
                        style: TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.tertiaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
