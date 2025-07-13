import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:truehub/providers/server_provider.dart';
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
        // Only auto-navigate to server detail if there's only one server
        // This maintains the expected behavior for single-server setups
        // while allowing multiple servers to be shown in the list
        if (mounted &&
            authStatus.isAuthenticated &&
            authStatus.server != null &&
            serverProvider.servers.length == 1) {
          context.go(
            '/server/${authStatus.server!.id}',
            extra: authStatus.server,
          );
        }
      });

      // Load servers but don't auto-select for multi-server scenarios
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
            const Text('Servers'),
            const SizedBox(width: 8),
            const SessionIndicatorWidget(),
          ],
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () {
            context.go('/add-server');
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
                      context.go('/server/${server.id}', extra: server);
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
