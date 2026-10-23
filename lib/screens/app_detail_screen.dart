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
import 'package:truehub/screens/app_detail/open_link.dart';
import 'package:truehub/services/url_opener.dart';

class AppDetailScreen extends StatefulWidget {
  final App app;
  final UrlOpener urlOpener;

  const AppDetailScreen({
    super.key,
    required this.app,
    this.urlOpener = const UrlLauncherOpener(),
  });

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> {
  final _sourcesKey = GlobalKey();

  App _resolveApp(AppProvider provider) {
    for (final app in provider.apps) {
      if (app.name == widget.app.name) return app;
    }
    return widget.app;
  }

  @override
  Widget build(BuildContext context) {
    final app = _resolveApp(context.watch<AppProvider>());
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(app.effectiveDisplayName),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppDetailHeader(app: app),
              const SizedBox(height: 24),
              if (app.screenshots.isNotEmpty) ...[
                AppScreenshotsSection(screenshots: app.screenshots),
                const SizedBox(height: 24),
              ],
              AppDescriptionSection(app: app),
              const SizedBox(height: 24),
              AppMetadataSection(app: app),
              const SizedBox(height: 24),
              if (app.maintainers.isNotEmpty) ...[
                AppMaintainersSection(maintainers: app.maintainers),
                const SizedBox(height: 24),
              ],
              if (app.sources.isNotEmpty) ...[
                AppSourcesSection(
                  key: _sourcesKey,
                  sources: app.sources,
                  urlOpener: widget.urlOpener,
                ),
                const SizedBox(height: 24),
              ],
              AppDetailActions(app: app, urlOpener: widget.urlOpener),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollToSources() {
    final sourcesContext = _sourcesKey.currentContext;
    if (sourcesContext == null) return;
    Scrollable.ensureVisible(
      sourcesContext,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _showAppActions() {
    final appProvider = context.read<AppProvider>();
    final app = _resolveApp(appProvider);
    final appConfig = appProvider.getAppConfig(app.name);

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(app.effectiveDisplayName),
        actions: [
          // Edit Configuration for installed apps
          if (app.installed)
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
              appProvider.isAppFavorite(app.name)
                  ? 'Remove from Favorites'
                  : 'Add to Favorites',
            ),
            onPressed: () {
              Navigator.pop(context);
              _toggleFavorite(appProvider);
            },
          ),
          if (app.home != null && app.home!.isNotEmpty)
            CupertinoActionSheetAction(
              child: const Text('View Homepage'),
              onPressed: () {
                Navigator.pop(context);
                openLinkOrAlert(this.context, widget.urlOpener, app.home!);
              },
            ),
          if (app.sources.isNotEmpty)
            CupertinoActionSheetAction(
              child: const Text('View Sources'),
              onPressed: () {
                Navigator.pop(context);
                _scrollToSources();
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
