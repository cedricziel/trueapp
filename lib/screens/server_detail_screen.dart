import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/navigation/shell_navigation_leading.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/providers/pool_provider.dart';
import 'package:truehub/providers/app_provider.dart';
import 'package:truehub/providers/system_stats_provider.dart';
import 'package:truehub/providers/jobs_provider.dart';
import 'package:truehub/widgets/system_stats_widget.dart';
import 'package:truehub/widgets/authentication_state_widget.dart';
import 'package:truehub/widgets/action_button_widget.dart';
import 'package:truehub/widgets/pool_card_widget.dart';
import 'package:truehub/widgets/app_card_widget.dart';
import 'package:truehub/widgets/error_state_widget.dart';
import 'package:truehub/widgets/empty_state_widget.dart';
import 'package:truehub/widgets/loading_state_widget.dart';
import 'package:truehub/widgets/connection_status_widget.dart';
import 'package:truehub/widgets/jobs_bell_button.dart';
import 'package:truehub/widgets/section_header.dart';

class ServerDetailScreen extends StatefulWidget {
  final NasServer server;

  const ServerDetailScreen({super.key, required this.server});

  @override
  State<ServerDetailScreen> createState() => _ServerDetailScreenState();
}

class _ServerDetailScreenState extends State<ServerDetailScreen> {
  SystemStatsProvider? _systemStatsProvider;
  JobsProvider? _jobsProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final serverProvider = context.read<ServerProvider>();
      final poolProvider = context.read<PoolProvider>();
      final appProvider = context.read<AppProvider>();
      final systemStatsProvider = context.read<SystemStatsProvider>();
      final jobsProvider = context.read<JobsProvider>();

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

        // Subscribed here (rather than in ServerJobsScreen) so the nav bar
        // bell keeps reflecting job state on every screen pushed on top of
        // this one, not just while the Jobs screen itself is open.
        await jobsProvider.setApiClient(widget.server);
        await jobsProvider.subscribeToJobs();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // didChangeDependencies() runs after initState() and again any time an
    // InheritedWidget this element depends on notifies - here that's the
    // ModalRoute this screen builds against via
    // ShellNavigationLeading.maybeBuild()'s `ModalRoute.of(context)`, which
    // fires whenever a sub-route (Edit Server, Pools, Files, Health, ...)
    // is pushed on top of or popped back to this screen. `??=` makes the
    // capture idempotent across those repeat calls; assigning unconditionally
    // to a `late final` field here would throw a LateInitializationError the
    // first time the user navigated to any of this screen's sub-routes.
    _systemStatsProvider ??= context.read<SystemStatsProvider>();
    _jobsProvider ??= context.read<JobsProvider>();
  }

  @override
  void dispose() {
    // Unsubscribe from system stats and jobs when screen is disposed. The
    // providers were captured synchronously in didChangeDependencies(), so
    // this runs immediately and doesn't need a frame boundary or a `mounted`
    // check - by the time dispose() runs the element is already unmounted,
    // which made a post-frame callback here dead code.
    _systemStatsProvider?.unsubscribeFromStats();
    _jobsProvider?.unsubscribeFromJobs();
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
            leading: ShellNavigationLeading.maybeBuild(
              context,
              previousPageTitle: 'Servers',
            ),
            middle: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConnectionStatusTitleWidget(serverId: currentServer.id),
                const SizedBox(width: 8),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.person_circle, size: 20),
                  onPressed: () {
                    context.push(
                      '/server/${currentServer.id}/profile',
                      extra: currentServer,
                    );
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(currentServer.name, textAlign: TextAlign.center),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                JobsBellButton(server: currentServer),
                CupertinoButton(
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
                              context.push(
                                '/server/${currentServer.id}/edit',
                                extra: currentServer,
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
              ],
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
              context.push('/server/${server.id}/pools', extra: server);
            },
          ),
          const SizedBox(height: 12),
          ActionButtonWidget(
            icon: CupertinoIcons.folder,
            title: 'Files',
            subtitle: 'Browse and manage files',
            onTap: () {
              context.push('/server/${server.id}/files', extra: server);
            },
          ),
          const SizedBox(height: 12),
          ActionButtonWidget(
            icon: CupertinoIcons.heart,
            title: 'Health',
            subtitle: 'View system health and status',
            onTap: () {
              context.push('/server/${server.id}/health', extra: server);
            },
          ),
          const SizedBox(height: 12),
          ActionButtonWidget(
            icon: CupertinoIcons.bell,
            title: 'Jobs',
            subtitle: 'View running, queued, and finished jobs',
            onTap: () {
              context.push('/server/${server.id}/jobs', extra: server);
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
              SectionHeader(
                title: 'Storage Pools',
                action: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    context.push('/server/${server.id}/pools', extra: server);
                  },
                  child: const Text('View All'),
                ),
              ),
              const SizedBox(height: 12),
              if (poolProvider.isLoading)
                const LoadingStateWidget(message: 'Loading pools...')
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
          SectionHeader(
            title: 'System Stats',
            action: Consumer<SystemStatsProvider>(
              builder: (context, statsProvider, child) {
                return CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    if (statsProvider.isSubscribed) {
                      statsProvider.unsubscribeFromStats();
                    } else {
                      statsProvider.subscribeToStats();
                    }
                  },
                  child: Icon(
                    statsProvider.isSubscribed
                        ? CupertinoIcons.pause_circle
                        : CupertinoIcons.play_circle,
                  ),
                );
              },
            ),
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
              SectionHeader(
                title: 'Apps',
                action: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    context.push('/server/${server.id}/apps', extra: server);
                  },
                  child: const Text('View All'),
                ),
              ),
              const SizedBox(height: 12),
              if (appProvider.isLoading)
                const LoadingStateWidget(message: 'Loading apps...')
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
                    // Apps Summary Card
                    _buildAppsSummaryCard(context, appProvider, server),
                    const SizedBox(height: 16),
                    // Show favorite apps
                    if (appProvider.favoriteApps.isNotEmpty) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.heart_fill,
                                color: CupertinoColors.systemRed,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Favorite Apps',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ...appProvider.favoriteApps.take(3).map((appConfig) {
                        // Convert AppConfig to App for display
                        try {
                          final app = appProvider.apps.firstWhere(
                            (app) => app.name == appConfig.appName,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AppCardWidget(app: app),
                          );
                        } catch (e) {
                          return const SizedBox.shrink();
                        }
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

  Widget _buildAppsSummaryCard(
    BuildContext context,
    AppProvider appProvider,
    NasServer server,
  ) {
    // Calculate app statistics
    final installedApps = appProvider.apps
        .where((app) => app.installed)
        .toList();
    final availableApps = appProvider.apps
        .where((app) => !app.installed)
        .toList();
    final appsWithUpdates = installedApps
        .where(
          (app) => app.upgradeInfo != null && app.upgradeInfo!.upgradeAvailable,
        )
        .toList();

    return GestureDetector(
      onTap: () {
        context.push('/server/${server.id}/apps', extra: server);
      },
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
              children: [
                const Icon(
                  CupertinoIcons.app_badge,
                  size: 24,
                  color: CupertinoColors.systemBlue,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Apps Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: CupertinoColors.systemGrey,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAppStat(
                    icon: CupertinoIcons.checkmark_circle_fill,
                    color: CupertinoColors.systemGreen,
                    count: installedApps.length,
                    label: 'Installed',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAppStat(
                    icon: CupertinoIcons.arrow_up_circle_fill,
                    color: appsWithUpdates.isNotEmpty
                        ? CupertinoColors.systemYellow
                        : CupertinoColors.systemGrey,
                    count: appsWithUpdates.length,
                    label: 'Updates',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAppStat(
                    icon: CupertinoIcons.square_grid_2x2,
                    color: CupertinoColors.systemBlue,
                    count: availableApps.length,
                    label: 'Available',
                  ),
                ),
              ],
            ),
            if (appsWithUpdates.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      size: 14,
                      color: CupertinoColors.systemYellow,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${appsWithUpdates.length} app${appsWithUpdates.length == 1 ? '' : 's'} ${appsWithUpdates.length == 1 ? 'has' : 'have'} updates available',
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
          ],
        ),
      ),
    );
  }

  Widget _buildAppStat({
    required IconData icon,
    required Color color,
    required int count,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
}
