import 'package:flutter/cupertino.dart';
import 'package:truehub/models/service_status.dart';
import 'package:truehub/widgets/section_card.dart';

enum ServiceAction { start, stop, restart }

/// One service row: its name, running state and, while an action is in
/// flight, a spinner in place of the state pill.
class ServiceTile extends StatelessWidget {
  final ServiceStatus service;
  final bool isBusy;
  final ValueChanged<ServiceAction> onAction;

  const ServiceTile({
    super.key,
    required this.service,
    required this.isBusy,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final color = service.isRunning
        ? CupertinoColors.systemGreen
        : CupertinoColors.systemGrey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: isBusy ? null : () => _showActions(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  service.displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
              if (isBusy)
                const CupertinoActivityIndicator()
              else
                StatusPill(
                  label: service.isRunning ? 'Running' : 'Stopped',
                  color: color,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showActions(BuildContext context) async {
    final action = await showCupertinoModalPopup<ServiceAction>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(service.displayName),
        message: Text(service.isRunning ? 'Running' : 'Stopped'),
        actions: [
          if (!service.isRunning)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, ServiceAction.start),
              child: const Text('Start'),
            ),
          if (service.isRunning) ...[
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, ServiceAction.stop),
              child: const Text('Stop'),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, ServiceAction.restart),
              child: const Text('Restart'),
            ),
          ],
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
    if (action != null) onAction(action);
  }
}
