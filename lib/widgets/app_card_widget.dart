import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/providers/app_provider.dart';
import 'package:truehub/widgets/app_icon.dart';
import 'package:truehub/screens/app_detail_screen.dart';
import 'package:truehub/widgets/app_card/app_health_error.dart';
import 'package:truehub/widgets/app_card/app_ports_panel.dart';
import 'package:truehub/widgets/app_card/app_resource_usage_panel.dart';
import 'package:truehub/widgets/app_card/app_upgrade_banner.dart';

class AppCardWidget extends StatelessWidget {
  final App app;

  const AppCardWidget({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) => AppDetailScreen(app: app)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                AppIcon(app: app, size: 50),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.effectiveDisplayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        app.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGrey.resolveFrom(
                            context,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (app.installed) ...[
                  _FavoriteToggle(appName: app.name),
                  const SizedBox(width: 8),
                ],
                _StatusBadge(installed: app.installed),
              ],
            ),
            if (app.categories.isNotEmpty ||
                app.latestAppVersion.isNotEmpty) ...[
              const SizedBox(height: 12),
              _AppMetadataRow(app: app),
            ],
            if (app.installed && app.resourceUsage != null) ...[
              const SizedBox(height: 12),
              AppResourceUsagePanel(usage: app.resourceUsage!),
            ],
            if (app.installed &&
                app.upgradeInfo != null &&
                app.upgradeInfo!.upgradeAvailable) ...[
              const SizedBox(height: 8),
              AppUpgradeBanner(app: app),
            ],
            if (app.installed &&
                (app.primaryCustomUrl != null || app.usedPorts.isNotEmpty)) ...[
              const SizedBox(height: 8),
              AppPortsPanel(app: app),
            ],
            if (app.installed && !app.healthy && app.healthyError != null) ...[
              const SizedBox(height: 8),
              AppHealthError(message: app.healthyError!),
            ],
          ],
        ),
      ),
    );
  }
}

class _FavoriteToggle extends StatelessWidget {
  final String appName;

  const _FavoriteToggle({required this.appName});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final isFavorite = appProvider.isAppFavorite(appName);
        return GestureDetector(
          onTap: () async {
            await appProvider.setAppFavorite(appName, !isFavorite);
          },
          child: Icon(
            isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
            color: isFavorite
                ? CupertinoColors.systemRed
                : CupertinoColors.systemGrey.resolveFrom(context),
            size: 20,
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool installed;

  const _StatusBadge({required this.installed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: installed
            ? CupertinoColors.systemGreen.withValues(alpha: 0.1)
            : CupertinoColors.systemBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        installed ? 'Installed' : 'Available',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: installed
              ? CupertinoColors.systemGreen
              : CupertinoColors.systemBlue,
        ),
      ),
    );
  }
}

class _AppMetadataRow extends StatelessWidget {
  final App app;

  const _AppMetadataRow({required this.app});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (app.categories.isNotEmpty) ...[
          Icon(
            CupertinoIcons.tag,
            size: 14,
            color: CupertinoColors.systemGrey2.resolveFrom(context),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              app.categories.take(2).join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey2.resolveFrom(context),
              ),
            ),
          ),
        ],
        const Spacer(),
        if (app.latestAppVersion.isNotEmpty) ...[
          Text(
            'v${app.latestAppVersion}',
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey2.resolveFrom(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
