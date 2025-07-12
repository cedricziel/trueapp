import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/models/app.dart';
import 'package:truenas_manager/providers/app_provider.dart';
import 'package:truenas_manager/providers/app_config_provider.dart';
import 'package:truenas_manager/widgets/app_card_widget.dart';
import 'package:truenas_manager/screens/app_management_screen.dart';

class ServerAppsScreen extends StatefulWidget {
  final NasServer server;

  const ServerAppsScreen({super.key, required this.server});

  @override
  State<ServerAppsScreen> createState() => _ServerAppsScreenState();
}

class _ServerAppsScreenState extends State<ServerAppsScreen> {
  int _selectedSegment =
      0; // 0 = Installed, 1 = Available, 2 = Favorites, 3 = Updates Available
  String _searchQuery = '';
  bool _sortByName = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appProvider = context.read<AppProvider>();
      final appConfigProvider = context.read<AppConfigProvider>();
      await appProvider.setApiClient(widget.server);
      appProvider.setAppConfigProvider(appConfigProvider);
      await appConfigProvider.setServer(widget.server.id);
      await appProvider.loadApps();
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) =>
                        AppManagementScreen(server: widget.server),
                  ),
                );
              },
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.refresh),
              onPressed: () {
                context.read<AppProvider>().refreshApps();
              },
            ),
          ],
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
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text('Installed'),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text('Available'),
                  ),
                  2: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text('Favorites'),
                  ),
                  3: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text('Updates'),
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
            // Sort and filter controls
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    color: _sortByName
                        ? CupertinoColors.systemBlue
                        : CupertinoColors.systemGrey4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.sort_down,
                          size: 16,
                          color: _sortByName
                              ? CupertinoColors.white
                              : CupertinoColors.systemGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Sort by Name',
                          style: TextStyle(
                            fontSize: 14,
                            color: _sortByName
                                ? CupertinoColors.white
                                : CupertinoColors.systemGrey,
                          ),
                        ),
                      ],
                    ),
                    onPressed: () {
                      setState(() {
                        _sortByName = !_sortByName;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Apps list
            Expanded(
              child: Consumer2<AppProvider, AppConfigProvider>(
                builder: (context, appProvider, appConfigProvider, child) {
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
                        child: AppCardWidget(app: apps[index]),
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

    switch (_selectedSegment) {
      case 0: // Installed
        apps = appProvider.installedApps;
        break;
      case 1: // Available
        apps = appProvider.availableApps;
        break;
      case 2: // Favorites
        final appConfigProvider = context.read<AppConfigProvider>();
        final favoriteAppNames = appConfigProvider.favoriteAppConfigs
            .map((config) => config.appName)
            .toSet();
        apps = appProvider.apps
            .where((app) => favoriteAppNames.contains(app.name))
            .toList();
        break;
      case 3: // Updates Available
        apps = appProvider.installedApps
            .where((app) => app.upgradeInfo?.upgradeAvailable == true)
            .toList();
        break;
      default:
        apps = appProvider.installedApps;
    }

    // Apply search filter
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

    // Apply sorting
    if (_sortByName) {
      apps.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
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
    String title;
    String subtitle;
    IconData icon;

    switch (_selectedSegment) {
      case 0: // Installed
        title = 'No installed apps';
        subtitle = 'Install apps from the Available tab to see them here.';
        icon = CupertinoIcons.app_badge;
        break;
      case 1: // Available
        title = 'No available apps';
        subtitle = 'Check your connection and try refreshing.';
        icon = CupertinoIcons.app;
        break;
      case 2: // Favorites
        title = 'No favorite apps';
        subtitle = 'Mark apps as favorites to see them here.';
        icon = CupertinoIcons.heart;
        break;
      case 3: // Updates Available
        title = 'No updates available';
        subtitle = 'All your apps are up to date!';
        icon = CupertinoIcons.arrow_up_circle;
        break;
      default:
        title = 'No apps found';
        subtitle = 'Try adjusting your search or filters.';
        icon = CupertinoIcons.app;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: CupertinoColors.systemGrey),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty ? 'No apps match your search' : subtitle,
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
}
