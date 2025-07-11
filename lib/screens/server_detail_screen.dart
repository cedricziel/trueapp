import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/providers/server_provider.dart';
import 'package:truenas_manager/providers/pool_provider.dart';
import 'package:truenas_manager/providers/app_provider.dart';
import 'package:truenas_manager/providers/system_stats_provider.dart';
import 'package:truenas_manager/widgets/system_stats_widget.dart';
import 'package:truenas_manager/widgets/authentication_state_widget.dart';
import 'package:truenas_manager/widgets/action_button_widget.dart';
import 'package:truenas_manager/widgets/pool_card_widget.dart';
import 'package:truenas_manager/widgets/app_card_widget.dart';
import 'package:truenas_manager/widgets/error_state_widget.dart';
import 'package:truenas_manager/widgets/empty_state_widget.dart';
import 'package:truenas_manager/screens/server_files_screen.dart';
import 'package:truenas_manager/screens/server_health_screen.dart';
import 'package:truenas_manager/screens/server_pools_screen.dart';
import 'package:truenas_manager/screens/edit_server_screen.dart';
import 'package:truenas_manager/screens/user_profile_screen.dart';
import 'package:truenas_manager/screens/server_apps_screen.dart';
import 'package:truenas_manager/widgets/connection_status_widget.dart';

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

      // Check if this server is already selected and authenticated
      if (serverProvider.selectedServer?.id != widget.server.id) {
        // Only select if it's a different server
        await serverProvider.selectServer(widget.server);
      }

      // Only proceed if authenticated
      if (serverProvider.isAuthenticated) {
        await serverProvider.loadCurrentUser();

        // Set up other providers
        await poolProvider.setApiClient(widget.server);
        await poolProvider.loadPools();

        await appProvider.setApiClient(widget.server);
        await appProvider.loadApps();

        await systemStatsProvider.setApiClient(widget.server);
        await systemStatsProvider.subscribeToStats();
      }
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
            middle: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConnectionStatusTitleWidget(serverId: currentServer.id),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.person_circle, size: 20),
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
                const SizedBox(width: 8),
                Expanded(
                  child: Text(currentServer.name, textAlign: TextAlign.center),
                ),
              ],
            ),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.back),
              onPressed: () {
                Navigator.pop(context);
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
          child: AuthenticationStateWidget(
            child: SafeArea(
              child: ListView(
                children: [
                  const SizedBox(height: 20),
                  _buildSystemStatsSection(currentServer),
                  const SizedBox(height: 20),
                  _buildPoolsSection(currentServer),
                  const SizedBox(height: 20),
                  _buildAppsSection(currentServer),
                  const SizedBox(height: 30),
                  _buildActionButtons(context, currentServer),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, NasServer server) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ActionButtonWidget(
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
          ActionButtonWidget(
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
          ActionButtonWidget(
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
                ErrorStateWidget(
                  title: 'Pool Error',
                  message: 'Failed to load pools: ${poolProvider.error}',
                )
              else if (poolProvider.pools.isEmpty)
                const EmptyStateWidget(
                  icon: CupertinoIcons.square_stack_3d_down_right,
                  title: 'No Pools',
                  message: 'No storage pools found',
                )
              else
                Column(
                  children: poolProvider.pools.map((pool) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PoolCardWidget(pool: pool, server: server),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
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
                ErrorStateWidget(
                  title: 'App Error',
                  message: 'Failed to load apps: ${appProvider.error}',
                )
              else if (appProvider.apps.isEmpty)
                const EmptyStateWidget(
                  icon: CupertinoIcons.app,
                  title: 'No Apps',
                  message: 'No apps found',
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
                          child: AppCardWidget(app: app),
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
                          child: AppCardWidget(app: app),
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
}
