import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/pool_provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/screens/server_detail_screen.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/layout_assertions.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/provider_scope.dart';
import '../helpers/test_providers.dart';
import '../helpers/test_surfaces.dart';

/// Regression coverage for ticket #86: `ServerDetailScreen` overflowed
/// horizontally at phone widths. Its section headers built a bare
/// `Row(mainAxisAlignment: spaceBetween, ...)`, and a non-flex `Row` child
/// is laid out with unbounded main-axis constraints, so neither the title
/// nor the trailing action could shrink - at 390pt the "Storage Pools"
/// header alone overflowed.
void main() {
  late AppDatabase database;
  late ServerProvider serverProvider;
  late UnifiedServerService unifiedServerService;
  late NasServer testServer;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    unifiedServerService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    serverProvider = ServerProvider(unifiedServerService);

    testServer = NasServer.create(
      name: 'Test Server',
      host: '192.168.1.100',
      port: 443,
      username: 'admin',
      password: 'password',
    );
  });

  tearDown(() async {
    await TestProviders.disposeTestStack(
      providers: [serverProvider],
      service: unifiedServerService,
      database: database,
    );
  });

  Widget createTestApp() {
    return provideAppProviders(
      database: database,
      service: unifiedServerService,
      serverProvider: serverProvider,
      child: CupertinoApp(home: ServerDetailScreen(server: testServer)),
    );
  }

  testWidgets('renders at iPhone width without layout overflow', (
    WidgetTester tester,
  ) async {
    useCompactSurface(tester);

    await tester.pumpWidget(createTestApp());
    await pumpUntilFound(tester, find.text('Storage Pools'));

    // Guard against the assertion below being vacuous: if the screen had
    // silently fallen back to the authentication spinner or lock screen
    // instead of the real content, there would be nothing left to overflow.
    expect(find.text('Storage Pools'), findsOneWidget);
    expectNoLayoutOverflow(tester);
  });

  testWidgets(
    'renders the lower sections at iPhone width without layout overflow',
    (WidgetTester tester) async {
      useCompactSurface(tester);

      await tester.pumpWidget(createTestApp());
      await pumpUntilFound(tester, find.text('Storage Pools'));
      expectNoLayoutOverflow(tester);

      // RenderFlex overflow is only reported at paint time, so a Row below
      // the fold of the ListView never reports until it is scrolled into
      // view.
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();

      expectNoLayoutOverflow(tester);
    },
  );

  testWidgets(
    'renders a loaded pool with a long name at iPhone width without layout '
    'overflow',
    (WidgetTester tester) async {
      useCompactSurface(tester);

      final poolProvider = _FakePoolProvider(unifiedServerService, [
        {
          'name': 'a-very-long-storage-pool-name-that-stresses-the-card',
          'status': 'ONLINE',
          'healthy': true,
          'topology': <String, dynamic>{},
        },
      ]);
      addTearDown(poolProvider.dispose);

      await tester.pumpWidget(
        provideAppProviders(
          database: database,
          service: unifiedServerService,
          serverProvider: serverProvider,
          poolProvider: poolProvider,
          child: CupertinoApp(home: ServerDetailScreen(server: testServer)),
        ),
      );
      await pumpUntilFound(tester, find.text('Storage Pools'));

      expect(
        find.textContaining('a-very-long-storage-pool-name'),
        findsOneWidget,
      );
      expectNoLayoutOverflow(tester);
    },
  );
}

/// A [PoolProvider] whose [pools] is seeded directly, bypassing the network
/// and credential flow so a widget test can render `PoolCardWidget` with
/// realistic data without a live API client.
class _FakePoolProvider extends PoolProvider {
  _FakePoolProvider(super.service, this._seedPools);

  final List<Map<String, dynamic>> _seedPools;

  @override
  List<Map<String, dynamic>> get pools => _seedPools;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;
}
