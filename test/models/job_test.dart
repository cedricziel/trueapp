import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/job.dart';

void main() {
  group('JobProgress', () {
    test('fromJson parses percent and description', () {
      final progress = JobProgress.fromJson({
        'percent': 42.5,
        'description': 'Copying files',
      });
      expect(progress.percent, equals(42.5));
      expect(progress.description, equals('Copying files'));
    });

    test('fromJson defaults percent to 0 and description to null', () {
      final progress = JobProgress.fromJson({});
      expect(progress.percent, equals(0));
      expect(progress.description, isNull);
    });

    test('fromJson handles null json', () {
      final progress = JobProgress.fromJson(null);
      expect(progress.percent, equals(0));
    });

    test('toJson round-trips', () {
      const progress = JobProgress(percent: 10, description: 'Step 1');
      final roundTripped = JobProgress.fromJson(progress.toJson());
      expect(roundTripped, equals(progress));
    });
  });

  group('Job.fromJson', () {
    test('parses a running job', () {
      final job = Job.fromJson({
        'id': 12,
        'method': 'pool.scrub.scrub',
        'arguments': ['tank'],
        'description': "Scrubbing pool 'tank'",
        'progress': {'percent': 34.0, 'description': 'Scanning'},
        'state': 'RUNNING',
        'time_started': {r'$date': 1700000000000},
        'time_finished': null,
        'abortable': true,
      });

      expect(job.id, equals(12));
      expect(job.method, equals('pool.scrub.scrub'));
      expect(job.arguments, equals(['tank']));
      expect(job.description, equals("Scrubbing pool 'tank'"));
      expect(job.progress.percent, equals(34.0));
      expect(job.state, equals(JobState.running));
      expect(
        job.timeStarted,
        equals(DateTime.fromMillisecondsSinceEpoch(1700000000000)),
      );
      expect(job.timeFinished, isNull);
      expect(job.abortable, isTrue);
      expect(job.isRunning, isTrue);
      expect(job.isWaiting, isFalse);
      expect(job.isFinished, isFalse);
      expect(job.isFailed, isFalse);
    });

    test('parses a failed job with an error', () {
      final job = Job.fromJson({
        'id': 7,
        'method': 'cloudsync.sync',
        'state': 'FAILED',
        'error': 'Connection timed out',
        'logs_excerpt': 'traceback...',
      });

      expect(job.state, equals(JobState.failed));
      expect(job.isFinished, isTrue);
      expect(job.isFailed, isTrue);
      expect(job.error, equals('Connection timed out'));
      expect(job.logsExcerpt, equals('traceback...'));
    });

    test('defaults missing fields', () {
      final job = Job.fromJson({'id': 1});
      expect(job.method, equals(''));
      expect(job.arguments, isEmpty);
      expect(job.description, isNull);
      expect(job.progress.percent, equals(0));
      expect(job.state, equals(JobState.unknown));
      expect(job.timeStarted, isNull);
      expect(job.timeFinished, isNull);
      expect(job.abortable, isFalse);
    });

    test('parses every known state', () {
      for (final entry in {
        'WAITING': JobState.waiting,
        'RUNNING': JobState.running,
        'SUCCESS': JobState.success,
        'FAILED': JobState.failed,
        'ABORTED': JobState.aborted,
        'HELD': JobState.held,
        'SOMETHING_ELSE': JobState.unknown,
      }.entries) {
        final job = Job.fromJson({'id': 1, 'state': entry.key});
        expect(job.state, equals(entry.value), reason: entry.key);
      }
    });

    test('isWaiting is true for both WAITING and HELD', () {
      expect(Job.fromJson({'id': 1, 'state': 'WAITING'}).isWaiting, isTrue);
      expect(Job.fromJson({'id': 1, 'state': 'HELD'}).isWaiting, isTrue);
      expect(Job.fromJson({'id': 1, 'state': 'RUNNING'}).isWaiting, isFalse);
    });

    test('isFinished is true for SUCCESS, FAILED and ABORTED', () {
      for (final state in ['SUCCESS', 'FAILED', 'ABORTED']) {
        expect(
          Job.fromJson({'id': 1, 'state': state}).isFinished,
          isTrue,
          reason: state,
        );
      }
      expect(Job.fromJson({'id': 1, 'state': 'RUNNING'}).isFinished, isFalse);
    });

    test('accepts a raw epoch-millisecond number for datetime fields', () {
      final job = Job.fromJson({'id': 1, 'time_started': 1700000000000});
      expect(
        job.timeStarted,
        equals(DateTime.fromMillisecondsSinceEpoch(1700000000000)),
      );
    });

    test('accepts an ISO 8601 string for datetime fields', () {
      final job = Job.fromJson({
        'id': 1,
        'time_started': '2023-11-14T22:13:20.000Z',
      });
      expect(job.timeStarted, isNotNull);
      expect(job.timeStarted!.year, equals(2023));
    });

    test('toJson round-trips through fromJson', () {
      final job = Job.fromJson({
        'id': 5,
        'method': 'zfs.replication.run',
        'arguments': ['backup'],
        'description': 'Replicating',
        'progress': {'percent': 50.0},
        'state': 'RUNNING',
        'time_started': {r'$date': 1700000000000},
        'abortable': true,
      });

      final roundTripped = Job.fromJson(job.toJson());
      expect(roundTripped, equals(job));
    });
  });

  group('Job.elapsed', () {
    test('is null when the job has not started', () {
      final job = Job.fromJson({'id': 1, 'state': 'WAITING'});
      expect(job.elapsed, isNull);
    });

    test('is measured against time_finished once the job is done', () {
      final job = Job.fromJson({
        'id': 1,
        'state': 'SUCCESS',
        'time_started': {r'$date': 1700000000000},
        'time_finished': {r'$date': 1700000010000},
      });
      expect(job.elapsed, equals(const Duration(seconds: 10)));
    });

    test('is measured against now while still running', () {
      final started = DateTime.now().subtract(const Duration(seconds: 5));
      final job = Job.fromJson({
        'id': 1,
        'state': 'RUNNING',
        'time_started': {r'$date': started.millisecondsSinceEpoch},
      });
      expect(job.elapsed!.inSeconds, greaterThanOrEqualTo(5));
    });
  });

  group('Job equality', () {
    test('two jobs with identical fields are equal', () {
      final a = Job.fromJson({'id': 1, 'method': 'x', 'state': 'RUNNING'});
      final b = Job.fromJson({'id': 1, 'method': 'x', 'state': 'RUNNING'});
      expect(a, equals(b));
    });

    test('jobs differing by id are not equal', () {
      final a = Job.fromJson({'id': 1, 'state': 'RUNNING'});
      final b = Job.fromJson({'id': 2, 'state': 'RUNNING'});
      expect(a == b, isFalse);
    });
  });
}
