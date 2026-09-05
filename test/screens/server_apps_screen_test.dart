import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/app_provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/screens/server_apps_screen.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/widgets/app_card_widget.dart';

import '../helpers/fake_api_client.dart';
import '../helpers/layout_assertions.dart';
import '../helpers/provider_scope.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';
import '../helpers/test_surfaces.dart';

/// A [FakeApiClient] whose [getInstalledApps] blocks on [gate] until the
/// test completes it - used to deterministically observe
/// [ServerAppsScreen]'s loading spinner instead of racing a fake client that
/// resolves within a single microtask.
class _GatedFakeApiClient extends FakeApiClient {
  final Completer<void> gate = Completer<void>();

  @override
  Future<List<App>> getInstalledApps() async {
    await gate.future;
    return super.getInstalledApps();
  }
}

/// A [FakeApiClient] whose catalog call ([getAvailableApps]) blocks on
/// [gate] while installed apps resolve immediately - the slow-catalog case
/// the screen must stay usable through.
class _GatedCatalogFakeApiClient extends FakeApiClient {
  final Completer<void> gate = Completer<void>();

  @override
  Future<List<App>> getAvailableApps() async {
    await gate.future;
    return super.getAvailableApps();
  }
}

App _app({
  required String name,
  String? title,
  bool installed = false,
  List<String> categories = const [],
  List<String> tags = const [],
  AppUpgradeInfo? upgradeInfo,
  String description = 'A test app.',
}) {
  return App(
    name: name,
    title: title ?? name,
    description: description,
    installed: installed,
    healthy: true,
    latestVersion: '1.0.0',
    latestAppVersion: '1.0.0',
    latestHumanVersion: '1.0.0',
    categories: categories,
    tags: tags,
    screenshots: const [],
    sources: const [],
    maintainers: const [],
    recommended: false,
    catalog: 'community',
    train: 'community',
    upgradeInfo: upgradeInfo,
    usedPorts: const [],
    portals: const {},
  );
}

// `App.effectiveDisplayName` shows the internal `name` for an *installed*
// app and `title` for one that is not - see app_card_widget_test.dart's note
// on this - and `AppProvider._syncAppsToDatabase` never carries
// `App.customDisplayName` through `AppConfig.fromApp` for a freshly-synced
// app, so there is no way to short-circuit that here. Tests below pick the
// right one of [displayedName]/`title` per app depending on `installed`.
String displayedName(App app) => app.installed ? app.name : app.title;

void main() {
  late AppDatabase database;
  late UnifiedServerService serverService;
  late ServerProvider serverProvider;
  late AppProvider appProvider;
  late FakeApiClient fakeClient;
  late NasServer testServer;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();

    database = createTestDatabase();
    serverService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    serverProvider = ServerProvider(serverService);
    appProvider = AppProvider(database: database, serverService: serverService);
    fakeClient = FakeApiClient();

    testServer = NasServer.create(
      name: 'Test Server',
      host: '192.168.1.100',
      username: 'admin',
      password: 'password',
    );

    await serverService.saveServerConfig(
      server: testServer,
      password: 'password',
    );
    TestProviders.mockApiClientManager.addMockClient(testServer.id, fakeClient);
  });

  tearDown(() async {
    await TestProviders.disposeTestStack(
      providers: [serverProvider, appProvider],
      service: serverService,
      database: database,
    );
  });

  Widget createTestApp() {
    return provideAppProviders(
      database: database,
      service: serverService,
      serverProvider: serverProvider,
      appProvider: appProvider,
      child: CupertinoApp(home: ServerAppsScreen(server: testServer)),
    );
  }

  /// Waits for the screen's `initState` post-frame callback to finish
  /// `setApiClient` + `loadApps` - both cross real drift/keychain I/O, so
  /// this must use [pumpUntilAsync] rather than a plain `pump` (see
  /// pump_helpers.dart's doc comment).
  ///
  /// `!appProvider.isLoading` alone is not a safe condition to poll: it is
  /// also true before the load has even started (`setApiClient` awaits real
  /// I/O before `loadApps` ever flips `isLoading`), so a naive wait can
  /// resolve immediately and race the real load. This instead waits for an
  /// observed true -> false transition of `isLoading`, proving a full load
  /// cycle actually ran.
  Future<void> settleInitialLoad(WidgetTester tester) async {
    var loadStarted = false;
    void listener() {
      if (appProvider.isLoading) loadStarted = true;
    }

    appProvider.addListener(listener);
    await pumpUntilAsync(tester, () => loadStarted && !appProvider.isLoading);
    appProvider.removeListener(listener);
  }

  group('ServerAppsScreen - populated list', () {
    testWidgets('renders installed apps on the default Installed tab', (
      WidgetTester tester,
    ) async {
      fakeClient.installedApps = [
        _app(name: 'plex', title: 'Plex', installed: true),
        _app(name: 'sonarr', title: 'Sonarr', installed: true),
      ];
      fakeClient.availableApps = [
        _app(name: 'radarr', title: 'Radarr', installed: false),
      ];
      fakeClient.appCategories = [];

      await tester.pumpWidget(createTestApp());
      await settleInitialLoad(tester);
      await tester.pump();

      expect(find.byType(AppCardWidget), findsNWidgets(2));
      // Installed apps show their instance `name`, not `title` - see
      // `displayedName`'s doc comment above.
      expect(find.text('plex'), findsOneWidget);
      expect(find.text('sonarr'), findsOneWidget);
      expect(find.text('Radarr'), findsNothing);
    });

    testWidgets('the Available tab shows only apps that are not installed', (
      WidgetTester tester,
    ) async {
      fakeClient.installedApps = [
        _app(name: 'plex', title: 'Plex', installed: true),
      ];
      fakeClient.availableApps = [
        _app(name: 'radarr', title: 'Radarr', installed: false),
        _app(name: 'sonarr', title: 'Sonarr', installed: false),
      ];
      fakeClient.appCategories = [];

      await tester.pumpWidget(createTestApp());
      await settleInitialLoad(tester);
      await tester.pump();

      await tester.tap(find.text('Available'));
      await tester.pump();

      expect(find.byType(AppCardWidget), findsNWidgets(2));
      expect(find.text('Radarr'), findsOneWidget);
      expect(find.text('Sonarr'), findsOneWidget);
      expect(find.text('Plex'), findsNothing);
    });

    testWidgets('the Favorites tab shows only apps marked as favorite', (
      WidgetTester tester,
    ) async {
      fakeClient.installedApps = [
        _app(name: 'plex', title: 'Plex', installed: true),
        _app(name: 'sonarr', title: 'Sonarr', installed: true),
      ];
      fakeClient.availableApps = [];
      fakeClient.appCategories = [];

      await tester.pumpWidget(createTestApp());
      await settleInitialLoad(tester);
      await tester.pump();

      // `setAppFavorite` writes through drift, which never completes inside
      // `testWidgets`'s FakeAsync zone - see pump_helpers.dart's doc comment.
      await runRealAsync(
        tester,
        () => appProvider.setAppFavorite('plex', true),
      );

      await tester.tap(find.text('Favorites'));
      await tester.pump();

      expect(find.byType(AppCardWidget), findsOneWidget);
      expect(find.text('plex'), findsOneWidget);
      expect(find.text('sonarr'), findsNothing);
    });

    testWidgets(
      'the Updates tab shows only installed apps with an available upgrade',
      (WidgetTester tester) async {
        fakeClient.installedApps = [
          _app(
            name: 'plex',
            title: 'Plex',
            installed: true,
            upgradeInfo: const AppUpgradeInfo(
              upgradeAvailable: true,
              availableVersion: '2.0.0',
              canUpgrade: true,
            ),
          ),
          _app(name: 'sonarr', title: 'Sonarr', installed: true),
        ];
        fakeClient.availableApps = [];
        fakeClient.appCategories = [];

        await tester.pumpWidget(createTestApp());
        await settleInitialLoad(tester);
        await tester.pump();

        await tester.tap(find.text('Updates'));
        await tester.pump();

        expect(find.byType(AppCardWidget), findsOneWidget);
        expect(find.text('plex'), findsOneWidget);
        expect(find.text('sonarr'), findsNothing);
      },
    );

    testWidgets('the refresh button reloads apps from the API', (
      WidgetTester tester,
    ) async {
      fakeClient.installedApps = [
        _app(name: 'plex', title: 'Plex', installed: true),
      ];
      fakeClient.availableApps = [];
      fakeClient.appCategories = [];

      await tester.pumpWidget(createTestApp());
      await settleInitialLoad(tester);
      await tester.pump();

      fakeClient.installedApps = [
        _app(name: 'plex', title: 'Plex', installed: true),
        _app(name: 'sonarr', title: 'Sonarr', installed: true),
      ];

      await tester.tap(find.byIcon(CupertinoIcons.refresh));
      await settleInitialLoad(tester);
      await tester.pump();

      expect(find.byType(AppCardWidget), findsNWidgets(2));
      expect(find.text('sonarr'), findsOneWidget);
    });

    testWidgets('tapping an app card navigates to the app detail screen', (
      WidgetTester tester,
    ) async {
      fakeClient.installedApps = [
        _app(name: 'plex', title: 'Plex', installed: true),
      ];
      fakeClient.availableApps = [];
      fakeClient.appCategories = [];

      await tester.pumpWidget(createTestApp());
      await settleInitialLoad(tester);
      await tester.pump();

      await tester.tap(find.byType(AppCardWidget));
      await settleRouteTransition(tester);

      expect(find.byIcon(CupertinoIcons.back), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.ellipsis), findsOneWidget);
    });
  });

  group('ServerAppsScreen - search', () {
    testWidgets('filters the visible apps by title, description, category '
        'and tag', (WidgetTester tester) async {
      // Not installed, so the card displays `title` (see `displayedName`'s
      // doc comment) - simplest for a test that is about the search filter,
      // not install state.
      fakeClient.installedApps = [];
      fakeClient.availableApps = [
        _app(
          name: 'plex',
          title: 'Plex Media Server',
          installed: false,
          description: 'Stream movies and shows.',
          categories: const ['media'],
          tags: const ['streaming'],
        ),
        _app(
          name: 'sonarr',
          title: 'Sonarr',
          installed: false,
          description: 'TV show manager.',
          categories: const ['downloads'],
          tags: const ['pvr'],
        ),
      ];
      fakeClient.appCategories = [];

      await tester.pumpWidget(createTestApp());
      await settleInitialLoad(tester);
      await tester.pump();

      await tester.tap(find.text('Available'));
      await tester.pump();

      expect(find.byType(AppCardWidget), findsNWidgets(2));

      // Matches by title.
      await tester.enterText(find.byType(CupertinoSearchTextField), 'plex');
      await tester.pump();
      expect(find.byType(AppCardWidget), findsOneWidget);
      expect(find.text('Plex Media Server'), findsOneWidget);

      // Matches by description, case-insensitively.
      await tester.enterText(find.byType(CupertinoSearchTextField), 'TV SHOW');
      await tester.pump();
      expect(find.byType(AppCardWidget), findsOneWidget);
      expect(find.text('Sonarr'), findsOneWidget);

      // Matches by category.
      await tester.enterText(find.byType(CupertinoSearchTextField), 'media');
      await tester.pump();
      expect(find.byType(AppCardWidget), findsOneWidget);
      expect(find.text('Plex Media Server'), findsOneWidget);

      // Matches by tag.
      await tester.enterText(find.byType(CupertinoSearchTextField), 'pvr');
      await tester.pump();
      expect(find.byType(AppCardWidget), findsOneWidget);
      expect(find.text('Sonarr'), findsOneWidget);

      // No match at all.
      await tester.enterText(
        find.byType(CupertinoSearchTextField),
        'nonexistent',
      );
      await tester.pump();
      expect(find.byType(AppCardWidget), findsNothing);
      expect(find.text('No apps match your search'), findsOneWidget);
    });
  });

  group('ServerAppsScreen - sorting', () {
    testWidgets(
      'sorts by name by default and reverts to insertion order when toggled '
      'off',
      (WidgetTester tester) async {
        // Inserted in reverse-alphabetical order so the two states are
        // visibly distinguishable.
        fakeClient.installedApps = [
          _app(name: 'zebra', title: 'Zebra App', installed: true),
          _app(name: 'alpha', title: 'Alpha App', installed: true),
        ];
        fakeClient.availableApps = [];
        fakeClient.appCategories = [];

        await tester.pumpWidget(createTestApp());
        await settleInitialLoad(tester);
        await tester.pump();

        List<String> renderedTitles() => tester
            .widgetList<AppCardWidget>(find.byType(AppCardWidget))
            .map((w) => w.app.title)
            .toList();

        // Sort-by-name is on by default.
        expect(find.text('Sort by Name'), findsOneWidget);
        expect(renderedTitles(), ['Alpha App', 'Zebra App']);

        await tester.tap(find.text('Sort by Name'));
        await tester.pump();

        expect(renderedTitles(), ['Zebra App', 'Alpha App']);

        await tester.tap(find.text('Sort by Name'));
        await tester.pump();

        expect(renderedTitles(), ['Alpha App', 'Zebra App']);
      },
    );
  });

  group('ServerAppsScreen - empty state', () {
    testWidgets('shows the Installed empty state when there are no apps at '
        'all', (WidgetTester tester) async {
      fakeClient.installedApps = [];
      fakeClient.availableApps = [];
      fakeClient.appCategories = [];

      await tester.pumpWidget(createTestApp());
      await settleInitialLoad(tester);
      await tester.pump();

      expect(find.byType(AppCardWidget), findsNothing);
      expect(find.text('No installed apps'), findsOneWidget);
      expect(
        find.text('Install apps from the Available tab to see them here.'),
        findsOneWidget,
      );
      expectNoLayoutOverflow(tester);
    });

    testWidgets('shows the per-tab empty state on Available/Favorites/'
        'Updates', (WidgetTester tester) async {
      fakeClient.installedApps = [];
      fakeClient.availableApps = [];
      fakeClient.appCategories = [];

      await tester.pumpWidget(createTestApp());
      await settleInitialLoad(tester);
      await tester.pump();

      await tester.tap(find.text('Available'));
      await tester.pump();
      expect(find.text('No available apps'), findsOneWidget);

      await tester.tap(find.text('Favorites'));
      await tester.pump();
      expect(find.text('No favorite apps'), findsOneWidget);

      await tester.tap(find.text('Updates'));
      await tester.pump();
      expect(find.text('No updates available'), findsOneWidget);
      expect(find.text('All your apps are up to date!'), findsOneWidget);
    });

    testWidgets('shows the search empty-state subtitle when a search yields '
        'no results', (WidgetTester tester) async {
      fakeClient.installedApps = [
        _app(name: 'plex', title: 'Plex', installed: true),
      ];
      fakeClient.availableApps = [];
      fakeClient.appCategories = [];

      await tester.pumpWidget(createTestApp());
      await settleInitialLoad(tester);
      await tester.pump();

      await tester.enterText(
        find.byType(CupertinoSearchTextField),
        'nothing-matches-this',
      );
      await tester.pump();

      expect(find.text('No installed apps'), findsOneWidget);
      expect(find.text('No apps match your search'), findsOneWidget);
      expect(
        find.text('Install apps from the Available tab to see them here.'),
        findsNothing,
      );
    });
  });

  group('ServerAppsScreen - loading state', () {
    testWidgets('shows a spinner while apps are loading, then the list', (
      WidgetTester tester,
    ) async {
      final gatedClient = _GatedFakeApiClient();
      gatedClient.installedApps = [
        _app(name: 'plex', title: 'Plex', installed: true),
      ];
      gatedClient.availableApps = [];
      gatedClient.appCategories = [];
      TestProviders.mockApiClientManager.addMockClient(
        testServer.id,
        gatedClient,
      );
      addTearDown(gatedClient.dispose);

      await tester.pumpWidget(createTestApp());
      await pumpUntilAsync(tester, () => appProvider.isLoading);

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.byType(AppCardWidget), findsNothing);

      gatedClient.gate.complete();
      await pumpUntilAsync(tester, () => !appProvider.isLoading);
      await tester.pump();

      expect(find.byType(CupertinoActivityIndicator), findsNothing);
      expect(find.byType(AppCardWidget), findsOneWidget);
      expect(find.text('plex'), findsOneWidget);
    });

    testWidgets(
      'installed apps are shown while the catalog is still loading, and the '
      'Available tab shows its own spinner until the catalog arrives',
      (WidgetTester tester) async {
        final gatedClient = _GatedCatalogFakeApiClient();
        gatedClient.installedApps = [
          _app(name: 'plex', title: 'Plex', installed: true),
        ];
        gatedClient.availableApps = [
          _app(name: 'radarr', title: 'Radarr', installed: false),
        ];
        gatedClient.appCategories = [];
        TestProviders.mockApiClientManager.addMockClient(
          testServer.id,
          gatedClient,
        );
        addTearDown(gatedClient.dispose);

        await tester.pumpWidget(createTestApp());
        await settleInitialLoad(tester);
        await tester.pump();

        // Installed apps are already usable while the catalog is pending.
        expect(appProvider.isCatalogLoading, isTrue);
        expect(find.byType(AppCardWidget), findsOneWidget);
        expect(find.text('plex'), findsOneWidget);

        await tester.tap(find.text('Available'));
        await tester.pump();
        expect(find.text('Loading app catalog...'), findsOneWidget);
        expect(find.byType(AppCardWidget), findsNothing);

        gatedClient.gate.complete();
        await pumpUntilAsync(tester, () => !appProvider.isCatalogLoading);
        await tester.pump();

        expect(find.text('Loading app catalog...'), findsNothing);
        expect(find.text('Radarr'), findsOneWidget);
      },
    );
  });

  group('ServerAppsScreen - error state', () {
    testWidgets('shows an error view with Retry when loading fails', (
      WidgetTester tester,
    ) async {
      fakeClient.failingMethods.add('getInstalledApps');

      await tester.pumpWidget(createTestApp());
      await pumpUntilAsync(
        tester,
        () => appProvider.connectionError != null && !appProvider.isLoading,
      );
      await tester.pump();

      expect(find.text('Failed to load apps'), findsOneWidget);
      // The cause is shown, not just a generic short message.
      expect(
        find.textContaining('getInstalledApps configured to fail'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(AppCardWidget), findsNothing);
      expectNoLayoutOverflow(tester);
    });

    testWidgets('Retry re-attempts the load and can succeed', (
      WidgetTester tester,
    ) async {
      fakeClient.failingMethods.add('getInstalledApps');

      await tester.pumpWidget(createTestApp());
      await pumpUntilAsync(
        tester,
        () => appProvider.connectionError != null && !appProvider.isLoading,
      );
      await tester.pump();
      expect(find.text('Failed to load apps'), findsOneWidget);

      fakeClient.failingMethods.remove('getInstalledApps');
      fakeClient.installedApps = [
        _app(name: 'plex', title: 'Plex', installed: true),
      ];

      await tester.tap(find.text('Retry'));
      await pumpUntilAsync(
        tester,
        () => appProvider.connectionError == null && !appProvider.isLoading,
      );
      await tester.pump();

      expect(find.text('Failed to load apps'), findsNothing);
      expect(find.byType(AppCardWidget), findsOneWidget);
    });
  });

  group('ServerAppsScreen - catalog failure', () {
    testWidgets(
      'installed apps stay usable when only the catalog fails to load',
      (WidgetTester tester) async {
        fakeClient.failingMethods.add('getAvailableApps');
        fakeClient.installedApps = [
          _app(name: 'plex', title: 'Plex', installed: true),
        ];
        fakeClient.appCategories = [];

        await tester.pumpWidget(createTestApp());
        await settleInitialLoad(tester);
        await tester.pump();

        expect(find.text('Failed to load apps'), findsNothing);
        expect(find.byType(AppCardWidget), findsOneWidget);
        expect(find.text('plex'), findsOneWidget);
        expectNoLayoutOverflow(tester);
      },
    );

    testWidgets('the Available tab reports the catalog failure with Retry', (
      WidgetTester tester,
    ) async {
      fakeClient.failingMethods.add('getAvailableApps');
      fakeClient.installedApps = [
        _app(name: 'plex', title: 'Plex', installed: true),
      ];
      fakeClient.appCategories = [];

      await tester.pumpWidget(createTestApp());
      await settleInitialLoad(tester);
      await tester.pump();

      await tester.tap(find.text('Available'));
      await tester.pump();

      expect(find.text('Failed to load app catalog'), findsOneWidget);
      expect(
        find.textContaining('getAvailableApps configured to fail'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(AppCardWidget), findsNothing);
      expectNoLayoutOverflow(tester);
    });

    testWidgets(
      'a previously synced catalog stays listed with a stale notice',
      (WidgetTester tester) async {
        fakeClient.installedApps = [
          _app(name: 'plex', title: 'Plex', installed: true),
        ];
        fakeClient.availableApps = [
          _app(name: 'radarr', title: 'Radarr', installed: false),
        ];
        fakeClient.appCategories = [];

        await tester.pumpWidget(createTestApp());
        await settleInitialLoad(tester);
        await tester.pump();

        fakeClient.failingMethods.add('getAvailableApps');
        await runRealAsync(tester, appProvider.refreshApps);

        await tester.tap(find.text('Available'));
        await tester.pump();

        expect(find.text('Radarr'), findsOneWidget);
        expect(
          find.textContaining('Catalog could not be refreshed'),
          findsOneWidget,
        );
        expect(find.text('Failed to load app catalog'), findsNothing);
        expectNoLayoutOverflow(tester);
      },
    );

    testWidgets(
      'a search that matches nothing in a stale catalog is an empty search '
      'result, not a catalog error',
      (WidgetTester tester) async {
        fakeClient.installedApps = [
          _app(name: 'plex', title: 'Plex', installed: true),
        ];
        fakeClient.availableApps = [
          _app(name: 'radarr', title: 'Radarr', installed: false),
        ];
        fakeClient.appCategories = [];

        await tester.pumpWidget(createTestApp());
        await settleInitialLoad(tester);
        await tester.pump();

        fakeClient.failingMethods.add('getAvailableApps');
        await runRealAsync(tester, appProvider.refreshApps);

        await tester.tap(find.text('Available'));
        await tester.pump();
        await tester.enterText(find.byType(CupertinoSearchTextField), 'zzz');
        await tester.pump();

        expect(find.text('No apps match your search'), findsOneWidget);
        expect(find.text('Failed to load app catalog'), findsNothing);
      },
    );
  });

  group('ServerAppsScreen - layout', () {
    testWidgets('renders at iPhone width without layout overflow', (
      WidgetTester tester,
    ) async {
      useCompactSurface(tester);

      fakeClient.installedApps = [
        _app(
          name: 'a-very-long-instance-name-that-stresses-the-card-layout',
          title:
              'An Extremely Long Application Title That Stresses The Card '
              'Layout At Narrow Widths',
          installed: true,
          categories: const ['Media & Streaming Applications', 'Network'],
          description:
              'A very long description that should wrap instead of '
              'overflowing the card at narrow widths.',
          upgradeInfo: const AppUpgradeInfo(
            upgradeAvailable: true,
            availableVersion: '2.1.0',
            currentVersion: '2.0.0',
            canUpgrade: true,
          ),
        ),
      ];
      fakeClient.availableApps = [];
      fakeClient.appCategories = [];

      await tester.pumpWidget(createTestApp());
      await settleInitialLoad(tester);
      await pumpUntilFound(tester, find.byType(AppCardWidget));

      expectNoLayoutOverflow(tester);
    });

    testWidgets('renders the empty state at iPhone width without overflow', (
      WidgetTester tester,
    ) async {
      useCompactSurface(tester);

      fakeClient.installedApps = [];
      fakeClient.availableApps = [];
      fakeClient.appCategories = [];

      await tester.pumpWidget(createTestApp());
      await settleInitialLoad(tester);
      await tester.pump();

      expectNoLayoutOverflow(tester);
    });
  });
}
