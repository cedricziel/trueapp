import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/user_info.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/screens/user_profile_screen.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';

import '../helpers/fake_api_client.dart';
import '../helpers/layout_assertions.dart';
import '../helpers/provider_scope.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';
import '../helpers/test_surfaces.dart';

void main() {
  late AppDatabase database;
  late UnifiedServerService serverService;
  late ServerProvider serverProvider;
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
    fakeClient = FakeApiClient();

    testServer = NasServer.create(
      name: 'Test Server',
      host: '192.168.1.100',
      port: 443,
      username: 'admin',
      password: 'password',
    );

    await serverService.saveServerConfig(
      server: testServer,
      password: 'password',
    );
    TestProviders.mockApiClientManager.addMockClient(testServer.id, fakeClient);

    // ServerProvider auto-selects and authenticates the sole registered
    // server as soon as its stream listener observes it - a background
    // process saveServerConfig does not await (see
    // server_route_deep_link_test.dart for the same concern). Draining it
    // here, in real time, stops it from racing UserProfileScreen's own
    // explicit selectServer call: without this, both calls' selectServer()
    // run concurrently, and the later one's _clearAuthState() can wipe out
    // the currentUser the earlier one just loaded.
    var attempts = 0;
    while ((serverProvider.selectedServer == null ||
            serverProvider.isAuthenticating) &&
        attempts < 100) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      attempts++;
    }
    expect(
      serverProvider.selectedServer?.id == testServer.id &&
          !serverProvider.isAuthenticating,
      isTrue,
      reason:
          'ServerProvider did not finish auto-selecting and authenticating '
          'the sole registered server before the test body started',
    );
  });

  tearDown(() async {
    await TestProviders.disposeTestStack(
      providers: [serverProvider],
      service: serverService,
      database: database,
    );
    await fakeClient.dispose();
  });

  /// Waits for [finder] to find something, letting real drift/keychain I/O
  /// progress between pumps.
  ///
  /// `UserProfileScreen`'s post-frame `_loadUserInfo` crosses real I/O
  /// (`ServerProvider.selectServer` reads the password from the keychain and
  /// the server row from drift before `ApiClientManager.getClient` even
  /// runs), which never completes under a plain [pumpUntilFound] - see
  /// pump_helpers.dart's doc comment on [pumpUntilAsync].
  Future<void> pumpUntilFoundAsync(WidgetTester tester, Finder finder) async {
    final found = await pumpUntilAsync(
      tester,
      () => finder.evaluate().isNotEmpty,
    );
    expect(
      found,
      isTrue,
      reason: 'Expected to find $finder within the pump budget',
    );
  }

  Widget createTestApp({NasServer? server}) {
    return provideAppProviders(
      database: database,
      service: serverService,
      serverProvider: serverProvider,
      child: CupertinoApp(
        home: UserProfileScreen(server: server ?? testServer),
      ),
    );
  }

  group('UserProfileScreen - populated profile', () {
    testWidgets(
      'renders username, full name, groups, source, admin badge and 2FA '
      'badge for a fully-populated admin user',
      (WidgetTester tester) async {
        useCompactSurface(tester);

        fakeClient.currentUser = const UserInfo(
          username: 'jdoe',
          fullName: 'Jane Doe',
          homeDirectory: '/home/jdoe',
          shell: '/bin/zsh',
          uid: 1000,
          gid: 1000,
          source: 'ACTIVEDIRECTORY',
          isLocal: false,
          groupList: [100, 200, 300],
          attributes: {},
          hasTwoFactor: true,
          privilege: {
            'allowlist': ['ADMIN'],
          },
        );

        await tester.pumpWidget(createTestApp());
        await pumpUntilFoundAsync(tester, find.text('Jane Doe'));

        // Header. 'Jane Doe' appears both in the header title and the
        // "Full Name" details row value.
        expect(find.text('Jane Doe'), findsNWidgets(2));
        expect(find.text('@jdoe'), findsOneWidget);
        // 'Administrator' appears both in the header badge and as the
        // Account Details row label further down.
        expect(find.text('Administrator'), findsNWidgets(2));
        expect(find.text('2FA Enabled'), findsOneWidget);

        // Account Details section
        expect(find.text('Account Details'), findsOneWidget);
        expect(find.text('Username'), findsOneWidget);
        // 'jdoe' appears both in the @handle and the details row value.
        expect(find.text('jdoe'), findsOneWidget);
        expect(find.text('Full Name'), findsOneWidget);
        expect(find.text('User ID'), findsOneWidget);
        expect(find.text('1000'), findsNWidgets(2)); // uid and gid
        expect(find.text('Home Directory'), findsOneWidget);
        expect(find.text('/home/jdoe'), findsOneWidget);
        expect(find.text('Shell'), findsOneWidget);
        expect(find.text('/bin/zsh'), findsOneWidget);
        expect(find.text('Account Source'), findsOneWidget);
        expect(find.text('Active Directory'), findsOneWidget);
        expect(find.text('Local Account'), findsOneWidget);
        expect(find.text('No'), findsOneWidget); // isLocal == false

        // Security & Permissions section
        expect(find.text('Security & Permissions'), findsOneWidget);
        expect(find.text('Two-Factor Authentication'), findsOneWidget);
        expect(find.text('Enabled'), findsOneWidget);
        expect(find.text('Groups'), findsOneWidget);
        expect(find.text('100'), findsOneWidget);
        expect(find.text('200'), findsOneWidget);
        expect(find.text('300'), findsOneWidget);

        // Server Information section - below the fold of the default test
        // surface, and ListView's sliver only builds/lays out children near
        // the viewport, so it must be scrolled into view before its text
        // can be found at all (mirrors dataset_detail_screen_test.dart).
        await tester.scrollUntilVisible(
          find.text('Server Information'),
          500,
          scrollable: find.byType(Scrollable),
        );
        await tester.pump();

        expect(find.text('Server Information'), findsOneWidget);
        expect(find.text('Server Name'), findsOneWidget);
        expect(find.text('Test Server'), findsOneWidget);
        expect(find.text('Host'), findsOneWidget);
        expect(find.text('192.168.1.100'), findsOneWidget);
        expect(find.text('Port'), findsOneWidget);
        expect(find.text('443'), findsOneWidget);
        expect(find.text('Protocol'), findsOneWidget);
        expect(find.text('HTTPS'), findsOneWidget); // useHttps defaults true

        expectNoLayoutOverflow(tester);
      },
    );

    testWidgets(
      'falls back to username as the header title when full name is empty',
      (WidgetTester tester) async {
        useCompactSurface(tester);

        fakeClient.currentUser = const UserInfo(
          username: 'plainuser',
          fullName: '',
          homeDirectory: '/home/plainuser',
          shell: '/bin/sh',
          uid: 500,
          gid: 500,
          source: 'LOCAL',
          isLocal: true,
          groupList: [],
          attributes: {},
          hasTwoFactor: false,
          privilege: {},
        );

        await tester.pumpWidget(createTestApp());
        await pumpUntilFoundAsync(tester, find.text('plainuser'));

        // Header shows the username as the title (and no "@username" line,
        // since fullName is empty) - 'plainuser' now appears both as that
        // header title and as the Account Details "Username" row value.
        expect(find.text('plainuser'), findsNWidgets(2));
        expect(find.text('@plainuser'), findsNothing);

        // Non-admin, no 2FA: neither header badge renders, but the Account
        // Details "Administrator" row label is always present (with a "No"
        // value) regardless of admin status.
        expect(find.text('Administrator'), findsOneWidget);
        expect(find.text('2FA Enabled'), findsNothing);

        // Account Details: "Full Name" row is skipped for an empty name.
        expect(find.text('Full Name'), findsNothing);

        // Security section: no groups, so the "Groups" wrap is skipped.
        expect(find.text('Groups'), findsNothing);
        expect(find.text('Disabled'), findsOneWidget);

        expectNoLayoutOverflow(tester);
      },
    );

    testWidgets(
      'shows the Server Information last-connected row when the server has '
      'connected before',
      (WidgetTester tester) async {
        useCompactSurface(tester);

        final connectedServer = testServer.copyWith(
          lastConnected: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        await serverService.saveServerConfig(
          server: connectedServer,
          password: 'password',
        );
        TestProviders.mockApiClientManager.addMockClient(
          connectedServer.id,
          fakeClient,
        );

        await tester.pumpWidget(createTestApp(server: connectedServer));
        await pumpUntilFoundAsync(tester, find.text('Last Connected'));

        expect(find.text('Last Connected'), findsOneWidget);
        expect(find.text('5 minutes ago'), findsOneWidget);

        expectNoLayoutOverflow(tester);
      },
    );

    testWidgets('renders HTTP as the protocol when the server does not use '
        'HTTPS', (WidgetTester tester) async {
      useCompactSurface(tester);

      final httpServer = testServer.copyWith(useHttps: false);
      await serverService.saveServerConfig(
        server: httpServer,
        password: 'password',
      );
      TestProviders.mockApiClientManager.addMockClient(
        httpServer.id,
        fakeClient,
      );

      await tester.pumpWidget(createTestApp(server: httpServer));
      await pumpUntilFoundAsync(tester, find.text('Protocol'));

      expect(find.text('HTTP'), findsOneWidget);

      expectNoLayoutOverflow(tester);
    });
  });

  group('UserProfileScreen - loading state', () {
    testWidgets(
      'shows the activity indicator while getCurrentUser has not resolved '
      'yet',
      (WidgetTester tester) async {
        useCompactSurface(tester);

        // setUp already resolved provider._apiClient to fakeClient via the
        // auto-select settle, so swapping the manager's mapping alone would
        // not be picked up - force a fresh selectServer so the provider
        // re-fetches the client and gets the slow one instead.
        final completer = Completer<UserInfo>();
        final slowClient = _SlowApiClient(completer);
        await serverProvider.clearSelectedServer();
        TestProviders.mockApiClientManager.addMockClient(
          testServer.id,
          slowClient,
        );

        await tester.pumpWidget(createTestApp());
        // The post-frame-scheduled selectServer() crosses real drift/keychain
        // I/O before loadCurrentUser() ever runs, so this needs
        // pumpUntilAsync rather than a plain pump - see pump_helpers.dart.
        // isLoadingUser only flips true once loadCurrentUser() is blocked on
        // the still-uncompleted getCurrentUser() call.
        final startedLoading = await pumpUntilAsync(
          tester,
          () => serverProvider.isLoadingUser,
        );
        expect(startedLoading, isTrue);
        // pumpUntilAsync can return as soon as the provider flag flips,
        // before the frame that state change schedules has actually been
        // pumped - one more frame makes the rebuild visible.
        await tester.pump();

        expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
        expect(find.text('No user information available'), findsNothing);
        expectNoLayoutOverflow(tester);

        completer.complete(fakeClient.currentUser);
        await pumpUntilFound(tester, find.text('Account Details'));

        expect(find.text('Account Details'), findsOneWidget);
        expectNoLayoutOverflow(tester);
      },
    );
  });

  group('UserProfileScreen - error state', () {
    testWidgets(
      'shows the failure banner and retries when getCurrentUser fails',
      (WidgetTester tester) async {
        useCompactSurface(tester);
        fakeClient.failingMethods.add('getCurrentUser');

        await tester.pumpWidget(createTestApp());
        await pumpUntilFoundAsync(
          tester,
          find.text('Failed to load user information'),
        );

        expect(find.text('Failed to load user information'), findsOneWidget);
        expect(
          find.textContaining(
            'FakeApiClient: getCurrentUser configured to '
            'fail',
          ),
          findsOneWidget,
        );
        expect(find.text('Retry'), findsOneWidget);

        // Sections that depend on currentUser being non-null are not shown.
        expect(find.text('Account Details'), findsNothing);
        expect(find.text('Security & Permissions'), findsNothing);
        // The server info section has no such dependency and still renders.
        expect(find.text('Server Information'), findsOneWidget);

        expectNoLayoutOverflow(tester);

        // Allow the retry to succeed this time and confirm the profile loads.
        fakeClient.failingMethods.remove('getCurrentUser');
        await tapWhenUnambiguous(tester, find.text('Retry'));
        await pumpUntilFound(tester, find.text('Account Details'));

        expect(find.text('Account Details'), findsOneWidget);
        expectNoLayoutOverflow(tester);
      },
    );
  });

  group('UserProfileScreen - navigation', () {
    testWidgets('the Back button pops the route', (WidgetTester tester) async {
      useCompactSurface(tester);

      await tester.pumpWidget(
        provideAppProviders(
          database: database,
          service: serverService,
          serverProvider: serverProvider,
          child: CupertinoApp(
            home: Builder(
              builder: (context) => CupertinoPageScaffold(
                child: Center(
                  child: CupertinoButton(
                    onPressed: () => Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) => UserProfileScreen(server: testServer),
                      ),
                    ),
                    child: const Text('Open Profile'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tapWhenUnambiguous(tester, find.text('Open Profile'));
      await settleRouteTransition(tester);

      expect(find.text('User Profile'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      // Let the pushed screen's post-frame load (real drift/keychain I/O)
      // finish before popping, so no pending work outlives the test.
      await pumpUntilFoundAsync(tester, find.text('Account Details'));

      await tapWhenUnambiguous(tester, find.text('Back'));
      await settleRouteTransition(tester);

      expect(find.text('User Profile'), findsNothing);
      expect(find.text('Open Profile'), findsOneWidget);
    });
  });
}

/// A [FakeApiClient] whose [getCurrentUser] hangs on [completer] instead of
/// resolving immediately, so a test can observe the screen's loading state
/// before the profile arrives.
class _SlowApiClient extends FakeApiClient {
  _SlowApiClient(this._completer);

  final Completer<UserInfo> _completer;

  @override
  Future<UserInfo> getCurrentUser() async {
    calls.add('getCurrentUser');
    return _completer.future;
  }
}
