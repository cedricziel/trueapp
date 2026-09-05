import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/alert.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/server_health.dart';
import 'package:truehub/models/service_status.dart';
import 'package:truehub/providers/health_provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/screens/server_health_screen.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/layout_assertions.dart';
import '../helpers/provider_scope.dart';
import '../helpers/test_providers.dart';
import '../helpers/test_surfaces.dart';

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

  Widget createTestApp(HealthProvider healthProvider) {
    return provideAppProviders(
      database: database,
      service: unifiedServerService,
      serverProvider: serverProvider,
      healthProvider: healthProvider,
      child: CupertinoApp(home: ServerHealthScreen(server: testServer)),
    );
  }

  testWidgets('shows "All Systems Operational" when there are no alerts', (
    WidgetTester tester,
  ) async {
    useCompactSurface(tester);
    final healthProvider = _FakeHealthProvider(unifiedServerService);
    addTearDown(healthProvider.dispose);

    await tester.pumpWidget(createTestApp(healthProvider));
    await tester.pump();

    expectNoLayoutOverflow(tester);
    expect(find.text('All Systems Operational'), findsOneWidget);
  });

  testWidgets('surfaces active alerts and which disk needs attention', (
    WidgetTester tester,
  ) async {
    useCompactSurface(tester);
    final healthProvider = _FakeHealthProvider(
      unifiedServerService,
      alerts: [
        const Alert(
          id: '1',
          level: AlertLevel.critical,
          message: 'Pool "tank" is degraded',
        ),
      ],
      serverHealth: ServerHealth(
        serverId: 'test',
        timestamp: DateTime(2026, 1, 1),
        cpuUsage: 10,
        memoryUsage: 20,
        diskUsage: 30,
        temperature: 40,
        isOnline: true,
        disks: const [
          DiskInfo(
            name: 'ada3',
            model: 'X',
            serial: 'Y',
            size: 1000,
            used: 500,
            temperature: 52,
            health: 'FAILED',
          ),
        ],
        network: const NetworkInfo(
          downloadSpeed: 0,
          uploadSpeed: 0,
          totalDownload: 0,
          totalUpload: 0,
        ),
      ),
      services: const [
        ServiceStatus(id: 'cifs', isRunning: true, isEnabled: true),
        ServiceStatus(id: 'rsync', isRunning: false, isEnabled: false),
      ],
    );
    addTearDown(healthProvider.dispose);

    await tester.pumpWidget(createTestApp(healthProvider));
    await tester.pump();

    expectNoLayoutOverflow(tester);
    expect(find.text('1 active alert'), findsOneWidget);
    expect(find.textContaining('Pool "tank" is degraded'), findsWidgets);
    expect(find.text('ada3'), findsOneWidget);
    expect(find.text('52°C'), findsOneWidget);
    expect(find.text('SMB'), findsOneWidget);
    expect(find.text('Rsync'), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Stopped'), findsOneWidget);
  });
}

/// A [HealthProvider] whose data is seeded directly, bypassing the network
/// and credential flow so a widget test can render `ServerHealthScreen`
/// with realistic data without a live API client.
class _FakeHealthProvider extends HealthProvider {
  _FakeHealthProvider(
    super.service, {
    this.alerts = const [],
    this.services = const [],
    this.serverHealth,
  });

  @override
  final List<Alert> alerts;

  @override
  List<Alert> get activeAlerts =>
      alerts.where((alert) => !alert.dismissed).toList();

  @override
  final List<ServiceStatus> services;

  @override
  final ServerHealth? serverHealth;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;
}
