import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/pool.dart';

import '../helpers/pool_scan_fixtures.dart';

void main() {
  final start = poolScanStart;

  group('PoolScan.tryParse', () {
    test('parses a running scrub', () {
      final scan = PoolScan.tryParse(poolScanJson(totalSecsLeft: 600))!;

      expect(scan.function, PoolScanFunction.scrub);
      expect(scan.state, PoolScanState.scanning);
      expect(scan.isRunning, isTrue);
      expect(scan.isPaused, isFalse);
      expect(scan.percentage, 25.0);
      expect(scan.fraction, 0.25);
      expect(scan.bytesToProcess, 1000);
      expect(scan.bytesIssued, 250);
      expect(scan.startTime, start);
      expect(scan.endTime, isNull);
      expect(scan.errors, 0);
      expect(scan.totalSecsLeft, 600);
    });

    test('parses a running resilver', () {
      final scan = PoolScan.tryParse(poolScanJson(function: 'RESILVER'))!;

      expect(scan.function, PoolScanFunction.resilver);
      expect(scan.isRunning, isTrue);
    });

    test('parses a finished scrub with errors and an end time', () {
      final end = start.add(const Duration(hours: 3));
      final scan = PoolScan.tryParse(
        poolScanJson(
          state: 'FINISHED',
          percentage: 100.0,
          bytesIssued: 1000,
          errors: 4,
          endTime: truenasDate(end),
        ),
      )!;

      expect(scan.state, PoolScanState.finished);
      expect(scan.isRunning, isFalse);
      expect(scan.errors, 4);
      expect(scan.duration, const Duration(hours: 3));
    });

    test('parses a canceled scan', () {
      final scan = PoolScan.tryParse(poolScanJson(state: 'CANCELED'))!;

      expect(scan.state, PoolScanState.canceled);
      expect(scan.isRunning, isFalse);
    });

    test('flags a paused scan', () {
      final scan = PoolScan.tryParse(poolScanJson(pause: truenasDate(start)))!;

      expect(scan.isPaused, isTrue);
    });

    test('returns null when there is no scan object', () {
      expect(PoolScan.tryParse(null), isNull);
      expect(PoolScan.tryParse('nonsense'), isNull);
      expect(PoolScan.tryParse(<String, dynamic>{}), isNull);
    });

    test('returns null for a pool that was never scanned', () {
      expect(
        PoolScan.tryParse({
          'function': null,
          'state': null,
          'start_time': null,
          'end_time': null,
          'percentage': null,
          'bytes_to_process': null,
          'bytes_processed': null,
          'bytes_issued': null,
          'pause': null,
          'errors': null,
          'total_secs_left': null,
        }),
        isNull,
      );
    });

    test('tolerates missing and mistyped fields', () {
      final scan = PoolScan.tryParse({
        'function': 'SCRUB',
        'state': 'SCANNING',
        'percentage': 'oops',
        'bytes_to_process': 'oops',
        'errors': 'oops',
        'start_time': 'not a date',
      })!;

      expect(scan.percentage, isNull);
      expect(scan.fraction, isNull);
      expect(scan.bytesToProcess, isNull);
      expect(scan.errors, 0);
      expect(scan.startTime, isNull);
    });

    test('keeps unrecognised function and state values as unknown', () {
      final scan = PoolScan.tryParse(
        poolScanJson(function: 'ERRORSCRUB', state: 'WEIRD'),
      )!;

      expect(scan.function, PoolScanFunction.unknown);
      expect(scan.state, PoolScanState.unknown);
    });

    test('derives the percentage from bytes when it is missing', () {
      final scan = PoolScan.tryParse(
        poolScanJson(percentage: null, bytesIssued: 500),
      )!;

      expect(scan.fraction, 0.5);
    });

    test('clamps fraction into 0..1', () {
      expect(PoolScan.tryParse(poolScanJson(percentage: 140.0))!.fraction, 1.0);
      expect(PoolScan.tryParse(poolScanJson(percentage: -3.0))!.fraction, 0.0);
    });
  });

  group('PoolScan speed and time left', () {
    test('derives speed from bytes issued over elapsed time', () {
      final scan = PoolScan.tryParse(poolScanJson(bytesIssued: 600))!;

      expect(scan.bytesPerSecond(start.add(const Duration(seconds: 60))), 10.0);
    });

    test('has no speed before any bytes are issued or time has elapsed', () {
      expect(
        PoolScan.tryParse(
          poolScanJson(bytesIssued: 0),
        )!.bytesPerSecond(start.add(const Duration(seconds: 60))),
        isNull,
      );
      expect(PoolScan.tryParse(poolScanJson())!.bytesPerSecond(start), isNull);
    });

    test('has no speed for a finished or paused scan', () {
      final later = start.add(const Duration(minutes: 5));

      expect(
        PoolScan.tryParse(
          poolScanJson(state: 'FINISHED'),
        )!.bytesPerSecond(later),
        isNull,
      );
      expect(
        PoolScan.tryParse(
          poolScanJson(pause: truenasDate(start)),
        )!.bytesPerSecond(later),
        isNull,
      );
    });

    test('prefers the middleware ETA over the derived one', () {
      final scan = PoolScan.tryParse(poolScanJson(totalSecsLeft: 90))!;

      expect(scan.timeLeft(DateTime.now()), const Duration(seconds: 90));
    });

    test('derives the ETA from speed when the middleware gives none', () {
      // 600 of 1000 bytes in 60s => 10 B/s => 40s for the remaining 400.
      final scan = PoolScan.tryParse(poolScanJson(bytesIssued: 600))!;

      expect(
        scan.timeLeft(start.add(const Duration(seconds: 60))),
        const Duration(seconds: 40),
      );
    });

    test('has no ETA when nothing can be derived', () {
      final scan = PoolScan.tryParse(
        poolScanJson(bytesToProcess: null, bytesIssued: null),
      )!;

      expect(scan.timeLeft(DateTime.now()), isNull);
    });

    test('has no ETA for a finished scan', () {
      final scan = PoolScan.tryParse(
        poolScanJson(state: 'FINISHED', totalSecsLeft: 5),
      )!;

      expect(scan.timeLeft(DateTime.now()), isNull);
    });
  });

  group('Pool.scan', () {
    test('is parsed from pool.query and part of equality', () {
      final withScan = Pool.fromJson({'name': 'tank', 'scan': poolScanJson()});
      final without = Pool.fromJson({'name': 'tank', 'scan': null});

      expect(withScan.scan?.function, PoolScanFunction.scrub);
      expect(without.scan, isNull);
      expect(withScan, isNot(equals(without)));
    });
  });
}
