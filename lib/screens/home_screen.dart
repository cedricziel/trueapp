import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/screens/add_server_screen.dart';
import 'package:truehub/screens/server_detail_screen.dart';
import 'package:truehub/screens/settings_screen.dart';
import 'package:truehub/widgets/server_list_tile.dart';
import 'package:truehub/widgets/session_indicator_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final serverProvider = Provider.of<ServerProvider>(
        context,
        listen: false,
      );

      // Listen to authentication state changes
      _authSubscription = serverProvider.authenticationStream.listen((
        authStatus,
      ) {
        if (mounted &&
            authStatus.isAuthenticated &&
            authStatus.server != null) {
          // Only navigate when successfully authenticated
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) =>
                  ServerDetailScreen(server: authStatus.server!),
            ),
          );
        }
      });

      // Load servers and attempt auto-selection
      serverProvider.loadServersAndAutoSelect();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('TrueNAS Manager'),
            const SizedBox(width: 8),
            const SessionIndicatorWidget(),
          ],
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.settings),
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => const AddServerScreen()),
            );
          },
        ),
      ),
      child: SafeArea(
        child: Consumer<ServerProvider>(
          builder: (context, serverProvider, child) {
            if (serverProvider.servers.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.desktopcomputer,
                      size: 64,
                      color: CupertinoColors.systemGrey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No servers added yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap + to add your first TrueNAS server',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey2,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: serverProvider.servers.length,
              itemBuilder: (context, index) {
                final server = serverProvider.servers[index];
                return ServerListTile(
                  server: server,
                  onTap: () async {
                    await serverProvider.selectServer(server);
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) =>
                              ServerDetailScreen(server: server),
                        ),
                      );
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
