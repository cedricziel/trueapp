import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/navigation/server_route_host.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/mock_server_sync_service.dart';

/// Widget-level coverage for [ServerRouteHost] itself (ticket #84), isolated
/// from the rest of the app and backed by the lightweight
/// [MockUnifiedServerService] rather than a real database - these tests care
/// about resolution timing, not persistence.
void main() {
  NasServer server({String id = 'srv-1', String name = 'Cached Server'}) {
    return NasServer(
      id: id,
      name: name,
      host: '192.168.1.10',
      port: 443,
      username: 'admin',
      password: 'password',
    );
  }

  late MockUnifiedServerService service;

  setUp(() {
    service = MockUnifiedServerService();
  });

  tearDown(() async {
    await service.dispose();
  });

  Widget host({required String serverId, NasServer? cachedServer}) {
    return Provider<UnifiedServerService>.value(
      value: service,
      child: CupertinoApp(
        home: ServerRouteHost(
          serverId: serverId,
          cachedServer: cachedServer,
          builder: (context, resolved) =>
              CupertinoPageScaffold(child: Center(child: Text(resolved.name))),
        ),
      ),
    );
  }

  testWidgets('renders the cached server on the very first frame, without the '
      'loading placeholder', (WidgetTester tester) async {
    final cached = server();

    await tester.pumpWidget(host(serverId: cached.id, cachedServer: cached));
    // Deliberately no further pump: this is the first frame, before the
    // resolver's own lookup could possibly have completed.

    expect(find.text('Cached Server'), findsOneWidget);
    expect(find.byType(CupertinoActivityIndicator), findsNothing);
  });

  testWidgets(
    'shows a loading placeholder first, then the resolved server, when '
    'there is no cache',
    (WidgetTester tester) async {
      final registered = server();
      await service.saveServerConfig(server: registered, password: 'pw');

      await tester.pumpWidget(host(serverId: registered.id));
      // First frame: no cache, so the placeholder shows.
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.text('Cached Server'), findsNothing);

      await tester.pump();
      await tester.pump();

      expect(find.text('Cached Server'), findsOneWidget);
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
    },
  );

  testWidgets('ignores a cached server for a different id than the route', (
    WidgetTester tester,
  ) async {
    final registered = server(id: 'srv-real', name: 'Real Server');
    await service.saveServerConfig(server: registered, password: 'pw');
    final staleCache = server(id: 'srv-stale', name: 'Stale Cached Server');

    await tester.pumpWidget(
      host(serverId: registered.id, cachedServer: staleCache),
    );
    // The stale cache must not be shown even for a single frame.
    expect(find.text('Stale Cached Server'), findsNothing);

    await tester.pump();
    await tester.pump();

    expect(find.text('Real Server'), findsOneWidget);
  });

  testWidgets('redirects to /servers when the id is unknown', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/server/does-not-exist',
      routes: [
        GoRoute(
          path: '/servers',
          builder: (context, state) =>
              const CupertinoPageScaffold(child: Center(child: Text('List'))),
        ),
        GoRoute(
          path: '/server/:serverId',
          pageBuilder: (context, state) => CupertinoPage(
            child: ServerRouteHost(
              serverId: state.pathParameters['serverId']!,
              builder: (context, resolved) => CupertinoPageScaffold(
                child: Center(child: Text(resolved.name)),
              ),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      Provider<UnifiedServerService>.value(
        value: service,
        child: CupertinoApp.router(routerConfig: router),
      ),
    );
    for (var i = 0; i < 5 && find.text('List').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('List'), findsOneWidget);
  });
}
