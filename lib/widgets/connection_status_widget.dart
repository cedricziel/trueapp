import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/providers/connection_status_provider.dart';

class ConnectionStatusWidget extends StatelessWidget {
  final String serverId;
  final bool compact;

  const ConnectionStatusWidget({
    super.key,
    required this.serverId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionStatusProvider>(
      builder: (context, provider, child) {
        final status = provider.getStatus(serverId);

        if (status == null) {
          return _buildIndicator(
            TrueNASConnectionState.disconnected,
            'Not Connected',
            null,
            compact,
          );
        }

        String statusText;
        switch (status.state) {
          case TrueNASConnectionState.connected:
            if (status.isHealthy) {
              statusText = compact ? '' : 'Connected';
            } else {
              statusText = compact ? '' : 'Connection Issues';
            }
            break;
          case TrueNASConnectionState.connecting:
            statusText = compact ? '' : 'Connecting...';
            break;
          case TrueNASConnectionState.reconnecting:
            statusText = compact ? '' : 'Reconnecting...';
            break;
          case TrueNASConnectionState.error:
            statusText = compact ? '' : 'Connection Error';
            break;
          case TrueNASConnectionState.disconnected:
            statusText = compact ? '' : 'Disconnected';
            break;
        }

        return _buildIndicator(
          status.state,
          statusText,
          status.latency,
          compact,
        );
      },
    );
  }

  Widget _buildIndicator(
    TrueNASConnectionState state,
    String text,
    Duration? latency,
    bool isCompact,
  ) {
    Color color;
    IconData icon;

    switch (state) {
      case TrueNASConnectionState.connected:
        color = CupertinoColors.systemGreen;
        icon = CupertinoIcons.checkmark_circle_fill;
        break;
      case TrueNASConnectionState.connecting:
      case TrueNASConnectionState.reconnecting:
        color = CupertinoColors.systemOrange;
        icon = CupertinoIcons.arrow_clockwise;
        break;
      case TrueNASConnectionState.error:
        color = CupertinoColors.systemRed;
        icon = CupertinoIcons.exclamationmark_circle_fill;
        break;
      case TrueNASConnectionState.disconnected:
        color = CupertinoColors.systemGrey;
        icon = CupertinoIcons.circle;
        break;
    }

    if (isCompact) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        if (text.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (latency != null && state == TrueNASConnectionState.connected) ...[
          const SizedBox(width: 4),
          Text(
            '${latency.inMilliseconds}ms',
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}

class ConnectionStatusTitleWidget extends StatelessWidget {
  final String serverId;

  const ConnectionStatusTitleWidget({super.key, required this.serverId});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionStatusProvider>(
      builder: (context, provider, child) {
        final status = provider.getStatus(serverId);

        if (status == null) {
          return const SizedBox.shrink();
        }

        Color color;
        IconData icon;
        String tooltip;

        switch (status.state) {
          case TrueNASConnectionState.connected:
            if (status.isHealthy) {
              color = CupertinoColors.systemGreen;
              icon = CupertinoIcons.wifi;
              tooltip = 'Connected';
              if (status.latency != null) {
                tooltip += ' (${status.latency!.inMilliseconds}ms)';
              }
            } else {
              color = CupertinoColors.systemOrange;
              icon = CupertinoIcons.wifi_exclamationmark;
              tooltip = 'Connection Issues';
            }
            break;
          case TrueNASConnectionState.connecting:
            color = CupertinoColors.systemOrange;
            icon = CupertinoIcons.arrow_clockwise;
            tooltip = 'Connecting...';
            break;
          case TrueNASConnectionState.reconnecting:
            color = CupertinoColors.systemOrange;
            icon = CupertinoIcons.arrow_clockwise;
            tooltip = 'Reconnecting...';
            break;
          case TrueNASConnectionState.error:
            color = CupertinoColors.systemRed;
            icon = CupertinoIcons.wifi_slash;
            tooltip = 'Connection Error';
            if (status.error != null) {
              tooltip += ': ${status.error}';
            }
            break;
          case TrueNASConnectionState.disconnected:
            color = CupertinoColors.systemGrey;
            icon = CupertinoIcons.wifi_slash;
            tooltip = 'Disconnected';
            break;
        }

        return GestureDetector(
          onTap: () {
            // Show detailed connection info in a popup
            _showConnectionDetails(context, status, tooltip);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 16),
                if (status.state == TrueNASConnectionState.connecting ||
                    status.state == TrueNASConnectionState.reconnecting) ...[
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CupertinoActivityIndicator(color: color, radius: 6),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConnectionDetails(
    BuildContext context,
    ConnectionStatus status,
    String tooltip,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Connection Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tooltip),
            if (status.connectionUrl != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'URL: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Text(
                      status.connectionUrl!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              if (status.isLocalConnection != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      status.isLocalConnection!
                          ? CupertinoIcons.house_fill
                          : CupertinoIcons.globe,
                      size: 14,
                      color: status.isLocalConnection!
                          ? CupertinoColors.systemGreen
                          : CupertinoColors.systemBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status.isLocalConnection!
                          ? 'Local Network'
                          : 'Remote Connection',
                      style: TextStyle(
                        fontSize: 12,
                        color: status.isLocalConnection!
                            ? CupertinoColors.systemGreen
                            : CupertinoColors.systemBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 8),
            Text('Last ping: ${_formatDateTime(status.lastPing)}'),
            if (status.lastPong != null) ...[
              const SizedBox(height: 4),
              Text('Last pong: ${_formatDateTime(status.lastPong!)}'),
            ],
            if (status.latency != null) ...[
              const SizedBox(height: 4),
              Text('Latency: ${status.latency!.inMilliseconds}ms'),
            ],
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
