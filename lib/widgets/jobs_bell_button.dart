import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/jobs_provider.dart';

/// The job-status bell dropped into every server-scoped screen's nav bar
/// trailing slot. Blue with a count badge while jobs are running, a steady
/// red dot if nothing is running but something failed recently, otherwise a
/// dim outline. Always opens the Jobs screen for [server].
class JobsBellButton extends StatelessWidget {
  final NasServer server;

  const JobsBellButton({super.key, required this.server});

  @override
  Widget build(BuildContext context) {
    return Consumer<JobsProvider>(
      builder: (context, jobsProvider, child) {
        final running = jobsProvider.runningCount;
        final needsAttention = jobsProvider.needsAttention;

        final Color color = running > 0
            ? CupertinoColors.systemBlue
            : needsAttention
            ? CupertinoColors.systemRed
            : CupertinoColors.systemGrey2;

        return CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: () =>
              context.push('/server/${server.id}/jobs', extra: server),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(CupertinoIcons.bell, color: color, size: 20),
                if (running > 0)
                  Positioned(
                    top: 3,
                    right: 3,
                    child: _CountBadge(count: running),
                  )
                else if (needsAttention)
                  const Positioned(top: 5, right: 5, child: _AttentionDot()),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CupertinoColors.systemBackground, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: CupertinoColors.white,
          height: 1.2,
        ),
      ),
    );
  }
}

class _AttentionDot extends StatelessWidget {
  const _AttentionDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed,
        shape: BoxShape.circle,
        border: Border.all(color: CupertinoColors.systemBackground, width: 1.5),
      ),
    );
  }
}
