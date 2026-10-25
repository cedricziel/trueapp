import 'package:flutter/cupertino.dart';
import 'package:truehub/models/pool_scan.dart';
import 'package:truehub/widgets/pool_scan/pool_scan_formatters.dart';
import 'package:truehub/widgets/section_card.dart';
import 'package:truehub/widgets/usage_bar.dart';

/// The pool detail card for a pool's scrub or resilver: live progress while
/// it runs, and a summary of the last run once idle.
class PoolScanSection extends StatelessWidget {
  final PoolScan scan;

  /// The reference time for speed and ETA; defaults to the current time.
  final DateTime? now;

  const PoolScanSection({super.key, required this.scan, this.now});

  @override
  Widget build(BuildContext context) {
    final scan = this.scan;
    return SectionCard(
      title: scan.isRunning
          ? scan.function.label
          : 'Last ${scan.function.label.toLowerCase()}',
      icon: CupertinoIcons.shield_lefthalf_fill,
      iconColor: scan.isRunning
          ? CupertinoColors.systemBlue
          : CupertinoColors.systemGrey,
      children: scan.isRunning
          ? _runningRows(scan, now ?? DateTime.now())
          : _idleRows(scan),
    );
  }

  List<Widget> _runningRows(PoolScan scan, DateTime now) {
    final fraction = scan.fraction;
    final speed = scan.bytesPerSecond(now);
    final timeLeft = scan.timeLeft(now);
    final startTime = scan.startTime;

    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: StatusPill(
            label: scan.isPaused ? 'Paused' : 'Scanning',
            color: scan.isPaused
                ? CupertinoColors.systemOrange
                : CupertinoColors.systemBlue,
          ),
        ),
      ),
      if (fraction != null) ...[
        UsageBar(
          usage: fraction * 100,
          color: scan.isPaused
              ? CupertinoColors.systemOrange
              : CupertinoColors.systemBlue,
        ),
        const SizedBox(height: 12),
        InfoRow('Progress', '${(fraction * 100).toStringAsFixed(1)}%'),
      ],
      if (speed != null) InfoRow('Speed', formatScanSpeed(speed)),
      if (timeLeft != null) InfoRow('Time left', formatScanDuration(timeLeft)),
      _errorsRow(scan),
      if (startTime != null) InfoRow('Started', formatScanTimestamp(startTime)),
    ];
  }

  List<Widget> _idleRows(PoolScan scan) {
    final endTime = scan.endTime;
    final duration = scan.duration;
    final (statusLabel, statusColor) = switch (scan.state) {
      PoolScanState.finished => ('Completed', CupertinoColors.systemGreen),
      PoolScanState.canceled => ('Canceled', CupertinoColors.systemOrange),
      _ => ('Unknown', CupertinoColors.systemGrey),
    };

    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: StatusPill(label: statusLabel, color: statusColor),
        ),
      ),
      if (endTime != null)
        InfoRow(
          scan.state == PoolScanState.canceled ? 'Stopped' : 'Completed',
          formatScanTimestamp(endTime),
        ),
      if (duration != null) InfoRow('Duration', formatScanDuration(duration)),
      _errorsRow(scan),
    ];
  }

  Widget _errorsRow(PoolScan scan) => InfoRow(
    'Errors',
    '${scan.errors}',
    valueColor: scan.errors > 0 ? CupertinoColors.systemRed : null,
  );
}
