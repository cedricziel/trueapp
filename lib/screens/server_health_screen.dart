import 'package:flutter/cupertino.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/widgets/empty_state_widget.dart';
import 'package:truehub/widgets/jobs_bell_button.dart';

class ServerHealthScreen extends StatelessWidget {
  final NasServer server;

  const ServerHealthScreen({super.key, required this.server});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Health'),
        previousPageTitle: server.name,
        trailing: JobsBellButton(server: server),
      ),
      child: const SafeArea(
        child: EmptyStateWidget(
          icon: CupertinoIcons.heart,
          title: 'Health monitoring coming soon',
          message:
              'This feature will show CPU, memory,\ndisk usage, and system temperatures',
        ),
      ),
    );
  }
}
