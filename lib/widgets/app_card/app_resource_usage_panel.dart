import 'package:flutter/cupertino.dart';
import 'package:truehub/models/app.dart';

class AppResourceUsagePanel extends StatelessWidget {
  final AppResourceUsage usage;

  const AppResourceUsagePanel({super.key, required this.usage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6
            .resolveFrom(context)
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.speedometer,
                size: 14,
                color: CupertinoColors.systemBlue,
              ),
              const SizedBox(width: 4),
              Text(
                'CPU: ${usage.cpuUsage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                CupertinoIcons.memories,
                size: 14,
                color: CupertinoColors.systemGreen,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Memory: ${_formatBytes(usage.memoryUsage)}${usage.memoryLimit > 0 ? ' / ${_formatBytes(usage.memoryLimit * 1024 * 1024)}' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
            ],
          ),
          if (usage.networkRxBytes > 0 || usage.networkTxBytes > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  CupertinoIcons.arrow_down_circle,
                  size: 14,
                  color: CupertinoColors.systemOrange,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'RX: ${_formatBytes(usage.networkRxBytes.toInt())}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  CupertinoIcons.arrow_up_circle,
                  size: 14,
                  color: CupertinoColors.systemOrange,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'TX: ${_formatBytes(usage.networkTxBytes.toInt())}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                ),
                const Spacer(),
                if (usage.lastUpdated != null)
                  Text(
                    _formatLastUpdated(usage.lastUpdated!),
                    style: TextStyle(
                      fontSize: 10,
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }

  static String _formatLastUpdated(DateTime lastUpdated) {
    final difference = DateTime.now().difference(lastUpdated);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}
