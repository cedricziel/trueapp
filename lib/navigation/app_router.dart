import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:truehub/screens/home_screen.dart';
import 'package:truehub/screens/settings_screen.dart';
import 'package:truehub/screens/add_server_screen.dart';
import 'package:truehub/screens/server_detail_screen.dart';
import 'package:truehub/navigation/adaptive_navigation_scaffold.dart';
import 'package:truehub/models/nas_server.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/servers',
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
      ],
    ),
    GoRoute(
      path: '/add-server',
      name: 'add-server',
      pageBuilder: (context, state) =>
          CupertinoPage(key: state.pageKey, child: const AddServerScreen()),
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
    ),
  ],
);
