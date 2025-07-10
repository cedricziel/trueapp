import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/providers/server_provider.dart';
import 'package:truenas_manager/screens/add_server_screen.dart';
import 'package:truenas_manager/screens/server_detail_screen.dart';
import 'package:truenas_manager/widgets/server_list_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('TrueNAS Manager'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const AddServerScreen(),
              ),
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
                  onTap: () {
                    serverProvider.selectServer(server);
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => ServerDetailScreen(
                          server: server,
                        ),
                      ),
                    );
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