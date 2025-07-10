import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/providers/server_provider.dart';
import 'package:truenas_manager/screens/add_server_screen.dart';
import 'package:truenas_manager/screens/server_detail_screen.dart';
import 'package:truenas_manager/screens/settings_screen.dart';
import 'package:truenas_manager/widgets/server_list_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final serverProvider = Provider.of<ServerProvider>(
        context,
        listen: false,
      );
      serverProvider.loadServersAndAutoSelect().then((_) {
        // If a server was auto-selected, navigate to it
        if (mounted && serverProvider.selectedServer != null) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) =>
                  ServerDetailScreen(server: serverProvider.selectedServer!),
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('TrueNAS Manager'),
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
