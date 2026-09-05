import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/models/connection_error.dart';
import 'package:truehub/providers/app_provider.dart';
import 'package:truehub/widgets/app_card_widget.dart';
import 'package:truehub/widgets/empty_state_widget.dart';
import 'package:truehub/widgets/error_state_widget.dart';
import 'package:truehub/widgets/jobs_bell_button.dart';
import 'package:truehub/widgets/loading_state_widget.dart';

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
      await appProvider.setApiClient(widget.server);
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
            JobsBellButton(server: widget.server),
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
              child: Consumer<AppProvider>(
                builder: (context, appProvider, child) {
                  if (appProvider.isLoading) {
                    return const LoadingStateWidget(message: 'Loading apps...');
                  }

                  if (appProvider.error != null) {
                    return _buildErrorView(
                      title: 'Failed to load apps',
                      error: appProvider.error!,
                      details: appProvider.errorDetails,
                    );
                  }

                  final apps = _getFilteredApps(appProvider);
                  final catalogError = _selectedSegment == 1
                      ? appProvider.catalogError
                      : null;

                  if (apps.isEmpty) {
                    if (catalogError != null) {
                      return _buildErrorView(
                        title: 'Failed to load app catalog',
                        error: catalogError.shortMessage,
                        details: catalogError.technicalDetails,
                      );
                    }
                    return _buildEmptyView();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: apps.length + (catalogError != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (catalogError != null) {
                        if (index == 0) {
                          return _buildCatalogNotice(catalogError);
                        }
                        index -= 1;
                      }
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
        apps = appProvider.apps.where((app) => app.installed).toList();
        break;
      case 1: // Available
        apps = appProvider.apps.where((app) => !app.installed).toList();
        break;
      case 2: // Favorites
        apps = appProvider.apps
            .where((app) => appProvider.isAppFavorite(app.name))
            .toList();
        break;
      case 3: // Updates Available
        apps = appProvider.apps
            .where((app) => app.upgradeInfo?.upgradeAvailable == true)
            .toList();
        break;
      default:
        apps = appProvider.apps.where((app) => app.installed).toList();
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

  Widget _buildErrorView({
    required String title,
    required String error,
    String? details,
  }) {
    return ErrorStateWidget(
      title: title,
      message: details == null ? error : '$error\n$details',
      onRetry: () {
        context.read<AppProvider>().refreshApps();
      },
    );
  }

  /// Shown above a stale catalog list when the catalog could not be
  /// refreshed this time, so the user knows the entries may be outdated
  /// without losing them.
  Widget _buildCatalogNotice(ConnectionError catalogError) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CupertinoColors.systemYellow.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Catalog could not be refreshed: ${catalogError.shortMessage}. '
          'Showing the last synced apps.',
          style: const TextStyle(fontSize: 13),
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

    return EmptyStateWidget(
      icon: icon,
      title: title,
      message: _searchQuery.isNotEmpty ? 'No apps match your search' : subtitle,
    );
  }
}
