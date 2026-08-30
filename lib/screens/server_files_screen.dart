import 'package:flutter/cupertino.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/widgets/empty_state_widget.dart';
import 'package:truehub/widgets/jobs_bell_button.dart';

class ServerFilesScreen extends StatelessWidget {
  final NasServer server;

  const ServerFilesScreen({super.key, required this.server});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Files'),
        previousPageTitle: server.name,
        trailing: JobsBellButton(server: server),
      ),
      child: const SafeArea(
        child: EmptyStateWidget(
          icon: CupertinoIcons.folder,
          title: 'File browsing coming soon',
          message:
              'This feature will allow you to browse\nand manage files on your TrueNAS server',
        ),
      ),
    );
  }
}
