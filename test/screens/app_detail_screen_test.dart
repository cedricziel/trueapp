import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/models/app_config.dart';
import 'package:truehub/providers/app_provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/screens/app_configuration_screen.dart';
import 'package:truehub/screens/app_detail_screen.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/layout_assertions.dart';
import '../helpers/provider_scope.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';
import '../helpers/test_surfaces.dart';

/// An [AppProvider] whose config/favorite state a test drives directly,
/// mirroring the `_FakeAppProvider` seam already used in
/// `test/widgets/app_card_widget_test.dart` and
/// `test/screens/server_detail_screen_test.dart` - `AppDetailScreen` only
/// reads `AppProvider` from its overflow menu (`_showAppActions`), never in
/// `build`, so a fake that answers `getAppConfig`/`isAppFavorite` directly
/// avoids routing every test through a real drift database write.
class _FakeAppProvider extends AppProvider {
  _FakeAppProvider({
    required super.database,
    required super.serverService,
    AppConfig? config,
    bool favorite = false,
  }) : _config = config,
       _favorite = favorite;

  final AppConfig? _config;
  bool _favorite;
  int toggleCallCount = 0;
  String? lastToggledAppName;
  bool? lastToggledValue;

  @override
  AppConfig? getAppConfig(String appName) => _config;

  @override
  bool isAppFavorite(String appName) => _favorite;

  @override
  Future<void> setAppFavorite(String appName, bool isFavorite) async {
    toggleCallCount++;
    lastToggledAppName = appName;
    lastToggledValue = isFavorite;
    _favorite = isFavorite;
    notifyListeners();
  }
}

App _buildApp({
  String name = 'plex',
  String title = 'Plex Media Server',
  String description = 'Media server for movies, TV shows and music.',
  bool installed = false,
  bool healthy = true,
  String? healthyError,
  String latestVersion = '1.0.0',
  String latestAppVersion = '1.0.0',
  String latestHumanVersion = '1.0.0',
  List<String> categories = const [],
  String? home,
  List<String> tags = const [],
  List<String> screenshots = const [],
  List<String> sources = const [],
  String? appReadme,
  List<AppMaintainer> maintainers = const [],
  DateTime? lastUpdate,
  bool recommended = false,
  String catalog = 'community',
  String train = 'stable',
}) {
  return App(
    name: name,
    title: title,
    description: description,
    installed: installed,
    healthy: healthy,
    healthyError: healthyError,
    latestVersion: latestVersion,
    latestAppVersion: latestAppVersion,
    latestHumanVersion: latestHumanVersion,
    categories: categories,
    home: home,
    tags: tags,
    screenshots: screenshots,
    sources: sources,
    appReadme: appReadme,
    maintainers: maintainers,
    lastUpdate: lastUpdate,
    recommended: recommended,
    catalog: catalog,
    train: train,
    usedPorts: const [],
    portals: const {},
  );
}

/// Taps the ellipsis button and settles the modal popup's entry animation.
///
/// A single `pump()` after the tap leaves `CupertinoActionSheet` mid-slide,
/// so its actions can sit below the test surface's bottom edge and fail a
/// hit test - `settleRouteTransition` gives the transition enough virtual
/// time to finish before a test taps anything inside the sheet.
Future<void> _openActionSheet(WidgetTester tester) async {
  await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
  await settleRouteTransition(tester);
}

void main() {
  late AppDatabase database;
  late UnifiedServerService unifiedServerService;
  late ServerProvider serverProvider;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();
    database = createTestDatabase();
    unifiedServerService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    serverProvider = ServerProvider(unifiedServerService);
  });

  tearDown(() async {
    await TestProviders.disposeTestStack(
      providers: [serverProvider],
      service: unifiedServerService,
      database: database,
    );
  });

  Widget wrap(App app, {_FakeAppProvider? appProvider}) {
    final fakeAppProvider =
        appProvider ??
        _FakeAppProvider(
          database: database,
          serverService: unifiedServerService,
        );
    addTearDown(fakeAppProvider.dispose);
    return provideAppProviders(
      database: database,
      service: unifiedServerService,
      serverProvider: serverProvider,
      appProvider: fakeAppProvider,
      child: CupertinoApp(home: AppDetailScreen(app: app)),
    );
  }

  group('AppDetailScreen - header', () {
    testWidgets('shows the human version when present', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(_buildApp(latestHumanVersion: '2.5.0', latestAppVersion: '9.9.9')),
      );
      expect(find.text('v2.5.0'), findsOneWidget);
    });

    testWidgets('falls back to the app version when human version is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(_buildApp(latestHumanVersion: '', latestAppVersion: '3.1.4')),
      );
      expect(find.text('v3.1.4'), findsOneWidget);
    });

    testWidgets('shows the green Installed badge when installed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp(installed: true)));
      expect(find.text('Installed'), findsOneWidget);
      final badge = tester.widget<Text>(find.text('Installed'));
      expect(badge.style?.color, CupertinoColors.systemGreen);
    });

    testWidgets('shows the blue Available badge when not installed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp(installed: false)));
      expect(find.text('Available'), findsOneWidget);
      final badge = tester.widget<Text>(find.text('Available'));
      expect(badge.style?.color, CupertinoColors.systemBlue);
    });

    testWidgets('shows the effective display name in the nav bar title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp(name: 'plex', title: 'Plex')));
      // Not installed -> effectiveDisplayName falls back to title.
      expect(find.text('Plex'), findsWidgets);
    });
  });

  group('AppDetailScreen - screenshots', () {
    testWidgets('renders no Screenshots section when there are none', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp(screenshots: const [])));
      expect(find.text('Screenshots'), findsNothing);
    });

    testWidgets('renders a single screenshot without a thumbnail strip', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(_buildApp(screenshots: const ['https://example.com/s1.png'])),
      );
      await tester.pump();
      expect(find.text('Screenshots'), findsOneWidget);
      // Only the main Image.network - no thumbnail ListView.separated.
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets(
      'renders a thumbnail strip for multiple screenshots and switches '
      'the selection on tap',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrap(
            _buildApp(
              screenshots: const [
                'https://example.com/s1.png',
                'https://example.com/s2.png',
                'https://example.com/s3.png',
              ],
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Screenshots'), findsOneWidget);
        // Main image + 3 thumbnails.
        expect(find.byType(Image), findsNWidgets(4));

        // Tap the second thumbnail's GestureDetector to change selection.
        final thumbnailGestures = find.descendant(
          of: find.byType(ListView),
          matching: find.byType(GestureDetector),
        );
        expect(thumbnailGestures, findsNWidgets(3));
        await tester.tap(thumbnailGestures.at(1));
        await tester.pump();
        expectNoLayoutOverflow(tester);
      },
    );
  });

  group('AppDetailScreen - description', () {
    testWidgets('shows the plain description', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(_buildApp(description: 'A great media server.')),
      );
      expect(find.text('A great media server.'), findsOneWidget);
    });

    testWidgets('strips HTML tags and decodes basic entities from the readme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          _buildApp(
            appReadme:
                '<p>Fish &amp; Chips</p> <b>bold</b> &lt;tag&gt; &gt;end',
          ),
        ),
      );
      expect(find.text('Details'), findsOneWidget);
      expect(find.text('Fish & Chips bold <tag> >end'), findsOneWidget);
    });

    testWidgets('hides the Details section when readme is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp(appReadme: '')));
      expect(find.text('Details'), findsNothing);
    });

    testWidgets('hides the Details section when readme is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp()));
      expect(find.text('Details'), findsNothing);
    });
  });

  group('AppDetailScreen - metadata', () {
    testWidgets('shows categories, catalog and train', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          _buildApp(
            categories: const ['Media', 'Network'],
            catalog: 'community',
            train: 'stable',
          ),
        ),
      );
      expect(find.text('Media, Network'), findsOneWidget);
      expect(find.text('community'), findsOneWidget);
      expect(find.text('stable'), findsOneWidget);
    });

    testWidgets('shows Not specified for an empty category list', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp(categories: const [])));
      expect(find.text('Not specified'), findsOneWidget);
    });

    testWidgets('hides the Tags row when there are no tags', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp(tags: const [])));
      expect(find.text('Tags'), findsNothing);
    });

    testWidgets('shows the Tags row when tags are present', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(_buildApp(tags: const ['media', 'streaming'])),
      );
      expect(find.text('Tags'), findsOneWidget);
      expect(find.text('media, streaming'), findsOneWidget);
    });

    testWidgets('hides Last Updated when lastUpdate is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp(lastUpdate: null)));
      expect(find.text('Last Updated'), findsNothing);
    });

    testWidgets('formats a date over a year old in years', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          _buildApp(
            lastUpdate: DateTime.now().subtract(const Duration(days: 400)),
          ),
        ),
      );
      expect(find.textContaining('year'), findsOneWidget);
    });

    testWidgets('formats a date over a month old in months', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          _buildApp(
            lastUpdate: DateTime.now().subtract(const Duration(days: 90)),
          ),
        ),
      );
      expect(find.textContaining('month'), findsOneWidget);
    });

    testWidgets('formats a date within the last month in days', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          _buildApp(
            lastUpdate: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ),
      );
      expect(find.textContaining('day'), findsOneWidget);
    });

    testWidgets('formats a date within the last day in hours', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          _buildApp(
            lastUpdate: DateTime.now().subtract(const Duration(hours: 5)),
          ),
        ),
      );
      expect(find.textContaining('hour'), findsOneWidget);
    });

    testWidgets('formats a very recent date as Recently', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp(lastUpdate: DateTime.now())));
      expect(find.text('Recently'), findsOneWidget);
    });

    testWidgets(
      'shows the health error banner for an installed, unhealthy app',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrap(
            _buildApp(
              installed: true,
              healthy: false,
              healthyError: 'Container crashed on startup',
            ),
          ),
        );
        expect(find.text('Container crashed on startup'), findsOneWidget);
        expect(
          find.byIcon(CupertinoIcons.exclamationmark_triangle_fill),
          findsOneWidget,
        );
      },
    );

    testWidgets('hides the health error banner when the app is healthy', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          _buildApp(
            installed: true,
            healthy: true,
            healthyError: 'should not show',
          ),
        ),
      );
      expect(find.text('should not show'), findsNothing);
    });

    testWidgets('hides the health error banner when the app is not installed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          _buildApp(
            installed: false,
            healthy: false,
            healthyError: 'should not show either',
          ),
        ),
      );
      expect(find.text('should not show either'), findsNothing);
    });
  });

  group('AppDetailScreen - maintainers', () {
    testWidgets('hides the section when there are no maintainers', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp(maintainers: const [])));
      expect(find.text('Maintainers'), findsNothing);
    });

    testWidgets('shows name and email, hiding the email row when empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          _buildApp(
            maintainers: const [
              AppMaintainer(
                name: 'Jane Doe',
                email: 'jane@example.com',
                url: '',
              ),
              AppMaintainer(name: 'No Email Person', email: '', url: ''),
            ],
          ),
        ),
      );
      expect(find.text('Maintainers'), findsOneWidget);
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('jane@example.com'), findsOneWidget);
      expect(find.text('No Email Person'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.person_circle), findsNWidgets(2));
    });
  });

  group('AppDetailScreen - sources', () {
    testWidgets('hides the section when there are no sources', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp(sources: const [])));
      expect(find.text('Sources'), findsNothing);
    });

    testWidgets('shows each source and tapping it does not crash', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          _buildApp(
            sources: const [
              'https://github.com/example/plex',
              'https://hub.docker.com/r/example/plex',
            ],
          ),
        ),
      );
      expect(find.text('Sources'), findsOneWidget);
      expect(find.text('https://github.com/example/plex'), findsOneWidget);
      expect(
        find.text('https://hub.docker.com/r/example/plex'),
        findsOneWidget,
      );

      await tester.tap(find.text('https://github.com/example/plex'));
      await tester.pump();
      expectNoLayoutOverflow(tester);
    });
  });

  group('AppDetailScreen - action buttons', () {
    testWidgets('shows Install App and it can be tapped without crashing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp(installed: false)));
      expect(find.text('Install App'), findsOneWidget);
      await tester.tap(find.text('Install App'));
      await tester.pump();
      expectNoLayoutOverflow(tester);
    });

    testWidgets('shows Manage App for an installed app', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp(installed: true)));
      expect(find.text('Manage App'), findsOneWidget);
      await tester.tap(find.text('Manage App'));
      await tester.pump();
      expectNoLayoutOverflow(tester);
    });

    testWidgets('hides View Homepage when home is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp(home: null)));
      expect(find.text('View Homepage'), findsNothing);
    });

    testWidgets('hides View Homepage when home is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp(home: '')));
      expect(find.text('View Homepage'), findsNothing);
    });

    testWidgets('shows and taps View Homepage when home is set', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp(home: 'https://plex.tv')));
      expect(find.text('View Homepage'), findsOneWidget);
      await tester.tap(find.text('View Homepage'));
      await tester.pump();
      expectNoLayoutOverflow(tester);
    });
  });

  group('AppDetailScreen - overflow menu', () {
    testWidgets('opens the action sheet with the app title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp(name: 'plex', title: 'Plex')));
      await _openActionSheet(tester);

      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      expect(find.text('Add to Favorites'), findsOneWidget);
      // The sheet's own title echoes the app's effective display name.
      expect(
        find.descendant(
          of: find.byType(CupertinoActionSheet),
          matching: find.text('Plex'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('does not show Edit Configuration for an uninstalled app', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp(installed: false)));
      await _openActionSheet(tester);
      expect(find.text('Edit Configuration'), findsNothing);
    });

    testWidgets('shows Edit Configuration for an installed app', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp(installed: true)));
      await _openActionSheet(tester);
      expect(find.text('Edit Configuration'), findsOneWidget);
    });

    testWidgets(
      'shows Remove from Favorites when the app is already a favorite',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrap(
            _buildApp(name: 'plex'),
            appProvider: _FakeAppProvider(
              database: database,
              serverService: unifiedServerService,
              favorite: true,
            ),
          ),
        );
        await _openActionSheet(tester);
        expect(find.text('Remove from Favorites'), findsOneWidget);
      },
    );

    testWidgets('tapping the favorite action toggles favorite state', (
      WidgetTester tester,
    ) async {
      final fakeProvider = _FakeAppProvider(
        database: database,
        serverService: unifiedServerService,
      );
      await tester.pumpWidget(
        wrap(_buildApp(name: 'plex'), appProvider: fakeProvider),
      );
      await _openActionSheet(tester);
      await tester.tap(find.text('Add to Favorites'));
      await settleRouteTransition(tester);

      expect(fakeProvider.toggleCallCount, 1);
      expect(fakeProvider.lastToggledAppName, 'plex');
      expect(fakeProvider.lastToggledValue, isTrue);
    });

    testWidgets('does not show View Homepage action when home is unset', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp(home: null)));
      await _openActionSheet(tester);
      // Only the button in the body should be absent too, so a zero count
      // here confirms the action-sheet branch is skipped.
      expect(find.text('View Homepage'), findsNothing);
    });

    testWidgets('shows and taps View Homepage action when home is set', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp(home: 'https://plex.tv')));
      await _openActionSheet(tester);
      // One in the sheet, since the body button is now offscreen underneath
      // the modal barrier but still present in the tree.
      expect(find.text('View Homepage'), findsWidgets);
      await tester.tap(find.text('View Homepage').last);
      await settleRouteTransition(tester);
      expectNoLayoutOverflow(tester);
    });

    testWidgets('shows View Sources action only when sources exist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp(sources: const [])));
      await _openActionSheet(tester);
      expect(find.text('View Sources'), findsNothing);
    });

    testWidgets('tapping View Sources dismisses the sheet without crashing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(_buildApp(sources: const ['https://github.com/example'])),
      );
      await _openActionSheet(tester);
      expect(find.text('View Sources'), findsOneWidget);
      await tester.tap(find.text('View Sources'));
      await settleRouteTransition(tester);
      expect(find.byType(CupertinoActionSheet), findsNothing);
    });

    testWidgets('tapping Cancel dismisses the sheet', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(_buildApp()));
      await _openActionSheet(tester);
      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await settleRouteTransition(tester);
      expect(find.byType(CupertinoActionSheet), findsNothing);
    });

    testWidgets('tapping Edit Configuration with a config navigates to '
        'AppConfigurationScreen', (WidgetTester tester) async {
      final config = AppConfig(
        serverId: 'server-1',
        appName: 'plex',
        displayName: 'My Plex',
      );
      await tester.pumpWidget(
        wrap(
          _buildApp(name: 'plex', installed: true),
          appProvider: _FakeAppProvider(
            database: database,
            serverService: unifiedServerService,
            config: config,
          ),
        ),
      );
      await _openActionSheet(tester);
      await tester.tap(find.text('Edit Configuration'));
      await settleRouteTransition(tester);

      expect(find.byType(AppConfigurationScreen), findsOneWidget);
      expect(find.text('Configure plex'), findsOneWidget);
    });

    testWidgets(
      'tapping Edit Configuration without a config shows an error dialog',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrap(
            _buildApp(name: 'plex', installed: true),
            appProvider: _FakeAppProvider(
              database: database,
              serverService: unifiedServerService,
              config: null,
            ),
          ),
        );
        await _openActionSheet(tester);
        await tester.tap(find.text('Edit Configuration'));
        await settleRouteTransition(tester);

        expect(find.byType(CupertinoAlertDialog), findsOneWidget);
        expect(
          find.textContaining('App configuration not found'),
          findsOneWidget,
        );

        await tester.tap(find.text('OK'));
        await settleRouteTransition(tester);
        expect(find.byType(CupertinoAlertDialog), findsNothing);
      },
    );
  });

  group('AppDetailScreen - layout', () {
    testWidgets(
      'renders a fully populated app at iPhone width without overflow',
      (WidgetTester tester) async {
        useCompactSurface(tester);

        final fullApp = _buildApp(
          name: 'a-very-long-installed-app-instance-name-for-overflow',
          title: 'A Very Long App Title For Overflow Testing Purposes',
          description:
              'A long description that wraps across several lines to '
              'stress the layout at a narrow phone width.',
          installed: true,
          healthy: false,
          healthyError:
              'Container exited unexpectedly with a fairly long error '
              'message that could wrap onto multiple lines.',
          categories: const [
            'Media & Streaming Applications',
            'Network & Communication Tools',
            'Home Automation',
          ],
          tags: const ['media', 'streaming', 'self-hosted'],
          home: 'https://plex.tv/a-very-long-homepage-url-for-testing',
          screenshots: const [
            'https://example.com/screenshot-one.png',
            'https://example.com/screenshot-two.png',
          ],
          sources: const [
            'https://github.com/example/a-very-long-repository-name-here',
          ],
          appReadme: '<p>Some <b>readme</b> content &amp; details.</p>',
          maintainers: const [
            AppMaintainer(
              name: 'A Maintainer With A Fairly Long Display Name',
              email: 'maintainer@example.com',
              url: '',
            ),
          ],
          lastUpdate: DateTime.now().subtract(const Duration(days: 40)),
        );

        await tester.pumpWidget(wrap(fullApp));
        await tester.pump();
        expectNoLayoutOverflow(tester);

        await tester.drag(find.byType(ListView).first, const Offset(0, -800));
        await tester.pump();
        expectNoLayoutOverflow(tester);
      },
    );
  });
}
