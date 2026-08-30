import 'package:flutter/cupertino.dart';
import 'package:truehub/models/system_stats.dart';

/// Maps 100% of physical memory into a single horizontal bar split into
/// Free / ZFS ARC / Apps & Services segments, with a legend of exact values
/// underneath. Free deliberately excludes the reclaimable ZFS ARC cache, so
/// the three segments always sum to 100% of [MemoryStats.physicalMemoryTotal].
class MemorySegmentedBar extends StatelessWidget {
  final MemoryStats stats;
  final String Function(int bytes) formatBytes;

  const MemorySegmentedBar({
    super.key,
    required this.stats,
    required this.formatBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 26,
            child: Row(
              children: [
                _Segment(
                  flex: stats.freeMemoryPercent,
                  color: CupertinoColors.systemGrey3,
                  label: '${stats.freeMemoryPercent.round()}%',
                  labelColor: CupertinoColors.label,
                ),
                const SizedBox(width: 1.5),
                _Segment(
                  flex: stats.arcUsagePercent,
                  color: CupertinoColors.systemBlue,
                  label: '${stats.arcUsagePercent.round()}%',
                  labelColor: CupertinoColors.white,
                ),
                const SizedBox(width: 1.5),
                _Segment(
                  flex: stats.appsMemoryPercent,
                  color: CupertinoColors.systemPurple,
                  label: '${stats.appsMemoryPercent.round()}%',
                  labelColor: CupertinoColors.white,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.only(top: 2),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: CupertinoColors.separator, width: 0.5),
            ),
          ),
          child: Column(
            children: [
              _LegendRow(
                color: CupertinoColors.systemGrey3,
                label: 'Free',
                value: formatBytes(stats.freeMemory),
                percent: stats.freeMemoryPercent,
              ),
              const SizedBox(height: 10),
              _LegendRow(
                color: CupertinoColors.systemBlue,
                label: 'ZFS ARC',
                value: formatBytes(stats.arcSize),
                percent: stats.arcUsagePercent,
              ),
              const SizedBox(height: 10),
              _LegendRow(
                color: CupertinoColors.systemPurple,
                label: 'Apps & Services',
                value: formatBytes(stats.appsMemory),
                percent: stats.appsMemoryPercent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Free excludes reclaimable ZFS ARC cache, so Free + ZFS ARC + '
          'Apps always adds up to 100% of physical memory.',
          style: TextStyle(fontSize: 11, color: CupertinoColors.tertiaryLabel),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  final double flex;
  final Color color;
  final String label;
  final Color labelColor;

  const _Segment({
    required this.flex,
    required this.color,
    required this.label,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      // Expanded/Flexible require a strictly positive flex; a genuinely
      // empty segment (e.g. no ARC cache yet) still renders as a sliver
      // rather than crashing.
      flex: flex.round().clamp(1, 100),
      child: Container(
        color: color,
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: labelColor,
          ),
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final double percent;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '${percent.round()}%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ),
      ],
    );
  }
}
