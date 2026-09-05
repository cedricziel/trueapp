import 'package:flutter/cupertino.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/pool.dart';
import 'package:truehub/widgets/storage_metric_widget.dart';
import 'package:truehub/screens/pool_detail_screen.dart';

class PoolCardWidget extends StatelessWidget {
  final Pool pool;
  final NasServer server;

  const PoolCardWidget({super.key, required this.pool, required this.server});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => PoolDetailScreen(server: server, pool: pool),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CupertinoColors.separator, width: 0.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: pool.healthy
                        ? CupertinoColors.systemGreen.withValues(alpha: 0.1)
                        : CupertinoColors.systemRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    CupertinoIcons.square_stack_3d_down_right,
                    color: pool.healthy
                        ? CupertinoColors.systemGreen
                        : CupertinoColors.systemRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pool.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pool.topologyDescription,
                        style: const TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: pool.healthy
                            ? CupertinoColors.systemGreen.withValues(alpha: 0.1)
                            : CupertinoColors.systemRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        pool.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: pool.healthy
                              ? CupertinoColors.systemGreen
                              : CupertinoColors.systemRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StorageMetricWidget(
                    label: 'Used',
                    value: _formatBytes(pool.allocatedBytes),
                    color: CupertinoColors.systemBlue,
                  ),
                ),
                Expanded(
                  child: StorageMetricWidget(
                    label: 'Available',
                    value: _formatBytes(pool.freeBytes),
                    color: CupertinoColors.systemGreen,
                  ),
                ),
                Expanded(
                  child: StorageMetricWidget(
                    label: 'Total',
                    value: _formatBytes(pool.totalBytes),
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    if (bytes < 1024 * 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
    return '${(bytes / (1024 * 1024 * 1024 * 1024)).toStringAsFixed(1)}TB';
  }
}
