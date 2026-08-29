import 'package:flutter/cupertino.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/widgets/storage_metric_widget.dart';
import 'package:truehub/screens/pool_detail_screen.dart';

class PoolCardWidget extends StatelessWidget {
  final Map<String, dynamic> pool;
  final NasServer server;

  const PoolCardWidget({super.key, required this.pool, required this.server});

  @override
  Widget build(BuildContext context) {
    final name = pool['name'] as String? ?? 'Unknown';
    final status = pool['status'] as String? ?? 'Unknown';
    final healthy = pool['healthy'] as bool? ?? false;

    final topology = pool['topology'] as Map<String, dynamic>?;
    final poolTypeDescription = _getPoolTypeDescription(topology);

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
                    color: healthy
                        ? CupertinoColors.systemGreen.withValues(alpha: 0.1)
                        : CupertinoColors.systemRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    CupertinoIcons.square_stack_3d_down_right,
                    color: healthy
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
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        poolTypeDescription,
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
                        color: healthy
                            ? CupertinoColors.systemGreen.withValues(alpha: 0.1)
                            : CupertinoColors.systemRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: healthy
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
                    value: _getPoolUsedSpace(pool),
                    color: CupertinoColors.systemBlue,
                  ),
                ),
                Expanded(
                  child: StorageMetricWidget(
                    label: 'Available',
                    value: _getPoolAvailableSpace(pool),
                    color: CupertinoColors.systemGreen,
                  ),
                ),
                Expanded(
                  child: StorageMetricWidget(
                    label: 'Total',
                    value: _getPoolTotalSpace(pool),
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

  String _getPoolTypeDescription(Map<String, dynamic>? topology) {
    if (topology == null) return 'Unknown configuration';

    final data = topology['data'] as List<dynamic>?;
    if (data == null || data.isEmpty) return 'Unknown configuration';

    final firstVdev = data.first as Map<String, dynamic>?;
    final type = firstVdev?['type'] as String?;
    final children = firstVdev?['children'] as List<dynamic>?;

    if (type == 'mirror' && children != null) {
      return 'Mirror (${children.length} drives)';
    } else if (type == 'raidz1') {
      return 'RAID-Z1 (${children?.length ?? 0} drives)';
    } else if (type == 'raidz2') {
      return 'RAID-Z2 (${children?.length ?? 0} drives)';
    } else if (type == 'raidz3') {
      return 'RAID-Z3 (${children?.length ?? 0} drives)';
    } else if (children != null && children.length == 1) {
      return 'Single drive';
    }

    return 'Custom configuration';
  }

  String _getPoolUsedSpace(Map<String, dynamic> pool) {
    final allocated = pool['allocated'] as int?;
    if (allocated != null) {
      return _formatBytes(allocated);
    }
    return 'Unknown';
  }

  String _getPoolAvailableSpace(Map<String, dynamic> pool) {
    final free = pool['free'] as int?;
    if (free != null) {
      return _formatBytes(free);
    }
    return 'Unknown';
  }

  String _getPoolTotalSpace(Map<String, dynamic> pool) {
    final allocated = pool['allocated'] as int?;
    final free = pool['free'] as int?;

    if (allocated != null && free != null) {
      return _formatBytes(allocated + free);
    }

    final size = pool['size'] as int?;
    if (size != null) {
      return _formatBytes(size);
    }

    return 'Unknown';
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
