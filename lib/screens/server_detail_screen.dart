import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/providers/server_provider.dart';
import 'package:truenas_manager/providers/pool_provider.dart';
import 'package:truenas_manager/providers/app_provider.dart';
import 'package:truenas_manager/providers/system_stats_provider.dart';
import 'package:truenas_manager/models/app.dart';
import 'package:truenas_manager/widgets/app_icon.dart';
import 'package:truenas_manager/widgets/system_stats_widget.dart';
import 'package:truenas_manager/screens/app_detail_screen.dart';
import 'package:truenas_manager/screens/server_files_screen.dart';
import 'package:truenas_manager/screens/server_health_screen.dart';
import 'package:truenas_manager/screens/server_pools_screen.dart';
import 'package:truenas_manager/screens/pool_detail_screen.dart';
import 'package:truenas_manager/screens/edit_server_screen.dart';
import 'package:truenas_manager/screens/user_profile_screen.dart';
import 'package:truenas_manager/screens/server_apps_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final serverProvider = context.read<ServerProvider>();
      final poolProvider = context.read<PoolProvider>();
      final appProvider = context.read<AppProvider>();
      final systemStatsProvider = context.read<SystemStatsProvider>();

      // Set up server connection first
      await serverProvider.selectServer(widget.server);
      await serverProvider.loadCurrentUser();

      // Then set up other providers
      await poolProvider.setApiClient(widget.server);
      await poolProvider.loadPools();

      await appProvider.setApiClient(widget.server);
      await appProvider.loadApps();

      await systemStatsProvider.setApiClient(widget.server);
      await systemStatsProvider.subscribeToStats();
    });
  }

  @override
  void dispose() {
    // Unsubscribe from system stats when screen is disposed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SystemStatsProvider>().unsubscribeFromStats();
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServerProvider>(
      builder: (context, serverProvider, child) {
        // Use the selectedServer from the provider if available, fallback to server
        final currentServer = serverProvider.selectedServer ?? widget.server;

        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text(currentServer.name),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.person_circle),
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) =>
                        UserProfileScreen(server: currentServer),
                  ),
                );
              },
            ),
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
                        onPressed: () async {
                          Navigator.pop(context);
                          final result = await Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) =>
                                  EditServerScreen(server: currentServer),
                            ),
                          );

                          // Refresh server data if changes were made
                          if (result == true && mounted) {
                            if (context.mounted) {
                              final serverProvider = context
                                  .read<ServerProvider>();
                              await serverProvider.refreshSelectedServer();
                            }
                          }
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
            child: ListView(
              children: [
                const SizedBox(height: 20),
                _buildServerInfo(currentServer),
                const SizedBox(height: 20),
                _buildSystemStatsSection(currentServer),
                const SizedBox(height: 20),
                _buildPoolsSection(currentServer),
                const SizedBox(height: 20),
                _buildAppsSection(currentServer),
                const SizedBox(height: 30),
                _buildActionButtons(context, currentServer),
                const SizedBox(height: 30),
                _buildConnectionStatus(currentServer),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServerInfo(NasServer server) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow('Host', server.host),
          const SizedBox(height: 8),
          _buildInfoRow('Port', server.port.toString()),
          const SizedBox(height: 8),
          _buildInfoRow('Protocol', server.useHttps ? 'HTTPS' : 'HTTP'),
          const SizedBox(height: 8),
          _buildInfoRow('Username', server.username),
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

  Widget _buildActionButtons(BuildContext context, NasServer server) {
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
                  builder: (context) => ServerPoolsScreen(server: server),
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
                  builder: (context) => ServerFilesScreen(server: server),
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
                  builder: (context) => ServerHealthScreen(server: server),
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

  Widget _buildConnectionStatus(NasServer server) {
    final isConnected =
        server.lastConnected != null &&
        DateTime.now().difference(server.lastConnected!).inMinutes < 5;

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
                if (server.lastConnected != null)
                  Text(
                    'Last connected: ${_formatLastConnected(server.lastConnected!)}',
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

  Widget _buildPoolsSection(NasServer server) {
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
                              ServerPoolsScreen(server: server),
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
                      child: _buildPoolCard(pool, server),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPoolCard(Map<String, dynamic> pool, NasServer server) {
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
            builder: (context) => PoolDetailScreen(server: server, pool: pool),
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
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    if (bytes < 1024 * 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
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

  Widget _buildSystemStatsSection(NasServer server) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'System Stats',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              Consumer<SystemStatsProvider>(
                builder: (context, statsProvider, child) {
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Icon(
                      statsProvider.isSubscribed
                          ? CupertinoIcons.pause_circle
                          : CupertinoIcons.play_circle,
                    ),
                    onPressed: () {
                      if (statsProvider.isSubscribed) {
                        statsProvider.unsubscribeFromStats();
                      } else {
                        statsProvider.subscribeToStats();
                      }
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const SystemStatsWidget(),
        ],
      ),
    );
  }

  Widget _buildAppsSection(NasServer server) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Apps',
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
                              ServerAppsScreen(server: server),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (appProvider.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CupertinoActivityIndicator(),
                  ),
                )
              else if (appProvider.error != null)
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
                          'Failed to load apps: ${appProvider.error}',
                          style: const TextStyle(
                            color: CupertinoColors.systemRed,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (appProvider.apps.isEmpty)
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
                          CupertinoIcons.app,
                          size: 32,
                          color: CupertinoColors.systemGrey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No apps found',
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
                  children: [
                    // Show installed apps first
                    if (appProvider.installedApps.isNotEmpty) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Installed Apps',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ),
                      ),
                      ...appProvider.installedApps.take(3).map((app) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildAppCard(app),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                    // Show available apps
                    if (appProvider.availableApps.isNotEmpty) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Available Apps',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ),
                      ),
                      ...appProvider.availableApps.take(4).map((app) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildAppCard(app),
                        );
                      }),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppCard(App app) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) => AppDetailScreen(app: app)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CupertinoColors.separator, width: 0.5),
        ),
        child: Row(
          children: [
            AppIcon(app: app, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    app.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
                    color: app.installed
                        ? CupertinoColors.systemGreen.withOpacity(0.1)
                        : CupertinoColors.systemBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    app.installed ? 'Installed' : 'Available',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: app.installed
                          ? CupertinoColors.systemGreen
                          : CupertinoColors.systemBlue,
                    ),
                  ),
                ),
                if (app.categories.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      app.categories.first,
                      style: const TextStyle(
                        fontSize: 11,
                        color: CupertinoColors.tertiaryLabel,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
