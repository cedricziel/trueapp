import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/models/app.dart';
import 'package:truenas_manager/providers/app_provider.dart';

class ServerAppsScreen extends StatefulWidget {
  final NasServer server;

  const ServerAppsScreen({super.key, required this.server});

  @override
  State<ServerAppsScreen> createState() => _ServerAppsScreenState();
}

class _ServerAppsScreenState extends State<ServerAppsScreen> {
  int _selectedSegment = 0; // 0 = Installed, 1 = Available
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = context.read<AppProvider>();
      appProvider.setApiClient(widget.server);
      appProvider.loadApps();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Apps'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.refresh),
          onPressed: () {
            context.read<AppProvider>().refreshApps();
          },
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Search bar
            Container(
              margin: const EdgeInsets.all(16),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Search apps...',
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            // Segmented control
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: CupertinoSegmentedControl<int>(
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Installed'),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Available'),
                  ),
                },
                onValueChanged: (value) {
                  setState(() {
                    _selectedSegment = value;
                  });
                },
                groupValue: _selectedSegment,
              ),
            ),
            const SizedBox(height: 16),
            // Apps list
            Expanded(
              child: Consumer<AppProvider>(
                builder: (context, appProvider, child) {
                  if (appProvider.isLoading) {
                    return const Center(child: CupertinoActivityIndicator());
                  }

                  if (appProvider.error != null) {
                    return _buildErrorView(appProvider.error!);
                  }

                  final apps = _getFilteredApps(appProvider);

                  if (apps.isEmpty) {
                    return _buildEmptyView();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildAppCard(apps[index]),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<App> _getFilteredApps(AppProvider appProvider) {
    List<App> apps;

    if (_selectedSegment == 0) {
      apps = appProvider.installedApps;
    } else {
      apps = appProvider.availableApps;
    }

    if (_searchQuery.isNotEmpty) {
      apps = apps.where((app) {
        return app.title.toLowerCase().contains(_searchQuery) ||
            app.description.toLowerCase().contains(_searchQuery) ||
            app.categories.any(
              (category) => category.toLowerCase().contains(_searchQuery),
            ) ||
            app.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
      }).toList();
    }

    return apps;
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 48,
              color: CupertinoColors.systemRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load apps',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              child: const Text('Retry'),
              onPressed: () {
                context.read<AppProvider>().refreshApps();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    final isInstalled = _selectedSegment == 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isInstalled ? CupertinoIcons.app_badge : CupertinoIcons.app,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              isInstalled ? 'No installed apps' : 'No available apps',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No apps match your search'
                  : isInstalled
                  ? 'Install apps to see them here'
                  : 'Check your connection or try again later',
              style: const TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppCard(App app) {
    return GestureDetector(
      onTap: () {
        _showAppDetails(app);
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
                // App icon placeholder or status indicator
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: app.installed
                        ? (app.healthy
                              ? CupertinoColors.systemGreen.withOpacity(0.1)
                              : CupertinoColors.systemRed.withOpacity(0.1))
                        : CupertinoColors.systemBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    app.installed
                        ? (app.healthy
                              ? CupertinoIcons.checkmark_circle
                              : CupertinoIcons.exclamationmark_circle)
                        : CupertinoIcons.app,
                    color: app.installed
                        ? (app.healthy
                              ? CupertinoColors.systemGreen
                              : CupertinoColors.systemRed)
                        : CupertinoColors.systemBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // App info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.title,
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
            // Health error for installed apps
            if (app.installed && !app.healthy && app.healthyError != null) ...[
              const SizedBox(height: 12),
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

  void _showAppDetails(App app) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(app.title),
        message: Text(app.description),
        actions: [
          if (app.home != null)
            CupertinoActionSheetAction(
              child: const Text('View Homepage'),
              onPressed: () {
                Navigator.pop(context);
                if (kDebugMode) {
                  print('Open homepage: ${app.home}');
                }
                // TODO: Open URL in browser
              },
            ),
          CupertinoActionSheetAction(
            child: Text(app.installed ? 'Manage App' : 'Install App'),
            onPressed: () {
              Navigator.pop(context);
              if (kDebugMode) {
                print(
                  '${app.installed ? 'Manage' : 'Install'} app: ${app.name}',
                );
              }
              // TODO: Navigate to app management or installation
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
  }
}
