import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/models/app_config.dart';
import 'package:truehub/providers/app_provider.dart';
import 'package:truehub/screens/app_configuration_screen.dart';
import 'package:truehub/screens/app_detail/app_description_section.dart';
import 'package:truehub/screens/app_detail/app_detail_actions.dart';
import 'package:truehub/screens/app_detail/app_detail_header.dart';
import 'package:truehub/screens/app_detail/app_maintainers_section.dart';
import 'package:truehub/screens/app_detail/app_metadata_section.dart';
import 'package:truehub/screens/app_detail/app_screenshots_section.dart';
import 'package:truehub/screens/app_detail/app_sources_section.dart';

class AppDetailScreen extends StatefulWidget {
  final App app;

  const AppDetailScreen({super.key, required this.app});

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.app.effectiveDisplayName),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.ellipsis),
          onPressed: () => _showAppActions(),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppDetailHeader(app: widget.app),
            const SizedBox(height: 24),
            if (widget.app.screenshots.isNotEmpty) ...[
              AppScreenshotsSection(screenshots: widget.app.screenshots),
              const SizedBox(height: 24),
            ],
            AppDescriptionSection(app: widget.app),
            const SizedBox(height: 24),
            AppMetadataSection(app: widget.app),
            const SizedBox(height: 24),
            if (widget.app.maintainers.isNotEmpty) ...[
              AppMaintainersSection(maintainers: widget.app.maintainers),
              const SizedBox(height: 24),
            ],
            if (widget.app.sources.isNotEmpty) ...[
              AppSourcesSection(sources: widget.app.sources),
              const SizedBox(height: 24),
            ],
            AppDetailActions(app: widget.app),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showAppActions() {
    final appProvider = context.read<AppProvider>();
    final appConfig = appProvider.getAppConfig(widget.app.name);

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(widget.app.effectiveDisplayName),
        actions: [
          // Edit Configuration for installed apps
          if (widget.app.installed)
            CupertinoActionSheetAction(
              child: const Text('Edit Configuration'),
              onPressed: () {
                Navigator.pop(context);
                _navigateToAppConfiguration(appConfig);
              },
            ),
          // Toggle Favorite
          CupertinoActionSheetAction(
            child: Text(
              appProvider.isAppFavorite(widget.app.name)
                  ? 'Remove from Favorites'
                  : 'Add to Favorites',
            ),
            onPressed: () {
              Navigator.pop(context);
              _toggleFavorite(appProvider);
            },
          ),
          CupertinoActionSheetAction(
            child: Text(widget.app.installed ? 'Manage App' : 'Install App'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          if (widget.app.home != null && widget.app.home!.isNotEmpty)
            CupertinoActionSheetAction(
              child: const Text('View Homepage'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          if (widget.app.sources.isNotEmpty)
            CupertinoActionSheetAction(
              child: const Text('View Sources'),
              onPressed: () {
                Navigator.pop(context);
                // Scroll to sources section
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

  void _navigateToAppConfiguration(AppConfig? appConfig) {
    if (appConfig != null) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => AppConfigurationScreen(appConfig: appConfig),
        ),
      );
    } else {
      // Show error or create new config
      _showError(
        'App configuration not found. Please try refreshing the app list.',
      );
    }
  }

  void _toggleFavorite(AppProvider appProvider) {
    final isFavorite = appProvider.isAppFavorite(widget.app.name);
    appProvider.setAppFavorite(widget.app.name, !isFavorite);
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
