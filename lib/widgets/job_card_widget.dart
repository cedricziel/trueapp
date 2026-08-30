import 'package:flutter/cupertino.dart';
import 'package:truehub/models/job.dart';
import 'package:truehub/widgets/usage_bar.dart';

class _JobVisual {
  final IconData icon;
  final Color color;
  const _JobVisual(this.icon, this.color);
}

_JobVisual _visualFor(Job job) {
  if (job.isFinished) {
    switch (job.state) {
      case JobState.success:
        return const _JobVisual(
          CupertinoIcons.checkmark_circle_fill,
          CupertinoColors.systemGreen,
        );
      case JobState.failed:
        return const _JobVisual(
          CupertinoIcons.xmark_circle_fill,
          CupertinoColors.systemRed,
        );
      default:
        return const _JobVisual(
          CupertinoIcons.minus_circle_fill,
          CupertinoColors.systemGrey,
        );
    }
  }

  final method = job.method;
  if (method.startsWith('zfs.replication')) {
    return const _JobVisual(
      CupertinoIcons.arrow_2_circlepath,
      CupertinoColors.systemTeal,
    );
  }
  if (method.startsWith('pool.scrub')) {
    return const _JobVisual(CupertinoIcons.shield, CupertinoColors.systemGreen);
  }
  if (method.startsWith('cloudsync')) {
    return const _JobVisual(
      CupertinoIcons.cloud_upload,
      CupertinoColors.systemOrange,
    );
  }
  if (method.startsWith('smart.test')) {
    return const _JobVisual(
      CupertinoIcons.waveform_path,
      CupertinoColors.systemPurple,
    );
  }
  if (method.startsWith('zfs.snapshot')) {
    return const _JobVisual(CupertinoIcons.camera, CupertinoColors.systemGrey);
  }
  return const _JobVisual(CupertinoIcons.gear, CupertinoColors.systemBlue);
}

String _titleFor(Job job) {
  final description = job.description;
  if (description != null && description.isNotEmpty) return description;

  final parts = job.method.split('.');
  final last = parts.isNotEmpty ? parts.last : job.method;
  final words = last.split('_').where((w) => w.isNotEmpty);
  if (words.isEmpty) return job.method;
  return words.map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
}

String _relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

String _durationLabel(Duration duration) {
  if (duration.inMinutes < 1) return '${duration.inSeconds}s';
  if (duration.inHours < 1) {
    return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
  }
  return '${duration.inHours}h ${duration.inMinutes % 60}m';
}

/// A single job in the Jobs screen list: icon, title, live progress while
/// running, a status badge once finished, and an expandable detail panel
/// with Cancel/Retry.
class JobCardWidget extends StatefulWidget {
  final Job job;
  final Future<void> Function()? onCancel;
  final Future<void> Function()? onRetry;

  const JobCardWidget({
    super.key,
    required this.job,
    this.onCancel,
    this.onRetry,
  });

  @override
  State<JobCardWidget> createState() => _JobCardWidgetState();
}

class _JobCardWidgetState extends State<JobCardWidget> {
  bool _expanded = false;
  bool _busy = false;

  Future<void> _handleCancel() async {
    final onCancel = widget.onCancel;
    if (onCancel == null || _busy) return;
    setState(() => _busy = true);
    try {
      await onCancel();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleRetry() async {
    final onRetry = widget.onRetry;
    if (onRetry == null || _busy) return;
    setState(() => _busy = true);
    try {
      await onRetry();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final visual = _visualFor(job);

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      behavior: HitTestBehavior.opaque,
      child: Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: visual.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(visual.icon, color: visual.color, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titleFor(job),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        job.isWaiting ? 'Queued · ${job.method}' : job.method,
                        style: const TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.systemGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (job.isRunning)
                      Text(
                        '${job.progress.percent.round()}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: visual.color,
                        ),
                      )
                    else if (job.isFinished)
                      _StatusBadge(job: job, visual: visual),
                    const SizedBox(height: 4),
                    Icon(
                      _expanded
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.chevron_down,
                      size: 14,
                      color: CupertinoColors.tertiaryLabel,
                    ),
                  ],
                ),
              ],
            ),
            if (job.isRunning) ...[
              const SizedBox(height: 12),
              UsageBar(
                usage: job.progress.percent,
                color: CupertinoColors.systemBlue,
              ),
              if (job.progress.description != null) ...[
                const SizedBox(height: 6),
                Text(
                  job.progress.description!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
              if (job.elapsed != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Elapsed ${_durationLabel(job.elapsed!)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: CupertinoColors.tertiaryLabel,
                  ),
                ),
              ],
            ],
            if (_expanded) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: CupertinoColors.separator,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (job.timeStarted != null)
                      _MetaRow(
                        label: 'Started',
                        value: _relativeTime(job.timeStarted!),
                      ),
                    if (job.timeFinished != null) ...[
                      const SizedBox(height: 8),
                      _MetaRow(
                        label: 'Finished',
                        value: _relativeTime(job.timeFinished!),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _MetaRow(label: 'Method', value: job.method),
                    if (job.isFailed && job.error != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemRed.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              CupertinoIcons.exclamationmark_triangle_fill,
                              size: 14,
                              color: CupertinoColors.systemRed,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                job.error!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.label,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if ((job.isRunning && job.abortable) || job.isFailed) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_busy)
                            const CupertinoActivityIndicator(radius: 8)
                          else if (job.isFailed && widget.onRetry != null)
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              onPressed: _handleRetry,
                              child: const Text(
                                'Retry',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else if (job.isRunning &&
                              job.abortable &&
                              widget.onCancel != null)
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              onPressed: _handleCancel,
                              child: const Text(
                                'Cancel Job',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.systemRed,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Job job;
  final _JobVisual visual;

  const _StatusBadge({required this.job, required this.visual});

  @override
  Widget build(BuildContext context) {
    final label = switch (job.state) {
      JobState.success => 'Success',
      JobState.failed => 'Failed',
      JobState.aborted => 'Aborted',
      _ => 'Done',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: visual.color,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
