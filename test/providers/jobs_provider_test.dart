import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/job.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/jobs_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';

import '../helpers/fake_api_client.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';

Job _job({
  int id = 1,
  String method = 'pool.scrub.scrub',
  String state = 'RUNNING',
  double percent = 0,
  DateTime? timeFinished,
  bool abortable = true,
  String? error,
}) {
  return Job.fromJson({
    'id': id,
    'method': method,
    'state': state,
    'progress': {'percent': percent},
    'time_started': {r'$date': DateTime.now().millisecondsSinceEpoch},
    if (timeFinished != null)
      'time_finished': {r'$date': timeFinished.millisecondsSinceEpoch},
    'abortable': abortable,
    'error': ?error,
  });
}

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

  group('JobsProvider - initial state', () {
    test('has no jobs and is not subscribed or loading', () {
      expect(provider.jobs, isEmpty);
      expect(provider.hasData, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.isSubscribed, isFalse);
      expect(provider.error, isNull);
      expect(provider.runningJobs, isEmpty);
      expect(provider.waitingJobs, isEmpty);
      expect(provider.historyJobs, isEmpty);
      expect(provider.runningCount, 0);
      expect(provider.waitingCount, 0);
      expect(provider.recentFailures, isEmpty);
      expect(provider.needsAttention, isFalse);
    });
  });

  group('JobsProvider - setApiClient', () {
    test('with a known server obtains an API client', () async {
      await provider.setApiClient(testServer);
      await provider.subscribeToJobs();
      expect(provider.isSubscribed, isTrue);
      expect(provider.error, isNull);
    });

    test('missing credentials leaves the client unset', () async {
      final orphanServer = NasServer.create(
        name: 'No Credentials Server',
        host: '192.168.1.200',
        username: 'admin',
        password: 'password',
      );

      await provider.setApiClient(orphanServer);
      await provider.subscribeToJobs();

      expect(provider.isSubscribed, isFalse);
      expect(provider.error, 'No API client configured');
    });

    test('switching from a configured server to one without credentials '
        'clears the previous client rather than keeping it live', () async {
      // Regression test: setApiClient used to leave `_apiClient` pointed at
      // the previous server whenever the new server had no credentials (or
      // client creation failed), so abortJob/rerunJob/subscribeToJobs could
      // silently keep acting on the old server after switching.
      await provider.setApiClient(testServer);
      await provider.subscribeToJobs();
      expect(provider.isSubscribed, isTrue);

      final orphanServer = NasServer.create(
        name: 'No Credentials Server',
        host: '192.168.1.200',
        username: 'admin',
        password: 'password',
      );
      await provider.setApiClient(orphanServer);

      // The old client's subscription was torn down by setApiClient...
      expect(provider.isSubscribed, isFalse);
      // ...and nothing new is configured, so every action fails closed
      // instead of quietly reaching the previous (Test Server) client.
      final aborted = await provider.abortJob(1);
      expect(aborted, isFalse);
      expect(provider.error, 'No API client configured');
      expect(fakeClient.lastAbortedJobId, isNull);
    });
  });

  group('JobsProvider - subscribeToJobs', () {
    test('seeds jobs from getJobs before listening to the stream', () async {
      fakeClient.jobs = [_job(id: 1), _job(id: 2, state: 'WAITING')];
      await provider.setApiClient(testServer);

      await provider.subscribeToJobs();

      expect(provider.isSubscribed, isTrue);
      expect(fakeClient.calls, contains('getJobs'));
      expect(fakeClient.calls, contains('subscribeToJobs'));
      expect(provider.jobs.length, 2);
      expect(provider.runningCount, 1);
      expect(provider.waitingCount, 1);
    });

    test('receives further updates through the jobs stream', () async {
      await provider.setApiClient(testServer);

      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.subscribeToJobs();

      fakeClient.emitJobs([_job(id: 3, percent: 55)]);
      await Future<void>.delayed(Duration.zero);

      expect(provider.jobs.length, 1);
      expect(provider.jobs.first.progress.percent, 55);
      expect(notifications, greaterThan(0));
    });

    test('is idempotent when already subscribed', () async {
      await provider.setApiClient(testServer);
      await provider.subscribeToJobs();
      final callsAfterFirst = fakeClient.calls
          .where((c) => c == 'subscribeToJobs')
          .length;

      await provider.subscribeToJobs();
      final callsAfterSecond = fakeClient.calls
          .where((c) => c == 'subscribeToJobs')
          .length;

      expect(callsAfterSecond, callsAfterFirst);
    });

    test('without a client sets an error', () async {
      await provider.subscribeToJobs();
      expect(provider.isSubscribed, isFalse);
      expect(provider.error, 'No API client configured');
    });

    test('a subscribeToJobs failure sets an error', () async {
      await provider.setApiClient(testServer);
      fakeClient.failingMethods.add('subscribeToJobs');

      await provider.subscribeToJobs();

      expect(provider.isSubscribed, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.error, contains('Failed to subscribe'));
    });
  });

  group('JobsProvider - job classification', () {
    test('runningJobs/waitingJobs/historyJobs partition correctly', () async {
      fakeClient.jobs = [
        _job(id: 1, state: 'RUNNING'),
        _job(id: 2, state: 'WAITING'),
        _job(id: 3, state: 'HELD'),
        _job(id: 4, state: 'SUCCESS', timeFinished: DateTime.now()),
        _job(id: 5, state: 'FAILED', timeFinished: DateTime.now()),
      ];
      await provider.setApiClient(testServer);
      await provider.subscribeToJobs();

      expect(provider.runningJobs.map((j) => j.id), [1]);
      expect(provider.waitingJobs.map((j) => j.id), containsAll([2, 3]));
      expect(provider.historyJobs.map((j) => j.id), containsAll([4, 5]));
    });

    test('historyJobs sorts most recently finished first', () async {
      final older = DateTime.now().subtract(const Duration(hours: 2));
      final newer = DateTime.now();
      fakeClient.jobs = [
        _job(id: 1, state: 'SUCCESS', timeFinished: older),
        _job(id: 2, state: 'SUCCESS', timeFinished: newer),
      ];
      await provider.setApiClient(testServer);
      await provider.subscribeToJobs();

      expect(provider.historyJobs.map((j) => j.id).toList(), [2, 1]);
    });

    test(
      'recentFailures only includes failures within the attention window',
      () async {
        fakeClient.jobs = [
          _job(
            id: 1,
            state: 'FAILED',
            timeFinished: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          _job(
            id: 2,
            state: 'FAILED',
            timeFinished: DateTime.now().subtract(const Duration(hours: 30)),
          ),
        ];
        await provider.setApiClient(testServer);
        await provider.subscribeToJobs();

        expect(provider.recentFailures.map((j) => j.id).toList(), [1]);
      },
    );

    test(
      'needsAttention is true only when idle with a recent failure',
      () async {
        fakeClient.jobs = [
          _job(id: 1, state: 'FAILED', timeFinished: DateTime.now()),
        ];
        await provider.setApiClient(testServer);
        await provider.subscribeToJobs();
        expect(provider.needsAttention, isTrue);

        fakeClient.emitJobs([
          _job(id: 1, state: 'FAILED', timeFinished: DateTime.now()),
          _job(id: 2, state: 'RUNNING'),
        ]);
        await Future<void>.delayed(Duration.zero);
        expect(provider.needsAttention, isFalse);
      },
    );
  });

  group('JobsProvider - abortJob / rerunJob', () {
    test('abortJob delegates to the API client and returns true', () async {
      await provider.setApiClient(testServer);
      final result = await provider.abortJob(42);
      expect(result, isTrue);
      expect(fakeClient.lastAbortedJobId, 42);
    });

    test('abortJob surfaces a failure', () async {
      await provider.setApiClient(testServer);
      fakeClient.failingMethods.add('abortJob');

      final result = await provider.abortJob(42);

      expect(result, isFalse);
      expect(provider.error, contains('Failed to cancel job'));
    });

    test('abortJob without a client sets an error', () async {
      final result = await provider.abortJob(42);
      expect(result, isFalse);
      expect(provider.error, 'No API client configured');
    });

    test('rerunJob delegates to the API client and returns true', () async {
      await provider.setApiClient(testServer);
      final job = _job(id: 9, state: 'FAILED');

      final result = await provider.rerunJob(job);

      expect(result, isTrue);
      expect(fakeClient.lastRerunJob, job);
    });

    test('rerunJob surfaces a failure', () async {
      await provider.setApiClient(testServer);
      fakeClient.failingMethods.add('rerunJob');

      final result = await provider.rerunJob(_job(id: 9, state: 'FAILED'));

      expect(result, isFalse);
      expect(provider.error, contains('Failed to retry job'));
    });
  });

  group('JobsProvider - refreshJobs', () {
    test('starts a subscription when not yet subscribed', () async {
      await provider.setApiClient(testServer);

      await provider.refreshJobs();

      expect(provider.isSubscribed, isTrue);
    });

    test('re-fetches jobs without touching the subscription', () async {
      fakeClient.jobs = [_job(id: 1)];
      await provider.setApiClient(testServer);
      await provider.subscribeToJobs();

      fakeClient.jobs = [_job(id: 1), _job(id: 2)];
      await provider.refreshJobs();

      expect(provider.jobs.length, 2);
      final subscribeCalls = fakeClient.calls
          .where((c) => c == 'subscribeToJobs')
          .length;
      expect(subscribeCalls, 1);
    });

    test('without a client sets an error', () async {
      await provider.refreshJobs();
      expect(provider.error, 'No API client configured');
    });
  });

  group('JobsProvider - unsubscribeFromJobs', () {
    test('clears jobs and subscription state', () async {
      fakeClient.jobs = [_job(id: 1)];
      await provider.setApiClient(testServer);
      await provider.subscribeToJobs();
      expect(provider.hasData, isTrue);

      await provider.unsubscribeFromJobs();

      expect(provider.isSubscribed, isFalse);
      expect(provider.jobs, isEmpty);
      expect(fakeClient.calls, contains('unsubscribeFromJobs'));
    });

    test('is a no-op when not subscribed', () async {
      await provider.unsubscribeFromJobs();
      expect(provider.isSubscribed, isFalse);
      expect(fakeClient.calls.contains('unsubscribeFromJobs'), isFalse);
    });
  });

  group('JobsProvider - dispose', () {
    test('unsubscribes and releases the active client', () async {
      final scoped = JobsProvider(serverService);
      await scoped.setApiClient(testServer);
      await scoped.subscribeToJobs();

      scoped.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(
        TestProviders.mockApiClientManager.wasMethodCalled(
          'releaseClient:${testServer.id}',
        ),
        isTrue,
      );
    });
  });
}
