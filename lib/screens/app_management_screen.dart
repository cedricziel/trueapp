import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/models/app_config.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/providers/app_config_provider.dart';
import 'package:truenas_manager/providers/app_provider.dart';
import 'package:truenas_manager/screens/app_configuration_screen.dart';
import 'package:truenas_manager/widgets/error_state_widget.dart';
import 'package:truenas_manager/widgets/empty_state_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class AppManagementScreen extends StatefulWidget {
  final NasServer server;
  
  const AppManagementScreen({super.key, required this.server});

  @override
  State<AppManagementScreen> createState() => _AppManagementScreenState();
}

class _AppManagementScreenState extends State<AppManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final configProvider = context.read<AppConfigProvider>();
      await configProvider.setServer(widget.server.id);
      await _syncAppConfigs();
    });
  }

  Future<void> _syncAppConfigs() async {
    final appProvider = context.read<AppProvider>();
    final configProvider = context.read<AppConfigProvider>();

    if (appProvider.installedApps.isNotEmpty) {
      await configProvider.syncFromInstalledApps(appProvider.installedApps);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('App Management'),
      ),
      child: SafeArea(
        child: Consumer2<AppProvider, AppConfigProvider>(
          builder: (context, appProvider, configProvider, child) {
            if (appProvider.isLoading || configProvider.isLoading) {
              return const Center(child: CupertinoActivityIndicator());
            }

            if (appProvider.connectionError != null) {
              return ErrorStateWidget(
                title: 'Connection Error',
                message: appProvider.connectionError!.shortMessage,
                onRetry: () => appProvider.loadApps(),
              );
            }

            if (appProvider.installedApps.isEmpty) {
              return const EmptyStateWidget(
                icon: CupertinoIcons.app,
                title: 'No Apps Installed',
                message:
                    'Install some apps on your TrueNAS server to configure them here.',
              );
            }

            return RefreshBox(
              onRefresh: () async {
                await appProvider.refreshApps();
                await _syncAppConfigs();
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: appProvider.installedApps.map((app) {
                    final config = configProvider.getAppConfig(app.name);
                    return _AppConfigCard(
                      app: app,
                      config: config,
                      onTap: () => _navigateToConfiguration(config, app),
                      onOpenUrl: (url) => _openUrl(url),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateToConfiguration(AppConfig? config, dynamic app) {
    if (config != null) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => AppConfigurationScreen(appConfig: config),
        ),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _AppConfigCard extends StatelessWidget {
  final dynamic app;
  final AppConfig? config;
  final VoidCallback onTap;
  final Function(String) onOpenUrl;

  const _AppConfigCard({
    required this.app,
    required this.config,
    required this.onTap,
    required this.onOpenUrl,
  });

  @override
  Widget build(BuildContext context) {
    final hasConfig = config != null;
    final primaryUrl = config?.primaryPort?.effectiveUrl;
    final enabledPorts = config?.enabledPorts ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator.resolveFrom(context),
          width: 0.5,
        ),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5.resolveFrom(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.app,
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          config?.effectiveDisplayName ?? app.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          app.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasConfig && config!.isEnabled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Configured',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    size: 16,
                    color: CupertinoColors.systemGrey,
                  ),
                ],
              ),
              if (hasConfig && enabledPorts.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(height: 0.5, color: CupertinoColors.separator),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (primaryUrl != null) ...[
                      Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          color: CupertinoColors.systemBlue,
                          borderRadius: BorderRadius.circular(8),
                          onPressed: () => onOpenUrl(primaryUrl),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                CupertinoIcons.link,
                                size: 16,
                                color: CupertinoColors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                config!.primaryPort?.displayName ?? 'Primary',
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (enabledPorts.length > 1) ...[
                        const SizedBox(width: 8),
                        CupertinoButton(
                          padding: const EdgeInsets.all(6),
                          color: CupertinoColors.systemGrey4,
                          borderRadius: BorderRadius.circular(8),
                          onPressed: () => _showPortMenu(context, enabledPorts),
                          child: Text(
                            '+${enabledPorts.length - 1}',
                            style: const TextStyle(
                              color: CupertinoColors.label,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ] else if (enabledPorts.isNotEmpty) ...[
                      Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          color: CupertinoColors.systemBlue,
                          borderRadius: BorderRadius.circular(8),
                          onPressed: () =>
                              onOpenUrl(enabledPorts.first.effectiveUrl),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                CupertinoIcons.link,
                                size: 16,
                                color: CupertinoColors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                enabledPorts.first.displayName,
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showPortMenu(BuildContext context, List<AppPortConfig> ports) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Choose Port'),
        actions: ports
            .map(
              (port) => CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(context).pop();
                  onOpenUrl(port.effectiveUrl);
                },
                child: Column(
                  children: [
                    Text(port.displayName),
                    Text(
                      port.effectiveUrl,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

class RefreshBox extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const RefreshBox({super.key, required this.child, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: onRefresh),
        SliverToBoxAdapter(child: child),
      ],
    );
  }
}
