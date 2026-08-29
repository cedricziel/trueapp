import 'package:flutter_test/flutter_test.dart';

import '../helpers/lcov_fixtures.dart';
import '../../tool/coverage/lcov_summary.dart';

void main() {
  group('parseLcov', () {
    test('sums the DA lines of a well-formed record', () {
      final report = lcovReport([
        lcovRecord('lib/foo.dart', hits: [1, 0, 4]),
      ]);

      final summary = parseLcov(report);

      expect(summary.hitLines, 2);
      expect(summary.totalLines, 3);
      expect(summary.percentage, closeTo(66.67, 0.01));
    });

    test('excludes build-generated sources by default', () {
      final report = lcovReport([
        lcovRecord('lib/services/database.g.dart', hits: [1, 1, 1, 1, 1]),
        lcovRecord('lib/foo.dart', hits: [1, 0]),
      ]);

      final summary = parseLcov(report);

      expect(summary.totalLines, 2);
      expect(summary.hitLines, 1);
      expect(summary.percentage, 50.0);
      expect(summary.files, ['lib/foo.dart']);
    });

    test('counts nothing when every record is filtered out', () {
      final report = lcovReport([
        lcovRecord('lib/services/database.g.dart', hits: [1, 1, 0]),
      ]);

      final summary = parseLcov(report);

      expect(summary.totalLines, 0);
      expect(summary.hitLines, 0);
      expect(summary.isEmpty, isTrue);
      expect(summary.percentage, 0);
    });

    test('a file with no executable lines neither crashes nor moves the '
        'percentage', () {
      final report = lcovReport([
        lcovRecord('lib/empty.dart'),
        lcovRecord('lib/foo.dart', hits: [1]),
      ]);

      final summary = parseLcov(report);

      expect(summary.percentage, 100.0);
      expect(summary.totalLines, 1);
      expect(summary.files, containsAll(['lib/empty.dart', 'lib/foo.dart']));
    });

    test('skips DA lines it cannot parse and counts them', () {
      final report = lcovReport([
        lcovRecord(
          'lib/foo.dart',
          extraLines: ['DA:1,1', 'DA:oops,1', 'DA:12', 'NOTALINE'],
        ),
      ]);

      final summary = parseLcov(report);

      expect(summary.totalLines, 1);
      expect(summary.hitLines, 1);
      expect(summary.malformedLines, 2);
    });

    test('accepts DA lines that carry a checksum field', () {
      final report = lcovReport([
        lcovRecord(
          'lib/foo.dart',
          extraLines: ['DA:12,3,7f9c2ba4e88f827d', 'DA:13,0'],
        ),
      ]);

      final summary = parseLcov(report);

      expect(summary.totalLines, 2);
      expect(summary.hitLines, 1);
      expect(summary.malformedLines, 0);
    });

    test('filters generated files whether the SF path is relative or '
        'absolute', () {
      final report = lcovReport([
        lcovRecord(
          '/Users/runner/work/trueapp/trueapp/lib/services/database.g.dart',
          hits: [1, 1, 1, 1, 1],
        ),
      ]);

      final summary = parseLcov(report);

      expect(summary.totalLines, 0);
      expect(summary.hitLines, 0);
    });
  });

  group('evaluate', () {
    test('fails a summary below the floor', () {
      const summary = LcovSummary(
        hitLines: 40,
        totalLines: 100,
        files: ['lib/foo.dart'],
        malformedLines: 0,
      );

      final result = evaluate(summary, 41);

      expect(result.passed, isFalse);
      expect(result.message, contains('40.0'));
      expect(result.message, contains('41'));
    });

    test('passes a summary exactly on the floor', () {
      const summary = LcovSummary(
        hitLines: 41,
        totalLines: 100,
        files: ['lib/foo.dart'],
        malformedLines: 0,
      );

      final result = evaluate(summary, 41);

      expect(result.passed, isTrue);
    });

    test('fails an empty summary regardless of the floor', () {
      const summary = LcovSummary(
        hitLines: 0,
        totalLines: 0,
        files: [],
        malformedLines: 0,
      );

      final result = evaluate(summary, 0);

      expect(result.passed, isFalse);
      expect(result.message, contains('no'));
    });
  });
}
