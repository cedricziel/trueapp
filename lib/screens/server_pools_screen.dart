import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/providers/pool_provider.dart';
import 'package:truenas_manager/screens/pool_detail_screen.dart';
import 'package:truenas_manager/widgets/connection_error_widget.dart';

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
    poolProvider.setApiClient(widget.server);
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
      ),
      child: SafeArea(
        child: Consumer<PoolProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CupertinoActivityIndicator());
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
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.square_stack_3d_down_right,
                      size: 48,
                      color: CupertinoColors.systemGrey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No pools found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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

  Widget _buildPoolTile(Map<String, dynamic> pool) {
    final name = pool['name'] as String? ?? 'Unknown';
    final status = pool['status'] as String? ?? 'Unknown';
    final healthy = pool['healthy'] as bool? ?? false;

    // Calculate total space
    final topology = pool['topology'] as Map<String, dynamic>?;

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
            border: Border.all(color: CupertinoColors.separator, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: healthy
                      ? CupertinoColors.systemGreen.withOpacity(0.1)
                      : CupertinoColors.systemRed.withOpacity(0.1),
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
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: $status',
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 14,
                      ),
                    ),
                    if (topology != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _getPoolTypeDescription(topology),
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                color: CupertinoColors.systemGrey3,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPoolTypeDescription(Map<String, dynamic> topology) {
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
}
