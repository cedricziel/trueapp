import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/app_provider.dart';
import 'package:truehub/widgets/app_card_widget.dart';
import 'package:truehub/widgets/empty_state_widget.dart';
import 'package:truehub/widgets/error_state_widget.dart';
import 'package:truehub/widgets/loading_state_widget.dart';
import 'package:truehub/widgets/section_header.dart';

class ServerAppsSection extends StatelessWidget {
  final NasServer server;

  const ServerAppsSection({super.key, required this.server});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Apps',
                action: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    context.push('/server/${server.id}/apps', extra: server);
                  },
                  child: const Text('View All'),
                ),
              ),
              const SizedBox(height: 12),
              if (appProvider.isLoading)
                const LoadingStateWidget(message: 'Loading apps...')
              else if (appProvider.error != null)
                ErrorStateWidget(
                  title: 'App Error',
                  message: appProvider.errorDetails == null
                      ? 'Failed to load apps: ${appProvider.error}'
                      : 'Failed to load apps: ${appProvider.error}\n'
                            '${appProvider.errorDetails}',
                )
              else if (appProvider.apps.isEmpty)
                const EmptyStateWidget(
                  icon: CupertinoIcons.app,
                  title: 'No Apps',
                  message: 'No apps found',
                )
              else
                Column(
                  children: [
                    _AppsSummaryCard(apps: appProvider.apps, server: server),
                    const SizedBox(height: 16),
                    if (appProvider.favoriteApps.isNotEmpty) ...[
                      const _FavoriteAppsHeader(),
                      ...appProvider.favoriteApps.take(3).map((appConfig) {
                        try {
                          final app = appProvider.apps.firstWhere(
                            (app) => app.name == appConfig.appName,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AppCardWidget(app: app),
                          );
                        } catch (e) {
                          return const SizedBox.shrink();
                        }
                      }),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FavoriteAppsHeader extends StatelessWidget {
  const _FavoriteAppsHeader();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.heart_fill,
              color: CupertinoColors.systemRed,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              'Favorite Apps',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.systemGrey.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppsSummaryCard extends StatelessWidget {
  final List<App> apps;
  final NasServer server;

  const _AppsSummaryCard({required this.apps, required this.server});

  @override
  Widget build(BuildContext context) {
    final installedApps = apps.where((app) => app.installed).toList();
    final availableApps = apps.where((app) => !app.installed).toList();
    final appsWithUpdates = installedApps
        .where(
          (app) => app.upgradeInfo != null && app.upgradeInfo!.upgradeAvailable,
        )
        .toList();

    return GestureDetector(
      onTap: () {
        context.push('/server/${server.id}/apps', extra: server);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  CupertinoIcons.app_badge,
                  size: 24,
                  color: CupertinoColors.systemBlue,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Apps Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _AppStat(
                    icon: CupertinoIcons.checkmark_circle_fill,
                    color: CupertinoColors.systemGreen,
                    count: installedApps.length,
                    label: 'Installed',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _AppStat(
                    icon: CupertinoIcons.arrow_up_circle_fill,
                    color: appsWithUpdates.isNotEmpty
                        ? CupertinoColors.systemYellow
                        : CupertinoColors.systemGrey.resolveFrom(context),
                    count: appsWithUpdates.length,
                    label: 'Updates',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _AppStat(
                    icon: CupertinoIcons.square_grid_2x2,
                    color: CupertinoColors.systemBlue,
                    count: availableApps.length,
                    label: 'Available',
                  ),
                ),
              ],
            ),
            if (appsWithUpdates.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle,
                      size: 14,
                      color: CupertinoColors.systemYellow,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${appsWithUpdates.length} app${appsWithUpdates.length == 1 ? '' : 's'} ${appsWithUpdates.length == 1 ? 'has' : 'have'} updates available',
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int count;
  final String label;

  const _AppStat({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: CupertinoColors.systemGrey.resolveFrom(context),
          ),
        ),
      ],
    );
  }
}
