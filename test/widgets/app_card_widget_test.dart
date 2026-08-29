import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/providers/app_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/widgets/app_card_widget.dart';
import '../helpers/layout_assertions.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';

/// An [AppProvider] whose favorite state the test drives directly, instead
/// of routing every tap through a real drift database write. `isAppFavorite`
/// and `setAppFavorite` are plain overridable members, mirroring the
/// `_FakeAppProvider` seam already used in
/// `test/screens/server_detail_screen_test.dart`.
class _FakeAppProvider extends AppProvider {
  _FakeAppProvider({required super.database, required super.serverService});

  bool _favorite = false;
  String? lastToggledAppName;
  bool? lastToggledValue;
  int toggleCallCount = 0;

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
  String? iconUrl,
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
  AppResourceUsage? resourceUsage,
  AppUpgradeInfo? upgradeInfo,
  List<AppPortInfo> usedPorts = const [],
  Map<String, String> portals = const {},
  String? customDisplayName,
  String? customIconUrl,
  String? primaryCustomUrl,
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
    iconUrl: iconUrl,
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
    resourceUsage: resourceUsage,
    upgradeInfo: upgradeInfo,
    usedPorts: usedPorts,
    portals: portals,
    customDisplayName: customDisplayName,
    customIconUrl: customIconUrl,
    primaryCustomUrl: primaryCustomUrl,
  );
}

void main() {
  Widget wrapPlain(App app, {double width = 375}) {
    return CupertinoApp(
      home: Center(
        child: SizedBox(
          width: width,
          child: SingleChildScrollView(child: AppCardWidget(app: app)),
        ),
      ),
    );
  }

  group('AppCardWidget - not installed', () {
    testWidgets('shows the title, description and an Available badge', (
      WidgetTester tester,
    ) async {
      final app = _buildApp(title: 'Plex Media Server', installed: false);

      await tester.pumpWidget(wrapPlain(app));

      expect(find.text('Plex Media Server'), findsOneWidget);
      expect(
        find.text('Media server for movies, TV shows and music.'),
        findsOneWidget,
      );
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Installed'), findsNothing);
      expect(find.byIcon(CupertinoIcons.heart), findsNothing);
      expect(find.byIcon(CupertinoIcons.heart_fill), findsNothing);
      expectNoLayoutOverflow(tester);
    });

    testWidgets('uses the title (not the internal name) as display name', (
      WidgetTester tester,
    ) async {
      final app = _buildApp(
        name: 'plex-internal',
        title: 'Plex Media Server',
        installed: false,
      );

      await tester.pumpWidget(wrapPlain(app));

      expect(find.text('Plex Media Server'), findsOneWidget);
      expect(find.text('plex-internal'), findsNothing);
    });

    testWidgets('customDisplayName overrides the title', (
      WidgetTester tester,
    ) async {
      final app = _buildApp(
        title: 'Plex Media Server',
        customDisplayName: 'My Plex',
        installed: false,
      );

      await tester.pumpWidget(wrapPlain(app));

      expect(find.text('My Plex'), findsOneWidget);
      expect(find.text('Plex Media Server'), findsNothing);
    });

    testWidgets('shows up to two categories and the app version', (
      WidgetTester tester,
    ) async {
      final app = _buildApp(
        categories: const ['Media', 'Entertainment', 'Streaming'],
        latestAppVersion: '1.2.3',
      );

      await tester.pumpWidget(wrapPlain(app));

      expect(find.text('Media, Entertainment'), findsOneWidget);
      expect(find.text('v1.2.3'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.tag), findsOneWidget);
    });

    testWidgets(
      'hides the metadata row when there are no categories or version',
      (WidgetTester tester) async {
        final app = _buildApp();

        await tester.pumpWidget(wrapPlain(app));

        expect(find.byIcon(CupertinoIcons.tag), findsNothing);
      },
    );

    testWidgets('tapping the card navigates to the app detail screen', (
      WidgetTester tester,
    ) async {
      final app = _buildApp(title: 'Plex Media Server');

      await tester.pumpWidget(wrapPlain(app));

      await tester.tap(find.byType(AppCardWidget));
      await settleRouteTransition(tester);

      expect(find.byIcon(CupertinoIcons.back), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.ellipsis), findsOneWidget);
    });
  });

  group('AppCardWidget - installed', () {
    late AppDatabase database;
    late UnifiedServerService unifiedServerService;
    late _FakeAppProvider appProvider;

    setUp(() async {
      await TestProviders.cleanupTestEnvironment();
      TestProviders.setupTestEnvironment();
      database = createTestDatabase();
      unifiedServerService = await TestProviders.createMockUnifiedServerService(
        database: database,
      );
      appProvider = _FakeAppProvider(
        database: database,
        serverService: unifiedServerService,
      );
    });

    tearDown(() async {
      await TestProviders.disposeTestStack(
        providers: [appProvider],
        service: unifiedServerService,
        database: database,
      );
    });

    Widget wrapInstalled(App app, {double width = 375}) {
      return ChangeNotifierProvider<AppProvider>.value(
        value: appProvider,
        child: CupertinoApp(
          home: Center(
            child: SizedBox(
              width: width,
              child: SingleChildScrollView(child: AppCardWidget(app: app)),
            ),
          ),
        ),
      );
    }

    testWidgets('shows an Installed badge and an outlined favorite icon', (
      WidgetTester tester,
    ) async {
      final app = _buildApp(installed: true);

      await tester.pumpWidget(wrapInstalled(app));

      expect(find.text('Installed'), findsOneWidget);
      expect(find.text('Available'), findsNothing);
      expect(find.byIcon(CupertinoIcons.heart), findsOneWidget);
      expectNoLayoutOverflow(tester);
    });

    testWidgets('uses the instance name (not the title) as display name', (
      WidgetTester tester,
    ) async {
      final app = _buildApp(
        name: 'plex-instance-1',
        title: 'Plex Media Server',
        installed: true,
      );

      await tester.pumpWidget(wrapInstalled(app));

      expect(find.text('plex-instance-1'), findsOneWidget);
    });

    testWidgets(
      'tapping the favorite icon toggles it via the provider and updates '
      'the icon',
      (WidgetTester tester) async {
        final app = _buildApp(name: 'plex', installed: true);

        await tester.pumpWidget(wrapInstalled(app));

        expect(find.byIcon(CupertinoIcons.heart), findsOneWidget);

        await tester.tap(find.byIcon(CupertinoIcons.heart));
        await tester.pump();

        expect(appProvider.toggleCallCount, 1);
        expect(appProvider.lastToggledAppName, 'plex');
        expect(appProvider.lastToggledValue, isTrue);
        expect(find.byIcon(CupertinoIcons.heart_fill), findsOneWidget);
        final icon = tester.widget<Icon>(
          find.byIcon(CupertinoIcons.heart_fill),
        );
        expect(icon.color, CupertinoColors.systemRed);
      },
    );

    testWidgets('shows CPU and memory usage for a running app', (
      WidgetTester tester,
    ) async {
      final app = _buildApp(
        installed: true,
        resourceUsage: const AppResourceUsage(
          cpuUsage: 12.34,
          memoryUsage: 150 * 1024 * 1024,
          memoryLimit: 300,
          networkRxBytes: 0,
          networkTxBytes: 0,
        ),
      );

      await tester.pumpWidget(wrapInstalled(app));

      expect(find.text('CPU: 12.3%'), findsOneWidget);
      expect(find.text('Memory: 150.0 MB / 300.0 MB'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.speedometer), findsOneWidget);
      // No network traffic yet, so the network row stays hidden.
      expect(find.byIcon(CupertinoIcons.arrow_down_circle), findsNothing);
    });

    testWidgets('shows the network usage row once there is traffic', (
      WidgetTester tester,
    ) async {
      final app = _buildApp(
        installed: true,
        resourceUsage: AppResourceUsage(
          cpuUsage: 1.0,
          memoryUsage: 1024 * 1024,
          memoryLimit: 0,
          networkRxBytes: 5 * 1024 * 1024,
          networkTxBytes: 300 * 1024,
          lastUpdated: DateTime.now().subtract(const Duration(seconds: 20)),
        ),
      );

      await tester.pumpWidget(wrapInstalled(app));

      expect(find.text('RX: 5.0 MB'), findsOneWidget);
      expect(find.text('TX: 300.0 KB'), findsOneWidget);
      expect(find.textContaining(RegExp(r'^\d+s ago$')), findsOneWidget);
    });

    testWidgets('hides the resource usage block when there is none', (
      WidgetTester tester,
    ) async {
      final app = _buildApp(installed: true);

      await tester.pumpWidget(wrapInstalled(app));

      expect(find.byIcon(CupertinoIcons.speedometer), findsNothing);
    });

    testWidgets(
      'shows the upgrade banner with an Upgrade button when available and '
      'the version is upgradeable',
      (WidgetTester tester) async {
        final app = _buildApp(
          title: 'Plex Media Server',
          installed: true,
          upgradeInfo: const AppUpgradeInfo(
            upgradeAvailable: true,
            availableVersion: '2.0.0',
            currentVersion: '1.0.0',
            canUpgrade: true,
          ),
        );

        await tester.pumpWidget(wrapInstalled(app));

        expect(find.text('Update available: 2.0.0'), findsOneWidget);
        expect(find.text('Upgrade'), findsOneWidget);

        await tester.tap(find.text('Upgrade'));
        await tester.pump();

        expect(find.text('Upgrade Plex Media Server'), findsOneWidget);
        expect(find.text('Current version: 1.0.0'), findsOneWidget);
        expect(find.text('Available version: 2.0.0'), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pump();

        expect(find.text('Upgrade Plex Media Server'), findsNothing);
      },
    );

    testWidgets('hides the Upgrade button when the app cannot be upgraded', (
      WidgetTester tester,
    ) async {
      final app = _buildApp(
        installed: true,
        upgradeInfo: const AppUpgradeInfo(
          upgradeAvailable: true,
          availableVersion: '2.0.0',
          canUpgrade: false,
        ),
      );

      await tester.pumpWidget(wrapInstalled(app));

      expect(find.text('Update available: 2.0.0'), findsOneWidget);
      expect(find.text('Upgrade'), findsNothing);
    });

    testWidgets('hides the upgrade banner when no upgrade is available', (
      WidgetTester tester,
    ) async {
      final app = _buildApp(
        installed: true,
        upgradeInfo: const AppUpgradeInfo(
          upgradeAvailable: false,
          canUpgrade: false,
        ),
      );

      await tester.pumpWidget(wrapInstalled(app));

      expect(find.textContaining('Update available'), findsNothing);
    });

    testWidgets('shows the primary custom URL and used ports', (
      WidgetTester tester,
    ) async {
      final app = _buildApp(
        installed: true,
        primaryCustomUrl: 'https://plex.example.com',
        usedPorts: const [
          AppPortInfo(
            containerPort: 32400,
            protocol: 'tcp',
            hostPorts: [AppHostPort(hostPort: 32400, hostIp: '0.0.0.0')],
          ),
          AppPortInfo(containerPort: 1900, protocol: 'udp', hostPorts: []),
        ],
      );

      await tester.pumpWidget(wrapInstalled(app));

      expect(find.text('Ports & Access'), findsOneWidget);
      expect(find.text('https://plex.example.com'), findsOneWidget);
      expect(find.text('Port 32400 (TCP)'), findsOneWidget);
      expect(find.text('Host: 32400'), findsOneWidget);
      expect(find.text('Port 1900 (UDP)'), findsOneWidget);
      expectNoLayoutOverflow(tester);

      // Tapping the custom URL delegates to url_launcher, which has no
      // platform implementation under test; AppCardWidget swallows that
      // failure internally so the tap must not throw.
      await tester.tap(find.text('https://plex.example.com'));
      await tester.pump();
    });

    testWidgets('shows portal links below the used ports', (
      WidgetTester tester,
    ) async {
      final app = _buildApp(
        installed: true,
        primaryCustomUrl: 'https://plex.example.com',
        portals: const {'web': 'http://192.168.1.10:32400'},
      );

      await tester.pumpWidget(wrapInstalled(app));

      expect(find.text('web: http://192.168.1.10:32400'), findsOneWidget);
    });

    testWidgets(
      'hides the ports section entirely when there is no URL or port data',
      (WidgetTester tester) async {
        final app = _buildApp(installed: true);

        await tester.pumpWidget(wrapInstalled(app));

        expect(find.text('Ports & Access'), findsNothing);
      },
    );

    testWidgets('shows the health error banner for an unhealthy app', (
      WidgetTester tester,
    ) async {
      final app = _buildApp(
        installed: true,
        healthy: false,
        healthyError: 'Container exited with code 1',
      );

      await tester.pumpWidget(wrapInstalled(app));

      expect(find.text('Container exited with code 1'), findsOneWidget);
      expect(
        find.byIcon(CupertinoIcons.exclamationmark_triangle_fill),
        findsOneWidget,
      );
    });

    testWidgets('hides the health error banner when the app is healthy', (
      WidgetTester tester,
    ) async {
      final app = _buildApp(
        installed: true,
        healthy: true,
        healthyError: 'Should not show',
      );

      await tester.pumpWidget(wrapInstalled(app));

      expect(find.text('Should not show'), findsNothing);
    });

    testWidgets('renders every optional section at once without overflowing a '
        'narrow width', (WidgetTester tester) async {
      final app = _buildApp(
        name: 'plex-instance-with-a-very-long-generated-name',
        title: 'Plex Media Server With An Extremely Long Title',
        description:
            'A very long description that should wrap or ellipsize '
            'instead of overflowing the card at narrow widths.',
        installed: true,
        healthy: false,
        healthyError: 'Container health check failed after 3 retries',
        categories: const ['Media', 'Entertainment', 'Streaming'],
        latestAppVersion: '1.2.3',
        resourceUsage: AppResourceUsage(
          cpuUsage: 87.65,
          memoryUsage: 500 * 1024 * 1024,
          memoryLimit: 1024,
          networkRxBytes: 12 * 1024 * 1024,
          networkTxBytes: 3 * 1024 * 1024,
          lastUpdated: DateTime.now(),
        ),
        upgradeInfo: const AppUpgradeInfo(
          upgradeAvailable: true,
          availableVersion: '2.0.0',
          currentVersion: '1.0.0',
          canUpgrade: true,
        ),
        primaryCustomUrl: 'https://plex.example.com/a/very/long/path',
        usedPorts: const [
          AppPortInfo(
            containerPort: 32400,
            protocol: 'tcp',
            hostPorts: [AppHostPort(hostPort: 32400, hostIp: '0.0.0.0')],
          ),
        ],
        portals: const {'web': 'http://192.168.1.10:32400'},
      );

      await tester.pumpWidget(wrapInstalled(app, width: 375));

      expectNoLayoutOverflow(tester);
    });
  });
}
