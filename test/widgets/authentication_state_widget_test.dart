import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/widgets/authentication_state_widget.dart';
import '../helpers/layout_assertions.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';

/// A [ServerProvider] whose authentication stream/status the test drives
/// directly, instead of routing through [ServerProvider.selectServer]'s real
/// credential lookup and API client machinery. `authenticationStream` and
/// `currentAuthStatus` are plain overridable getters, which is what makes
/// this seam possible without touching production code.
class _FakeServerProvider extends ServerProvider {
  _FakeServerProvider(super.service);

  final StreamController<AuthenticationStatus> _controller =
      StreamController<AuthenticationStatus>.broadcast();
  AuthenticationStatus _status = const AuthenticationStatus(
    state: AuthenticationState.none,
  );
  int retryCount = 0;

  @override
  Stream<AuthenticationStatus> get authenticationStream => _controller.stream;

  @override
  AuthenticationStatus get currentAuthStatus => _status;

  void emit(AuthenticationStatus status) {
    _status = status;
    _controller.add(status);
  }

  @override
  Future<void> retryAuthentication() async {
    retryCount++;
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}

void main() {
  late AppDatabase database;
  late UnifiedServerService unifiedServerService;
  late _FakeServerProvider serverProvider;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();
    database = createTestDatabase();
    unifiedServerService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    serverProvider = _FakeServerProvider(unifiedServerService);
  });

  tearDown(() async {
    await TestProviders.disposeTestStack(
      providers: [serverProvider],
      service: unifiedServerService,
      database: database,
    );
  });

  Widget wrap(Widget child, {double width = 375}) {
    return ChangeNotifierProvider<ServerProvider>.value(
      value: serverProvider,
      child: CupertinoApp(
        home: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    );
  }

  const child = Text('Server Content');

  group('AuthenticationStateWidget', () {
    testWidgets('renders the child when there is no auth status yet', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(const AuthenticationStateWidget(child: child)),
      );

      expect(find.text('Server Content'), findsOneWidget);
      expectNoLayoutOverflow(tester);
    });

    testWidgets('renders the child once authenticated', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(const AuthenticationStateWidget(child: child)),
      );

      serverProvider.emit(
        const AuthenticationStatus(state: AuthenticationState.authenticated),
      );
      await tester.pump();

      expect(find.text('Server Content'), findsOneWidget);
    });

    testWidgets('shows an activity indicator while authenticating', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(const AuthenticationStateWidget(child: child)),
      );

      serverProvider.emit(
        const AuthenticationStatus(state: AuthenticationState.authenticating),
      );
      await tester.pump();

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.text('Authenticating...'), findsOneWidget);
      expect(find.text('Server Content'), findsNothing);
      expectNoLayoutOverflow(tester);
    });

    testWidgets(
      'shows the required-auth locked state with an Authenticate button',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrap(const AuthenticationStateWidget(child: child)),
        );

        serverProvider.emit(
          const AuthenticationStatus(state: AuthenticationState.required),
        );
        await tester.pump();

        expect(find.text('Authentication Required'), findsOneWidget);
        expect(find.byIcon(CupertinoIcons.lock_shield), findsOneWidget);
        expect(find.text('Authenticate'), findsOneWidget);
        expect(find.byIcon(CupertinoIcons.lock), findsOneWidget);
        expect(find.text('Server Content'), findsNothing);
        expectNoLayoutOverflow(tester);

        await tester.tap(find.text('Authenticate'));
        await tester.pump();
        expect(serverProvider.retryCount, 1);
      },
    );

    testWidgets(
      'shows the failed-auth locked state with the error, server name and '
      'a Retry Authentication button',
      (WidgetTester tester) async {
        final server = NasServer.create(
          name: 'Home Server',
          host: '192.168.1.50',
          username: 'admin',
          password: 'password',
        );

        // Wider than the other cases in this file: under the widget-test
        // environment's synthetic square-glyph font (see
        // test/helpers/layout_assertions.dart), the filled button's
        // "Retry Authentication" label - longer than any other button text
        // this widget renders - is measured wide enough to overflow a true
        // 375pt row even though real proportional text fits comfortably.
        await tester.pumpWidget(
          wrap(const AuthenticationStateWidget(child: child), width: 500),
        );

        serverProvider.emit(
          AuthenticationStatus(
            state: AuthenticationState.failed,
            error: 'Invalid username or password',
            server: server,
          ),
        );
        await tester.pump();

        expect(find.text('Authentication Failed'), findsOneWidget);
        expect(find.text('Invalid username or password'), findsOneWidget);
        expect(find.textContaining('Server: ${server.name}'), findsOneWidget);
        expect(find.text('Retry Authentication'), findsOneWidget);
        expect(find.byIcon(CupertinoIcons.refresh), findsOneWidget);
        expectNoLayoutOverflow(tester);

        await tester.tap(find.text('Retry Authentication'));
        await tester.pump();
        expect(serverProvider.retryCount, 1);
      },
    );

    testWidgets('renders the child again once state resets to none', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(const AuthenticationStateWidget(child: child)),
      );

      serverProvider.emit(
        const AuthenticationStatus(state: AuthenticationState.required),
      );
      await tester.pump();
      expect(find.text('Server Content'), findsNothing);

      serverProvider.emit(
        const AuthenticationStatus(state: AuthenticationState.none),
      );
      // A second stream event delivered in the same test needs an extra
      // pump to drain: the broadcast controller's `add` is a microtask, and
      // one `pump()` only flushes the microtask queue built up since the
      // previous pump - not a second one queued during that same flush.
      await tester.pump();
      await tester.pump();
      expect(find.text('Server Content'), findsOneWidget);
    });
  });
}
