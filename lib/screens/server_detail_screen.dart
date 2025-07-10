import 'package:flutter/cupertino.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/screens/server_files_screen.dart';
import 'package:truenas_manager/screens/server_health_screen.dart';
import 'package:truenas_manager/screens/edit_server_screen.dart';

class ServerDetailScreen extends StatelessWidget {
  final NasServer server;

  const ServerDetailScreen({
    super.key,
    required this.server,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(server.name),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.ellipsis),
          onPressed: () {
            showCupertinoModalPopup(
              context: context,
              builder: (context) => CupertinoActionSheet(
                actions: [
                  CupertinoActionSheetAction(
                    child: const Text('Edit Server'),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => EditServerScreen(
                            server: server,
                          ),
                        ),
                      );
                    },
                  ),
                ],
                cancelButton: CupertinoActionSheetAction(
                  isDefaultAction: true,
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            );
          },
        ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 20),
            _buildServerInfo(),
            const SizedBox(height: 30),
            _buildActionButtons(context),
            const SizedBox(height: 30),
            _buildConnectionStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildServerInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow('Host', server.host),
          const SizedBox(height: 8),
          _buildInfoRow('Port', server.port.toString()),
          const SizedBox(height: 8),
          _buildInfoRow('Protocol', server.useHttps ? 'HTTPS' : 'HTTP'),
          const SizedBox(height: 8),
          _buildInfoRow('Username', server.username),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: CupertinoColors.systemGrey,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildActionButton(
            context,
            icon: CupertinoIcons.folder,
            title: 'Files',
            subtitle: 'Browse and manage files',
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => ServerFilesScreen(server: server),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            icon: CupertinoIcons.heart,
            title: 'Health',
            subtitle: 'View system health and status',
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => ServerHealthScreen(server: server),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoColors.separator,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: CupertinoColors.activeBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.tertiaryLabel,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    final isConnected = server.lastConnected != null &&
        DateTime.now().difference(server.lastConnected!).inMinutes < 5;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConnected
            ? CupertinoColors.activeGreen.withOpacity(0.1)
            : CupertinoColors.systemOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isConnected
                ? CupertinoIcons.checkmark_circle_fill
                : CupertinoIcons.exclamationmark_circle_fill,
            color: isConnected
                ? CupertinoColors.activeGreen
                : CupertinoColors.systemOrange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'Connected' : 'Not Connected',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (server.lastConnected != null)
                  Text(
                    'Last connected: ${_formatLastConnected(server.lastConnected!)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastConnected(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minutes ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else {
      return '${diff.inDays} days ago';
    }
  }
}