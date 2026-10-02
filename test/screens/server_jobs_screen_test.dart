import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/job.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/jobs_provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/screens/server_jobs_screen.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/provider_scope.dart';
import '../helpers/pump_helpers.dart';
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
    serverProvider = await TestProviders.createSettledServerProvider(
      unifiedServerService,
    );
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

  testWidgets('dragging the job list down refreshes the jobs', (
    WidgetTester tester,
  ) async {
    useCompactSurface(tester);
    final jobsProvider = _FakeJobsProvider(unifiedServerService, [
      Job.fromJson({
        'id': 1,
        'method': 'pool.scrub',
        'description': 'Scrub tank',
        'state': 'RUNNING',
      }),
    ]);
    addTearDown(jobsProvider.dispose);

    await tester.pumpWidget(
      provideAppProviders(
        database: database,
        service: unifiedServerService,
        serverProvider: serverProvider,
        jobsProvider: jobsProvider,
        child: CupertinoApp(home: ServerJobsScreen(server: testServer)),
      ),
    );
    await tester.pump();
    await pullToRefresh(tester, finder: find.byType(CustomScrollView));

    expect(jobsProvider.refreshCount, 1);
  });
}

class _FakeJobsProvider extends JobsProvider {
  _FakeJobsProvider(super.service, this._seedJobs)
    : super(clientManager: TestProviders.mockApiClientManager);

  final List<Job> _seedJobs;

  int refreshCount = 0;

  @override
  Future<void> refreshJobs() async => refreshCount++;

  @override
  List<Job> get jobs => _seedJobs;

  @override
  bool get hasData => _seedJobs.isNotEmpty;

  @override
  List<Job> get runningJobs => _seedJobs.where((job) => job.isRunning).toList();

  @override
  bool get isLoading => false;

  @override
  String? get error => null;
}
