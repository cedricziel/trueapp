import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/health_provider.dart';
import 'package:truehub/providers/jobs_provider.dart';
import 'package:truehub/providers/pool_provider.dart';

class ServerQuickActions extends StatelessWidget {
  final NasServer server;

  const ServerQuickActions({super.key, required this.server});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildTileRow(context),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionTile(
                  icon: CupertinoIcons.gear,
                  title: 'Services',
                  subtitle: 'Start, stop and restart',
                  onTap: () => context.push(
                    '/server/${server.id}/services',
                    extra: server,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTileRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Consumer<PoolProvider>(
            builder: (context, poolProvider, child) {
              final poolCount = poolProvider.pools.length;
              return _QuickActionTile(
                icon: CupertinoIcons.square_stack_3d_down_right,
                title: 'Pools',
                subtitle: poolCount == 1 ? '1 pool' : '$poolCount pools',
                onTap: () =>
                    context.push('/server/${server.id}/pools', extra: server),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionTile(
            icon: CupertinoIcons.folder,
            title: 'Files',
            subtitle: 'Browse',
            onTap: () =>
                context.push('/server/${server.id}/files', extra: server),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Consumer<HealthProvider>(
            builder: (context, healthProvider, child) {
              final activeCount = healthProvider.activeAlerts.length;
              return _QuickActionTile(
                icon: CupertinoIcons.heart,
                title: 'Health',
                subtitle: activeCount == 0
                    ? 'All clear'
                    : '$activeCount active',
                subtitleColor: activeCount == 0
                    ? CupertinoColors.systemGreen
                    : CupertinoColors.systemRed,
                showAlertDot: activeCount > 0,
                onTap: () =>
                    context.push('/server/${server.id}/health', extra: server),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Consumer<JobsProvider>(
            builder: (context, jobsProvider, child) {
              final runningCount = jobsProvider.runningCount;
              return _QuickActionTile(
                icon: CupertinoIcons.bell,
                title: 'Jobs',
                subtitle: runningCount == 0
                    ? 'None running'
                    : '$runningCount running',
                subtitleColor: jobsProvider.needsAttention
                    ? CupertinoColors.systemRed
                    : null,
                showAlertDot: jobsProvider.needsAttention,
                onTap: () =>
                    context.push('/server/${server.id}/jobs', extra: server),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A compact, icon-led quick-action card - three of these side by side
/// replace what used to be three full-width `ActionButtonWidget` rows,
/// so the dashboard scans in one glance rather than a scroll.
class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final bool showAlertDot;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.subtitleColor,
    this.showAlertDot = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: CupertinoColors.activeBlue, size: 22),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: subtitleColor != null
                        ? FontWeight.w500
                        : FontWeight.w400,
                    color:
                        subtitleColor ??
                        CupertinoColors.systemGrey.resolveFrom(context),
                  ),
                ),
              ],
            ),
            if (showAlertDot)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: CupertinoColors.systemRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
