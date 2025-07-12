import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:truenas_manager/models/app.dart';
import 'package:truenas_manager/providers/app_provider.dart';
import 'package:truenas_manager/widgets/app_icon.dart';
import 'package:truenas_manager/screens/app_detail_screen.dart';

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
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CupertinoColors.separator, width: 0.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // App icon with network image support
                AppIcon(app: app, size: 50),
                const SizedBox(width: 16),
                // App info
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
                        style: const TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemGrey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Favorite toggle for installed apps
                if (app.installed) ...[
                  Consumer<AppProvider>(
                    builder: (context, appProvider, child) {
                      final isFavorite = appProvider.isAppFavorite(app.name);
                      return GestureDetector(
                        onTap: () async {
                          await appProvider.setAppFavorite(
                            app.name,
                            !isFavorite,
                          );
                        },
                        child: Icon(
                          isFavorite
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          color: isFavorite
                              ? CupertinoColors.systemRed
                              : CupertinoColors.systemGrey,
                          size: 20,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: app.installed
                        ? CupertinoColors.systemGreen.withOpacity(0.1)
                        : CupertinoColors.systemBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    app.installed ? 'Installed' : 'Available',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: app.installed
                          ? CupertinoColors.systemGreen
                          : CupertinoColors.systemBlue,
                    ),
                  ),
                ),
              ],
            ),
            // App metadata
            if (app.categories.isNotEmpty ||
                app.latestAppVersion.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (app.categories.isNotEmpty) ...[
                    Icon(
                      CupertinoIcons.tag,
                      size: 14,
                      color: CupertinoColors.systemGrey2,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      app.categories.take(2).join(', '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey2,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (app.latestAppVersion.isNotEmpty) ...[
                    Text(
                      'v${app.latestAppVersion}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            // Real-time resource usage for installed apps
            if (app.installed && app.resourceUsage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // CPU and Memory usage row
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.speedometer,
                          size: 14,
                          color: CupertinoColors.systemBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'CPU: ${app.resourceUsage!.cpuUsage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.label,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          CupertinoIcons.memories,
                          size: 14,
                          color: CupertinoColors.systemGreen,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Memory: ${_formatBytes(app.resourceUsage!.memoryUsage)}${app.resourceUsage!.memoryLimit > 0 ? ' / ${_formatBytes(app.resourceUsage!.memoryLimit * 1024 * 1024)}' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.label,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Network usage row
                    if (app.resourceUsage!.networkRxBytes > 0 ||
                        app.resourceUsage!.networkTxBytes > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            CupertinoIcons.arrow_down_circle,
                            size: 14,
                            color: CupertinoColors.systemOrange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'RX: ${_formatBytes(app.resourceUsage!.networkRxBytes.toInt())}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.label,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            CupertinoIcons.arrow_up_circle,
                            size: 14,
                            color: CupertinoColors.systemOrange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'TX: ${_formatBytes(app.resourceUsage!.networkTxBytes.toInt())}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.label,
                            ),
                          ),
                          const Spacer(),
                          if (app.resourceUsage!.lastUpdated != null) ...[
                            Text(
                              _formatLastUpdated(
                                app.resourceUsage!.lastUpdated!,
                              ),
                              style: const TextStyle(
                                fontSize: 10,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
            // Upgrade info for installed apps
            if (app.installed &&
                app.upgradeInfo != null &&
                app.upgradeInfo!.upgradeAvailable) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.arrow_up_circle_fill,
                      size: 14,
                      color: CupertinoColors.systemYellow,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Update available: ${app.upgradeInfo!.availableVersion ?? 'Latest'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.label,
                        ),
                      ),
                    ),
                    if (app.upgradeInfo!.canUpgrade) ...[
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: const Text(
                          'Upgrade',
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.systemYellow,
                          ),
                        ),
                        onPressed: () => _showUpgradeDialog(context, app),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            // Port information for installed apps
            if (app.installed &&
                (app.primaryCustomUrl != null || app.usedPorts.isNotEmpty)) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue.withOpacity(0.1),
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
                        const Text(
                          'Ports & Access',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.label,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Custom URL (prioritized)
                    if (app.primaryCustomUrl != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGreen.withOpacity(0.1),
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
                    // Port information
                    for (final port in app.usedPorts) ...[
                      Row(
                        children: [
                          const SizedBox(width: 22),
                          Text(
                            'Port ${port.containerPort} (${port.protocol.toUpperCase()})',
                            style: const TextStyle(
                              fontSize: 11,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                          const Spacer(),
                          if (port.hostPorts.isNotEmpty) ...[
                            Text(
                              'Host: ${port.hostPorts.first.hostPort}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    // Portal links
                    if (app.portals.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        height: 1,
                        color: CupertinoColors.separator,
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
              ),
            ],
            // Health error for installed apps
            if (app.installed && !app.healthy && app.healthyError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_triangle_fill,
                      size: 14,
                      color: CupertinoColors.systemRed,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        app.healthyError!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemRed,
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

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }

  String _formatLastUpdated(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  void _openPortal(String portalUrl) async {
    try {
      final url = Uri.parse(portalUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Silently handle URL launch errors
    }
  }

  void _showUpgradeDialog(BuildContext context, App app) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Upgrade ${app.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Current version: ${app.upgradeInfo?.currentVersion ?? 'Unknown'}',
            ),
            const SizedBox(height: 8),
            Text(
              'Available version: ${app.upgradeInfo?.availableVersion ?? 'Latest'}',
            ),
            if (app.upgradeInfo?.upgradeNotes != null) ...[
              const SizedBox(height: 16),
              Text(
                'Release notes:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                app.upgradeInfo!.upgradeNotes!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => _performUpgrade(context, app),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  void _performUpgrade(BuildContext context, App app) async {
    Navigator.of(context).pop();

    if (!context.mounted) return;

    // Show loading indicator
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CupertinoAlertDialog(
        title: Text('Upgrading...'),
        content: Padding(
          padding: EdgeInsets.all(16.0),
          child: CupertinoActivityIndicator(),
        ),
      ),
    );

    try {
      final appProvider = context.read<AppProvider>();
      final success = await appProvider.upgradeApp(app.name);

      if (!context.mounted) return;
      Navigator.of(context).pop();

      if (success) {
        if (!context.mounted) return;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: Text('${app.title} has been upgraded successfully.'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        if (!context.mounted) return;
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to upgrade ${app.title}. Please try again.'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      if (!context.mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('An error occurred while upgrading ${app.title}: $e'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
