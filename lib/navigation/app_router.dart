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
import 'package:truehub/navigation/adaptive_navigation_scaffold.dart';
import 'package:truehub/models/nas_server.dart';

/// Builds a router for the app.
///
/// Exposed as a factory rather than only as the [appRouter] singleton so tests
/// can drive a fresh navigation stack per test instead of sharing location
/// state through a global.
GoRouter createAppRouter({String initialLocation = '/servers'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AdaptiveNavigationScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/servers',
          name: 'servers',
          pageBuilder: (context, state) =>
              CupertinoPage(key: state.pageKey, child: const HomeScreen()),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder: (context, state) =>
              CupertinoPage(key: state.pageKey, child: const SettingsScreen()),
        ),
        GoRoute(
          path: '/server/:serverId',
          name: 'server-detail',
          pageBuilder: (context, state) {
            final server = state.extra as NasServer;
            return CupertinoPage(
              key: state.pageKey,
              child: ServerDetailScreen(server: server),
            );
          },
          routes: [
            GoRoute(
              path: 'profile',
              name: 'server-profile',
              pageBuilder: (context, state) {
                final server = state.extra as NasServer;
                return CupertinoPage(
                  key: state.pageKey,
                  child: UserProfileScreen(server: server),
                );
              },
            ),
            GoRoute(
              path: 'edit',
              name: 'server-edit',
              pageBuilder: (context, state) {
                final server = state.extra as NasServer;
                return CupertinoPage(
                  key: state.pageKey,
                  child: EditServerScreen(server: server),
                );
              },
            ),
            GoRoute(
              path: 'pools',
              name: 'server-pools',
              pageBuilder: (context, state) {
                final server = state.extra as NasServer;
                return CupertinoPage(
                  key: state.pageKey,
                  child: ServerPoolsScreen(server: server),
                );
              },
            ),
            GoRoute(
              path: 'apps',
              name: 'server-apps',
              pageBuilder: (context, state) {
                final server = state.extra as NasServer;
                return CupertinoPage(
                  key: state.pageKey,
                  child: ServerAppsScreen(server: server),
                );
              },
            ),
            GoRoute(
              path: 'files',
              name: 'server-files',
              pageBuilder: (context, state) {
                final server = state.extra as NasServer;
                return CupertinoPage(
                  key: state.pageKey,
                  child: ServerFilesScreen(server: server),
                );
              },
            ),
            GoRoute(
              path: 'health',
              name: 'server-health',
              pageBuilder: (context, state) {
                final server = state.extra as NasServer;
                return CupertinoPage(
                  key: state.pageKey,
                  child: ServerHealthScreen(server: server),
                );
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/add-server',
      name: 'add-server',
      pageBuilder: (context, state) =>
          CupertinoPage(key: state.pageKey, child: const AddServerScreen()),
    ),
  ],
);

/// The router instance used by the running app.
final GoRouter appRouter = createAppRouter();
