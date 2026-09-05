import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/pool.dart';
import 'package:truehub/providers/pool_provider.dart';
import 'package:truehub/screens/pool_detail_screen.dart';
import 'package:truehub/widgets/connection_error_widget.dart';
import 'package:truehub/widgets/empty_state_widget.dart';
import 'package:truehub/widgets/jobs_bell_button.dart';
import 'package:truehub/widgets/loading_state_widget.dart';
import 'package:truehub/widgets/section_card.dart';

class ServerPoolsScreen extends StatefulWidget {
  final NasServer server;

  const ServerPoolsScreen({super.key, required this.server});

  @override
  State<ServerPoolsScreen> createState() => _ServerPoolsScreenState();
}

class _ServerPoolsScreenState extends State<ServerPoolsScreen> {
  @override
  void initState() {
    super.initState();
    _loadPools();
  }

  Future<void> _loadPools() async {
    final poolProvider = context.read<PoolProvider>();
    await poolProvider.setApiClient(widget.server);
    await poolProvider.loadPools();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('${widget.server.name} - Pools'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Back'),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: JobsBellButton(server: widget.server),
      ),
      child: SafeArea(
        child: Consumer<PoolProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const LoadingStateWidget(message: 'Loading pools...');
            }

            if (provider.connectionError != null) {
              return Center(
                child: ConnectionErrorWidget(
                  error: provider.connectionError!,
                  onRetry: _loadPools,
                  onSettings: () {
                    // Navigate back to edit server settings
                    Navigator.pop(context);
                  },
                ),
              );
            }

            if (provider.pools.isEmpty) {
              return const EmptyStateWidget(
                icon: CupertinoIcons.square_stack_3d_down_right,
                title: 'No pools found',
                message:
                    'Storage pools configured on this server will appear here.',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.pools.length,
              itemBuilder: (context, index) {
                final pool = provider.pools[index];
                return _buildPoolTile(pool);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPoolTile(Pool pool) {
    final healthy = pool.healthy;
    final disks = pool.allDisks;
    final unhealthyDisks = disks.where((disk) => !disk.isHealthy).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) =>
                  PoolDetailScreen(server: widget.server, pool: pool),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: unhealthyDisks.isEmpty
                  ? CupertinoColors.separator
                  : CupertinoColors.systemRed.withValues(alpha: 0.35),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: healthy
                          ? CupertinoColors.systemGreen.withValues(alpha: 0.1)
                          : CupertinoColors.systemRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      CupertinoIcons.square_stack_3d_down_right,
                      color: healthy
                          ? CupertinoColors.systemGreen
                          : CupertinoColors.systemRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
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
                        const SizedBox(height: 4),
                        Text(
                          pool.topologyDescription,
                          style: const TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(
                    label: pool.status,
                    color: healthy
                        ? CupertinoColors.systemGreen
                        : CupertinoColors.systemRed,
                  ),
                ],
              ),
              if (disks.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [for (final disk in disks) _buildDriveBadge(disk)],
                ),
              ],
              if (unhealthyDisks.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${unhealthyDisks.map((d) => d.name).join(', ')} '
                  '${unhealthyDisks.length == 1 ? 'needs' : 'need'} attention',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.systemRed,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// A small per-disk status chip - what turns "Mirror (2 drives)" from a
  /// text description into something that says which specific drive, if
  /// any, needs attention.
  Widget _buildDriveBadge(VdevDisk disk) {
    final (icon, color) = switch (disk.status) {
      VdevDiskStatus.online => (
        CupertinoIcons.checkmark,
        CupertinoColors.systemGreen,
      ),
      VdevDiskStatus.degraded => (
        CupertinoIcons.exclamationmark,
        CupertinoColors.systemYellow,
      ),
      VdevDiskStatus.unknown => (
        CupertinoIcons.minus,
        CupertinoColors.systemGrey,
      ),
      VdevDiskStatus.faulted ||
      VdevDiskStatus.offline ||
      VdevDiskStatus.removed ||
      VdevDiskStatus.unavail => (
        CupertinoIcons.xmark,
        CupertinoColors.systemRed,
      ),
    };

    return Container(
      width: 26,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 14, color: CupertinoColors.white),
    );
  }
}
