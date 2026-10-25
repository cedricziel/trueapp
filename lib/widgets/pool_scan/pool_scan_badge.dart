import 'package:flutter/cupertino.dart';
import 'package:truehub/models/pool_scan.dart';
import 'package:truehub/widgets/pool_scan/pool_scan_formatters.dart';
import 'package:truehub/widgets/usage_bar.dart';

/// A compact "Scrubbing 42%" line with a thin progress bar, for list cards.
/// Renders nothing unless [scan] is still running.
class PoolScanBadge extends StatelessWidget {
  final PoolScan scan;

  const PoolScanBadge({super.key, required this.scan});

  @override
  Widget build(BuildContext context) {
    if (!scan.isRunning) return const SizedBox.shrink();

    final fraction = scan.fraction;
    final percent = fraction == null ? '' : ' ${(fraction * 100).round()}%';
    final label = scan.isPaused
        ? '${scan.function.label} paused$percent'
        : '${scan.function.progressiveLabel}$percent';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.systemBlue,
          ),
        ),
        if (fraction != null) ...[
          const SizedBox(height: 4),
          UsageBar(
            usage: fraction * 100,
            color: scan.isPaused
                ? CupertinoColors.systemOrange
                : CupertinoColors.systemBlue,
            height: 4,
            borderRadius: 2,
          ),
        ],
      ],
    );
  }
}
