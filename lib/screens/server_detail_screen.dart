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
import 'package:truehub/providers/health_provider.dart';
import 'package:truehub/screens/server_detail/server_alert_banner.dart';
import 'package:truehub/screens/server_detail/server_apps_section.dart';
import 'package:truehub/screens/server_detail/server_pools_section.dart';
import 'package:truehub/screens/server_detail/server_quick_actions.dart';
import 'package:truehub/screens/server_detail/server_system_stats_section.dart';
import 'package:truehub/widgets/authentication_state_widget.dart';
import 'package:truehub/widgets/connection_status_widget.dart';
import 'package:truehub/widgets/jobs_bell_button.dart';

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
      final healthProvider = context.read<HealthProvider>();

      // Check if this server is already selected and authenticated
      if (serverProvider.selectedServer?.id != widget.server.id) {
        // Only select if it's a different server
        await serverProvider.selectServer(widget.server);
      }

      // Only proceed if authenticated
      if (serverProvider.currentAuthStatus.isAuthenticated) {
        await poolProvider.loadPools();
        await appProvider.loadApps();
        await systemStatsProvider.subscribeToStats();

        // Subscribed here (rather than in ServerJobsScreen) so the nav bar
        // bell keeps reflecting job state on every screen pushed on top of
        // this one, not just while the Jobs screen itself is open.
        await jobsProvider.subscribeToJobs();
        await healthProvider.loadHealth();
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
                  ServerAlertBanner(server: currentServer),
                  const ServerSystemStatsSection(),
                  const SizedBox(height: 20),
                  ServerPoolsSection(server: currentServer),
                  const SizedBox(height: 20),
                  ServerAppsSection(server: currentServer),
                  const SizedBox(height: 30),
                  ServerQuickActions(server: currentServer),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
