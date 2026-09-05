import 'package:flutter/cupertino.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/fleet_server_status.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/server_provider.dart';

class ServerListTile extends StatelessWidget {
  final NasServer server;
  final VoidCallback onTap;

  /// A fleet health snapshot for this server, if one has been fetched.
  /// When present, the tile shows a status dot plus CPU/storage readouts
  /// instead of the plain active/inactive icon.
  final FleetServerStatus? status;

  const ServerListTile({
    super.key,
    required this.server,
    required this.onTap,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) async {
              final shouldDelete = await showCupertinoDialog<bool>(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: const Text('Delete Server'),
                  content: Text(
                    'Are you sure you want to delete "${server.name}"?',
                  ),
                  actions: [
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      child: const Text('Delete'),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                ),
              );

              if (shouldDelete == true && context.mounted) {
                await context.read<ServerProvider>().deleteServer(server.id);
              }
            },
            backgroundColor: CupertinoColors.destructiveRed,
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: status != null && status!.needsAttention
                ? CupertinoColors.systemRed.withValues(alpha: 0.05)
                : null,
            border: const Border(
              bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          server.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          server.baseUrl,
                          style: const TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    color: CupertinoColors.tertiaryLabel,
                    size: 20,
                  ),
                ],
              ),
              if (status != null) ...[
                const SizedBox(height: 10),
                _buildStatusDetail(status!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    final connectivity = status?.connectivity;
    final Color color;
    if (connectivity == FleetServerConnectivity.online) {
      color = status!.needsAttention
          ? CupertinoColors.systemRed
          : CupertinoColors.activeGreen;
    } else if (connectivity == FleetServerConnectivity.offline) {
      color = CupertinoColors.systemRed;
    } else if (server.isActive) {
      color = CupertinoColors.activeGreen;
    } else {
      color = CupertinoColors.systemGrey;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(CupertinoIcons.desktopcomputer, color: color, size: 24),
    );
  }

  Widget _buildStatusDetail(FleetServerStatus status) {
    switch (status.connectivity) {
      case FleetServerConnectivity.loading:
      case FleetServerConnectivity.unknown:
        return const Padding(
          padding: EdgeInsets.only(left: 52),
          child: Text(
            'Checking…',
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.tertiaryLabel,
            ),
          ),
        );
      case FleetServerConnectivity.offline:
        return const Padding(
          padding: EdgeInsets.only(left: 52),
          child: Text(
            'Offline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.systemRed,
            ),
          ),
        );
      case FleetServerConnectivity.online:
        return Padding(
          padding: const EdgeInsets.only(left: 52, right: 8),
          child: Row(
            children: [
              Expanded(child: _buildMiniMetric('CPU', status.cpuUsage)),
              const SizedBox(width: 16),
              Expanded(child: _buildMiniMetric('Storage', status.storageUsage)),
              if (status.activeAlertCount > 0) ...[
                const SizedBox(width: 8),
                Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  size: 12,
                  color: CupertinoColors.systemRed,
                ),
              ],
            ],
          ),
        );
    }
  }

  Widget _buildMiniMetric(String label, double? value) {
    final percent = (value ?? 0).clamp(0, 100).toDouble();
    final color = percent > 85
        ? CupertinoColors.systemRed
        : percent > 65
        ? CupertinoColors.systemOrange
        : CupertinoColors.activeGreen;

    return Row(
      children: [
        Text(
          '$label ',
          style: const TextStyle(
            fontSize: 11,
            color: CupertinoColors.systemGrey,
          ),
        ),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percent / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${percent.toStringAsFixed(0)}%',
          style: const TextStyle(
            fontSize: 10,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }
}
