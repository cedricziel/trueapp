import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:truehub/screens/home_screen.dart';
import 'package:truehub/screens/settings_screen.dart';
import 'package:truehub/screens/add_server_screen.dart';
import 'package:truehub/screens/server_detail_screen.dart';
import 'package:truehub/screens/user_profile_screen.dart';
import 'package:truehub/screens/edit_server_screen.dart';
import 'package:truehub/screens/server_pools_screen.dart';
import 'package:truehub/screens/server_apps_screen.dart';
import 'package:truehub/screens/server_files_screen.dart';
import 'package:truehub/screens/server_health_screen.dart';
import 'package:truehub/screens/server_jobs_screen.dart';
import 'package:truehub/screens/services_screen.dart';
import 'package:truehub/navigation/adaptive_navigation_scaffold.dart';
import 'package:truehub/navigation/server_route_host.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/telemetry_service_interface.dart';
import 'package:flutter_otel/flutter_otel.dart';

/// A server carried in `state.extra` by an in-app navigation, or `null` if
/// absent, of the wrong type, or for a different server than [state]'s
/// route - which happens for a cold start, a deep link, or a restored
/// location, none of which populate `extra`.
///
/// This is purely an optimisation [ServerRouteHost] uses to skip its loading
/// state on an in-app hop; every `/server/:serverId` route resolves the
/// server from its id regardless (ticket #84).
NasServer? _cachedServer(GoRouterState state) {
  final extra = state.extra;
  return (extra is NasServer && extra.id == state.pathParameters['serverId'])
      ? extra
      : null;
}

/// Builds a [CupertinoPage] hosting a `/server/:serverId` route (or a route
/// nested under it) through [ServerRouteHost], so [build] only ever runs
/// once the server has actually resolved.
Page<void> _serverPage(
  GoRouterState state,
  Widget Function(NasServer server) build,
) {
  return CupertinoPage(
    key: state.pageKey,
    name: state.name,
    child: ServerRouteHost(
      serverId: state.pathParameters['serverId'] ?? '',
      cachedServer: _cachedServer(state),
      builder: (context, server) => build(server),
    ),
  );
}

/// Builds a router for the app.
///
/// Exposed as a factory so tests can drive a fresh navigation stack per test
/// instead of sharing location state through a global.
///
/// With a [telemetry] service, screen changes are recorded as `app.navigation`
/// events. Pages carry their route's `name:` (a fixed template such as
/// `server-apps`), so no server id or other path parameter reaches telemetry.
GoRouter createAppRouter({
  String initialLocation = '/servers',
  TelemetryServiceInterface? telemetry,
}) {
  // A NavigatorObserver attaches to one navigator, so the root navigator and
  // the shell's nested one each need their own.
  OTelNavigatorObserver? newObserver() => telemetry == null
      ? null
      : OTelNavigatorObserver(
          logEvent: appEventLogger(telemetry.getLogger()),
          unnamedRoutePolicy: UnnamedRoutePolicy.skip,
        );
  return GoRouter(
    initialLocation: initialLocation,
    observers: [?newObserver()],
    routes: [
      ShellRoute(
        observers: [?newObserver()],
        builder: (context, state, child) {
          return AdaptiveNavigationScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/servers',
            name: 'servers',
            pageBuilder: (context, state) => CupertinoPage(
              key: state.pageKey,
              name: state.name,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => CupertinoPage(
              key: state.pageKey,
              name: state.name,
              child: const SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/server/:serverId',
            name: 'server-detail',
            pageBuilder: (context, state) => _serverPage(
              state,
              (server) => ServerDetailScreen(server: server),
            ),
            routes: [
              GoRoute(
                path: 'profile',
                name: 'server-profile',
                pageBuilder: (context, state) => _serverPage(
                  state,
                  (server) => UserProfileScreen(server: server),
                ),
              ),
              GoRoute(
                path: 'edit',
                name: 'server-edit',
                pageBuilder: (context, state) => _serverPage(
                  state,
                  (server) => EditServerScreen(server: server),
                ),
              ),
              GoRoute(
                path: 'pools',
                name: 'server-pools',
                pageBuilder: (context, state) => _serverPage(
                  state,
                  (server) => ServerPoolsScreen(server: server),
                ),
              ),
              GoRoute(
                path: 'apps',
                name: 'server-apps',
                pageBuilder: (context, state) => _serverPage(
                  state,
                  (server) => ServerAppsScreen(server: server),
                ),
              ),
              GoRoute(
                path: 'files',
                name: 'server-files',
                pageBuilder: (context, state) => _serverPage(
                  state,
                  (server) => ServerFilesScreen(server: server),
                ),
              ),
              GoRoute(
                path: 'health',
                name: 'server-health',
                pageBuilder: (context, state) => _serverPage(
                  state,
                  (server) => ServerHealthScreen(server: server),
                ),
              ),
              GoRoute(
                path: 'jobs',
                name: 'server-jobs',
                pageBuilder: (context, state) => _serverPage(
                  state,
                  (server) => ServerJobsScreen(server: server),
                ),
              ),
              GoRoute(
                path: 'services',
                name: 'server-services',
                pageBuilder: (context, state) => _serverPage(
                  state,
                  (server) => ServicesScreen(server: server),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/add-server',
        name: 'add-server',
        pageBuilder: (context, state) => CupertinoPage(
          key: state.pageKey,
          name: state.name,
          child: const AddServerScreen(),
        ),
      ),
    ],
  );
}
