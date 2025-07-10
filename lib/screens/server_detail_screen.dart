import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/providers/server_provider.dart';
import 'package:truenas_manager/providers/pool_provider.dart';
import 'package:truenas_manager/screens/server_files_screen.dart';
import 'package:truenas_manager/screens/server_health_screen.dart';
import 'package:truenas_manager/screens/server_pools_screen.dart';
import 'package:truenas_manager/screens/pool_detail_screen.dart';
import 'package:truenas_manager/screens/edit_server_screen.dart';

class ServerDetailScreen extends StatefulWidget {
  final NasServer server;

  const ServerDetailScreen({super.key, required this.server});

  @override
  State<ServerDetailScreen> createState() => _ServerDetailScreenState();
}

class _ServerDetailScreenState extends State<ServerDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final serverProvider = context.read<ServerProvider>();
      final poolProvider = context.read<PoolProvider>();

      serverProvider.selectServer(widget.server);
      serverProvider.loadCurrentUser();

      poolProvider.setApiClient(widget.server);
      poolProvider.loadPools();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.server.name),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.ellipsis),
          onPressed: () {
            showCupertinoModalPopup(
              context: context,
              builder: (context) => CupertinoActionSheet(
                actions: [
                  CupertinoActionSheetAction(
                    child: const Text('Edit Server'),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) =>
                              EditServerScreen(server: widget.server),
                        ),
                      );
                    },
                  ),
                ],
                cancelButton: CupertinoActionSheetAction(
                  isDefaultAction: true,
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            );
          },
        ),
      ),
      child: SafeArea(
        child: Consumer<ServerProvider>(
          builder: (context, provider, child) {
            return ListView(
              children: [
                const SizedBox(height: 20),
                _buildServerInfo(),
                const SizedBox(height: 20),
                _buildUserInfo(provider),
                const SizedBox(height: 20),
                _buildPoolsSection(),
                const SizedBox(height: 30),
                _buildActionButtons(context),
                const SizedBox(height: 30),
                _buildConnectionStatus(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildServerInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow('Host', widget.server.host),
          const SizedBox(height: 8),
          _buildInfoRow('Port', widget.server.port.toString()),
          const SizedBox(height: 8),
          _buildInfoRow('Protocol', widget.server.useHttps ? 'HTTPS' : 'HTTP'),
          const SizedBox(height: 8),
          _buildInfoRow('Username', widget.server.username),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: CupertinoColors.systemGrey,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildActionButton(
            context,
            icon: CupertinoIcons.square_stack_3d_down_right,
            title: 'Pools',
            subtitle: 'View storage pools and datasets',
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) =>
                      ServerPoolsScreen(server: widget.server),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            icon: CupertinoIcons.folder,
            title: 'Files',
            subtitle: 'Browse and manage files',
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) =>
                      ServerFilesScreen(server: widget.server),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            icon: CupertinoIcons.heart,
            title: 'Health',
            subtitle: 'View system health and status',
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) =>
                      ServerHealthScreen(server: widget.server),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CupertinoColors.separator, width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: CupertinoColors.activeBlue, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
      ),
    );
  }

  Widget _buildUserInfo(ServerProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.person_circle,
                color: CupertinoColors.activeBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Current User',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (provider.isLoadingUser)
                const CupertinoActivityIndicator()
              else if (provider.currentUser == null &&
                  provider.userError == null)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Load'),
                  onPressed: () => provider.loadCurrentUser(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (provider.userError != null)
            Text(
              'Error: ${provider.userError}',
              style: const TextStyle(
                color: CupertinoColors.systemRed,
                fontSize: 14,
              ),
            )
          else if (provider.currentUser != null) ...[
            _buildInfoRow('Name', provider.currentUser!.displayName),
            const SizedBox(height: 8),
            _buildInfoRow('Username', provider.currentUser!.username),
            const SizedBox(height: 8),
            _buildInfoRow('Source', provider.currentUser!.sourceDisplayName),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Home Directory',
              provider.currentUser!.homeDirectory,
            ),
            if (provider.currentUser!.isAdministrator) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.checkmark_shield,
                    color: CupertinoColors.activeGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Administrator',
                    style: TextStyle(
                      color: CupertinoColors.activeGreen,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
            if (provider.currentUser!.hasTwoFactor) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.lock_shield,
                    color: CupertinoColors.activeBlue,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Two-Factor Enabled',
                    style: TextStyle(
                      color: CupertinoColors.activeBlue,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ] else
            const Text(
              'User information not loaded',
              style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14),
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    final isConnected =
        widget.server.lastConnected != null &&
        DateTime.now().difference(widget.server.lastConnected!).inMinutes < 5;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConnected
            ? CupertinoColors.activeGreen.withOpacity(0.1)
            : CupertinoColors.systemOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isConnected
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.exclamationmark_circle_fill,
            color: isConnected
                ? CupertinoColors.activeGreen
                : CupertinoColors.systemOrange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'Connected' : 'Not Connected',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (widget.server.lastConnected != null)
                  Text(
                    'Last connected: ${_formatLastConnected(widget.server.lastConnected!)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoolsSection() {
    return Consumer<PoolProvider>(
      builder: (context, poolProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Storage Pools',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('View All'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) =>
                              ServerPoolsScreen(server: widget.server),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (poolProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CupertinoActivityIndicator(),
                  ),
                )
              else if (poolProvider.error != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CupertinoColors.systemRed.withOpacity(0.3),
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
                          'Failed to load pools: ${poolProvider.error}',
                          style: const TextStyle(
                            color: CupertinoColors.systemRed,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (poolProvider.pools.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(
                          CupertinoIcons.square_stack_3d_down_right,
                          size: 32,
                          color: CupertinoColors.systemGrey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No storage pools found',
                          style: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: poolProvider.pools.map((pool) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPoolCard(pool),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPoolCard(Map<String, dynamic> pool) {
    final name = pool['name'] as String? ?? 'Unknown';
    final status = pool['status'] as String? ?? 'Unknown';
    final healthy = pool['healthy'] as bool? ?? false;

    // Extract pool topology information
    final topology = pool['topology'] as Map<String, dynamic>?;
    final poolTypeDescription = _getPoolTypeDescription(topology);

    return GestureDetector(
      onTap: () {
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
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CupertinoColors.separator, width: 0.5),
        ),
        child: Column(
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: healthy
                        ? CupertinoColors.systemGreen.withOpacity(0.1)
                        : CupertinoColors.systemRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    CupertinoIcons.square_stack_3d_down_right,
                    color: healthy
                        ? CupertinoColors.systemGreen
                        : CupertinoColors.systemRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
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
                      const SizedBox(height: 2),
                      Text(
                        poolTypeDescription,
                        style: const TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: healthy
                            ? CupertinoColors.systemGreen.withOpacity(0.1)
                            : CupertinoColors.systemRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: healthy
                              ? CupertinoColors.systemGreen
                              : CupertinoColors.systemRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Storage Info Row
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStorageMetric(
                    'Used',
                    _getPoolUsedSpace(pool),
                    CupertinoColors.systemBlue,
                  ),
                ),
                Expanded(
                  child: _buildStorageMetric(
                    'Available',
                    _getPoolAvailableSpace(pool),
                    CupertinoColors.systemGreen,
                  ),
                ),
                Expanded(
                  child: _buildStorageMetric(
                    'Total',
                    _getPoolTotalSpace(pool),
                    CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }

  String _getPoolTypeDescription(Map<String, dynamic>? topology) {
    if (topology == null) return 'Unknown configuration';

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

  String _getPoolUsedSpace(Map<String, dynamic> pool) {
    // Try to get allocated space from pool properties
    final allocated = pool['allocated'] as int?;
    if (allocated != null) {
      return _formatBytes(allocated);
    }
    return 'Unknown';
  }

  String _getPoolAvailableSpace(Map<String, dynamic> pool) {
    // Try to get free space from pool properties
    final free = pool['free'] as int?;
    if (free != null) {
      return _formatBytes(free);
    }
    return 'Unknown';
  }

  String _getPoolTotalSpace(Map<String, dynamic> pool) {
    // Calculate total from allocated + free
    final allocated = pool['allocated'] as int?;
    final free = pool['free'] as int?;

    if (allocated != null && free != null) {
      return _formatBytes(allocated + free);
    }

    // Fallback to size if available
    final size = pool['size'] as int?;
    if (size != null) {
      return _formatBytes(size);
    }

    return 'Unknown';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    if (bytes < 1024 * 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    return '${(bytes / (1024 * 1024 * 1024 * 1024)).toStringAsFixed(1)}TB';
  }

  String _formatLastConnected(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minutes ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else {
      return '${diff.inDays} days ago';
    }
  }
}
