import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/system_stats.dart';
import 'package:truehub/providers/system_stats_provider.dart';
import 'package:truehub/widgets/responsive_row.dart';
import 'package:truehub/widgets/usage_bar.dart';

class SystemStatsWidget extends StatelessWidget {
  const SystemStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SystemStatsProvider>(
      builder: (context, statsProvider, child) {
        if (statsProvider.isLoading && !statsProvider.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CupertinoActivityIndicator(),
            ),
          );
        }

        if (statsProvider.error != null && !statsProvider.hasData) {
          return _buildErrorView(statsProvider.error!);
        }

        if (!statsProvider.hasData) {
          return _buildEmptyView();
        }

        return _buildStatsContent(statsProvider);
      },
    );
  }

  Widget _buildErrorView(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemRed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: CupertinoColors.systemRed,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Failed to load system stats: $error',
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

  Widget _buildEmptyView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(
              CupertinoIcons.chart_bar,
              size: 32,
              color: CupertinoColors.systemGrey,
            ),
            SizedBox(height: 8),
            Text(
              'No system stats available',
              style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsContent(SystemStatsProvider statsProvider) {
    return Column(
      children: [
        // CPU and Memory - responsive layout
        ResponsiveRow(
          children: [
            _CpuStatsCard(
              cpuUsage: statsProvider.cpuUsage,
              cores: statsProvider.cpuCores,
            ),
            _MemoryStatsCard(
              memoryUsage: statsProvider.memoryUsage,
              arcUsage: statsProvider.arcUsage,
              totalMemory: statsProvider.physicalMemoryTotal,
              availableMemory: statsProvider.physicalMemoryAvailable,
              arcSize: statsProvider.arcSize,
              formatBytes: statsProvider.formatBytes,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Disk I/O row
        _DiskStatsCard(
          diskStats: statsProvider.currentStats!.disks,
          formatRate: statsProvider.formatRate,
        ),
        const SizedBox(height: 12),
        // Network interfaces
        if (statsProvider.networkInterfaces.isNotEmpty)
          _NetworkStatsCard(
            interfaces: statsProvider.networkInterfaces,
            formatRate: statsProvider.formatRate,
          ),
      ],
    );
  }
}

class _CpuStatsCard extends StatelessWidget {
  final double cpuUsage;
  final List<MapEntry<String, CpuCore>> cores;

  const _CpuStatsCard({required this.cpuUsage, required this.cores});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.separator, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.speedometer,
                color: CupertinoColors.systemBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'CPU',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${cpuUsage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _getCpuUsageColor(cpuUsage),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          UsageBar(usage: cpuUsage, color: _getCpuUsageColor(cpuUsage)),
          if (cores.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildCoresList(),
          ],
        ],
      ),
    );
  }

  Widget _buildCoresList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cores',
          style: TextStyle(
            fontSize: 14,
            color: CupertinoColors.systemGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: cores.take(8).map((core) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getCpuUsageColor(
                  core.value.usage,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${core.key.replaceAll('cpu', '')}: ${core.value.usage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: _getCpuUsageColor(core.value.usage),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getCpuUsageColor(double usage) {
    if (usage > 80) return CupertinoColors.systemRed;
    if (usage > 60) return CupertinoColors.systemOrange;
    return CupertinoColors.systemGreen;
  }
}

class _MemoryStatsCard extends StatelessWidget {
  final double memoryUsage;
  final double arcUsage;
  final int totalMemory;
  final int availableMemory;
  final int arcSize;
  final String Function(int) formatBytes;

  const _MemoryStatsCard({
    required this.memoryUsage,
    required this.arcUsage,
    required this.totalMemory,
    required this.availableMemory,
    required this.arcSize,
    required this.formatBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.separator, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.memories,
                color: CupertinoColors.systemPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Memory',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${memoryUsage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _getMemoryUsageColor(memoryUsage),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          UsageBar(
            usage: memoryUsage,
            color: _getMemoryUsageColor(memoryUsage),
          ),
          const SizedBox(height: 12),
          _buildMemoryDetails(),
        ],
      ),
    );
  }

  Widget _buildMemoryDetails() {
    return Column(
      children: [
        _buildMemoryRow(
          'Physical',
          formatBytes(totalMemory - availableMemory),
          formatBytes(totalMemory),
          CupertinoColors.systemPurple,
        ),
        const SizedBox(height: 6),
        _buildMemoryRow(
          'ARC Cache',
          formatBytes(arcSize),
          formatBytes(totalMemory),
          CupertinoColors.systemBlue,
        ),
      ],
    );
  }

  Widget _buildMemoryRow(String label, String used, String total, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const Spacer(),
        Text(
          '$used / $total',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Color _getMemoryUsageColor(double usage) {
    if (usage > 90) return CupertinoColors.systemRed;
    if (usage > 75) return CupertinoColors.systemOrange;
    return CupertinoColors.systemPurple;
  }
}

class _DiskStatsCard extends StatelessWidget {
  final DiskStats diskStats;
  final String Function(double) formatRate;

  const _DiskStatsCard({required this.diskStats, required this.formatRate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.separator, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.device_desktop,
                color: CupertinoColors.systemGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Disk I/O',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${diskStats.busy.toStringAsFixed(1)}% busy',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _getDiskBusyColor(diskStats.busy),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildIOMetric(
                  'Read',
                  formatRate(diskStats.readBytes),
                  '${diskStats.readOps.toStringAsFixed(1)} ops/s',
                  CupertinoColors.systemBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildIOMetric(
                  'Write',
                  formatRate(diskStats.writeBytes),
                  '${diskStats.writeOps.toStringAsFixed(1)} ops/s',
                  CupertinoColors.systemOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIOMetric(String label, String rate, String ops, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          rate,
          style: const TextStyle(
            fontSize: 13,
            color: CupertinoColors.systemGrey,
          ),
        ),
        Text(
          ops,
          style: const TextStyle(
            fontSize: 11,
            color: CupertinoColors.systemGrey2,
          ),
        ),
      ],
    );
  }

  Color _getDiskBusyColor(double busy) {
    if (busy > 80) return CupertinoColors.systemRed;
    if (busy > 60) return CupertinoColors.systemOrange;
    return CupertinoColors.systemGreen;
  }
}

class _NetworkStatsCard extends StatelessWidget {
  final Map<String, NetworkInterfaceStats> interfaces;
  final String Function(double) formatRate;

  const _NetworkStatsCard({required this.interfaces, required this.formatRate});

  @override
  Widget build(BuildContext context) {
    final activeInterfaces = interfaces.entries
        .where((entry) => entry.value.isUp)
        .toList();

    if (activeInterfaces.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.separator, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.wifi,
                color: CupertinoColors.systemTeal,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Network',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...activeInterfaces.map((interface) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildNetworkInterface(interface.key, interface.value),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNetworkInterface(String name, NetworkInterfaceStats stats) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.arrow_down,
                    size: 12,
                    color: CupertinoColors.systemBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formatRate(stats.receivedBytesRate),
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    CupertinoIcons.arrow_up,
                    size: 12,
                    color: CupertinoColors.systemOrange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formatRate(stats.sentBytesRate),
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'UP',
            style: TextStyle(
              fontSize: 10,
              color: CupertinoColors.systemGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
