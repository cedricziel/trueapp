// Enforces a coverage ratchet against coverage/lcov.info.
//
// This is a floor, not the 80% target CLAUDE.md/README describe: it is set
// to whatever this branch measured at the time it was introduced, rounded
// down to a whole percent, so CI stays green today but cannot regress. Raise
// tool/coverage_floor.txt as real coverage improves; never lower it without
// a written reason in the commit that does so. The 80% goal remains the
// destination, this gate just stops the number sliding backwards on the way
// there.
//
// Usage:
//   dart run tool/check_coverage.dart [--report=coverage/lcov.info] [--floor=41]
//
// Generated sources (*.g.dart, *.freezed.dart, *.mocks.dart) are excluded
// from the measured percentage - see tool/coverage/lcov_summary.dart and
// README.md's Coverage section for why.
import 'dart:io';

import 'coverage/lcov_summary.dart';

Future<void> main(List<String> arguments) async {
  final options = _Options.parse(arguments);

  final reportFile = File(options.reportPath);
  if (!reportFile.existsSync()) {
    stderr.writeln(
      'Coverage report not found at ${options.reportPath}. Run '
      "'flutter test --coverage' first.",
    );
    exitCode = 1;
    return;
  }

  final report = await reportFile.readAsString();
  final summary = parseLcov(report);
  final floor = options.floor ?? await _readFloor();
  final check = evaluate(summary, floor);

  stdout.writeln(
    'Coverage: ${summary.percentage.toStringAsFixed(1)}% '
    '(${summary.hitLines}/${summary.totalLines} lines, '
    '${summary.files.length} files, floor $floor%)',
  );
  if (summary.malformedLines > 0) {
    stdout.writeln(
      'Warning: ${summary.malformedLines} DA record(s) in the report could '
      'not be parsed and were skipped.',
    );
  }

  final missing = _libFilesMissingFromReport(summary.files);
  if (missing.isNotEmpty) {
    stdout.writeln(
      '${missing.length} of ${missing.length + summary.files.length} '
      'lib/ files were never loaded by any test and are absent from the '
      'report (lcov only records files the VM actually imported) - the '
      'percentage above is therefore optimistic, not exact.',
    );
  }

  stdout.writeln(check.message);
  if (!check.passed) {
    exitCode = 1;
  }
}

Future<int> _readFloor() async {
  final floorFile = File('tool/coverage_floor.txt');
  final contents = await floorFile.readAsString();
  return int.parse(contents.trim());
}

/// `lib/` files (excluding generated sources) that never appear in the
/// lcov report at all, because no test imported them.
List<String> _libFilesMissingFromReport(List<String> reportedFiles) {
  final reported = reportedFiles.map(_normalize).toSet();
  final missing = <String>[];

  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    return missing;
  }

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final path = _normalize(entity.path);
    if (!excludeGenerated(path)) {
      continue;
    }
    final isReported = reported.any(
      (reportedPath) => reportedPath.endsWith(path),
    );
    if (!isReported) {
      missing.add(path);
    }
  }
  return missing;
}

String _normalize(String path) => path.replaceAll('\\', '/');

class _Options {
  _Options({required this.reportPath, this.floor});

  final String reportPath;
  final int? floor;

  static _Options parse(List<String> arguments) {
    var reportPath = 'coverage/lcov.info';
    int? floor;
    for (final argument in arguments) {
      if (argument.startsWith('--report=')) {
        reportPath = argument.substring('--report='.length);
      } else if (argument.startsWith('--floor=')) {
        floor = int.parse(argument.substring('--floor='.length));
      }
    }
    return _Options(reportPath: reportPath, floor: floor);
  }
}
