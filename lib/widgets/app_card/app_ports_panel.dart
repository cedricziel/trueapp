import 'package:flutter/cupertino.dart';
import 'package:truehub/models/app.dart';
import 'package:url_launcher/url_launcher.dart';

class AppPortsPanel extends StatelessWidget {
  final App app;

  const AppPortsPanel({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.globe,
                size: 14,
                color: CupertinoColors.systemBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Ports & Access',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (app.primaryCustomUrl != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.star_fill,
                    size: 12,
                    color: CupertinoColors.systemGreen,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Custom URL: ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.systemGreen,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openPortal(app.primaryCustomUrl!),
                      child: Text(
                        app.primaryCustomUrl!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.systemGreen,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
          for (final port in app.usedPorts) ...[
            Row(
              children: [
                const SizedBox(width: 22),
                Text(
                  'Port ${port.containerPort} (${port.protocol.toUpperCase()})',
                  style: TextStyle(
                    fontSize: 11,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
                const Spacer(),
                if (port.hostPorts.isNotEmpty) ...[
                  Text(
                    'Host: ${port.hostPorts.first.hostPort}',
                    style: TextStyle(
                      fontSize: 11,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (app.portals.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              height: 1,
              color: CupertinoColors.separator.resolveFrom(context),
              margin: const EdgeInsets.symmetric(vertical: 4),
            ),
            for (final portal in app.portals.entries) ...[
              Row(
                children: [
                  const SizedBox(width: 22),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openPortal(portal.value),
                      child: Text(
                        '${portal.key}: ${portal.value}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.systemBlue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  static void _openPortal(String portalUrl) async {
    try {
      final url = Uri.parse(portalUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Silently handle URL launch errors
    }
  }
}
