import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/job.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/jobs_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/widgets/jobs_bell_button.dart';

import '../helpers/fake_api_client.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';

Job _job({required int id, required String state, DateTime? timeFinished}) {
  return Job.fromJson({
    'id': id,
    'method': 'pool.scrub.scrub',
    'state': state,
    if (timeFinished != null)
      'time_finished': {r'$date': timeFinished.millisecondsSinceEpoch},
  });
}

Widget _wrap(JobsProvider provider) {
  return ChangeNotifierProvider<JobsProvider>.value(
    value: provider,
    child: CupertinoApp(
      home: CupertinoPageScaffold(
        child: Center(
          child: JobsBellButton(
            server: NasServer.create(
              name: 'Test Server',
              host: '192.168.1.100',
              username: 'admin',
              password: 'password',
            ),
          ),
        ),
      ),
    ),
  );
}

Icon _bellIcon(WidgetTester tester) =>
    tester.widget<Icon>(find.byIcon(CupertinoIcons.bell));

void main() {
  late AppDatabase database;
  late UnifiedServerService serverService;
  late JobsProvider provider;
  late FakeApiClient fakeClient;
  late NasServer testServer;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();

    database = createTestDatabase();
    serverService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    provider = JobsProvider(serverService);
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
    provider.dispose();
    await fakeClient.dispose();
    await serverService.dispose();
    await TestProviders.cleanupTestEnvironment();
  });

  testWidgets('idle state: dim bell, no badge', (tester) async {
    await tester.pumpWidget(_wrap(provider));

    expect(find.byIcon(CupertinoIcons.bell), findsOneWidget);
    expect(_bellIcon(tester).color, CupertinoColors.systemGrey2);
    // No count badge and no red dot.
    expect(find.textContaining(RegExp(r'^\d+$')), findsNothing);
  });

  testWidgets('active state: blue bell with a running count badge', (
    tester,
  ) async {
    fakeClient.jobs = [
      _job(id: 1, state: 'RUNNING'),
      _job(id: 2, state: 'RUNNING'),
    ];
    await provider.setApiClient(testServer);
    await provider.subscribeToJobs();

    await tester.pumpWidget(_wrap(provider));

    expect(_bellIcon(tester).color, CupertinoColors.systemBlue);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets(
    'needs-attention state: red bell with no count when idle after a failure',
    (tester) async {
      fakeClient.jobs = [
        _job(id: 1, state: 'FAILED', timeFinished: DateTime.now()),
      ];
      await provider.setApiClient(testServer);
      await provider.subscribeToJobs();

      await tester.pumpWidget(_wrap(provider));

      expect(_bellIcon(tester).color, CupertinoColors.systemRed);
      expect(find.textContaining(RegExp(r'^\d+$')), findsNothing);
    },
  );

  testWidgets('running jobs take priority over a stale failure', (
    tester,
  ) async {
    fakeClient.jobs = [
      _job(id: 1, state: 'FAILED', timeFinished: DateTime.now()),
      _job(id: 2, state: 'RUNNING'),
    ];
    await provider.setApiClient(testServer);
    await provider.subscribeToJobs();

    await tester.pumpWidget(_wrap(provider));

    expect(_bellIcon(tester).color, CupertinoColors.systemBlue);
    expect(find.text('1'), findsOneWidget);
  });
}
