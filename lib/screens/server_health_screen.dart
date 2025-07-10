import 'package:flutter/cupertino.dart';
import 'package:truenas_manager/models/nas_server.dart';

class ServerHealthScreen extends StatelessWidget {
  final NasServer server;

  const ServerHealthScreen({super.key, required this.server});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Health'),
        previousPageTitle: server.name,
      ),
      child: const SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.heart,
                size: 64,
                color: CupertinoColors.systemGrey,
              ),
              SizedBox(height: 16),
              Text(
                'Health monitoring coming soon',
                style: TextStyle(
                  fontSize: 18,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This feature will show CPU, memory,\ndisk usage, and system temperatures',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
