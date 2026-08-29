/// Pure parsing and threshold logic for lcov coverage reports.
///
/// Deliberately free of `dart:io` so it can be exercised directly by
/// `flutter test` (see test/tool/lcov_summary_test.dart) without touching
/// the filesystem; the shell that reads coverage/lcov.info and prints to
/// the console lives in tool/check_coverage.dart.
library;

/// Build-generated sources. They are excluded from the coverage number:
/// nobody writes tests against generated code, and including it makes the
/// figure say more about how much drift generates than about how much of
/// the hand-written app is actually tested.
const generatedSuffixes = <String>['.g.dart', '.freezed.dart', '.mocks.dart'];

/// Decides whether a source file's `DA:` lines should count toward the
/// summary. Receives the raw `SF:` path exactly as lcov wrote it (which may
/// be relative or absolute).
typedef PathFilter = bool Function(String path);

/// The default [PathFilter]: keep everything except generated sources.
bool excludeGenerated(String path) =>
    !generatedSuffixes.any((suffix) => path.endsWith(suffix));

/// Aggregated result of parsing an lcov report.
class LcovSummary {
  const LcovSummary({
    required this.hitLines,
    required this.totalLines,
    required this.files,
    required this.malformedLines,
  });

  /// Number of `DA:` lines with a hit count greater than zero, across all
  /// records that survived [PathFilter].
  final int hitLines;

  /// Number of `DA:` lines across all records that survived [PathFilter].
  final int totalLines;

  /// Source paths of every included record, in report order - even ones
  /// with no `DA:` lines at all.
  final List<String> files;

  /// Number of `DA:` lines that could not be parsed and were skipped.
  final int malformedLines;

  /// True when no record survived filtering (or the report was empty).
  bool get isEmpty => totalLines == 0;

  /// Coverage percentage, `0` when [isEmpty] rather than dividing by zero.
  double get percentage => totalLines == 0 ? 0 : hitLines * 100 / totalLines;
}

/// Parses an lcov [report] into an [LcovSummary].
///
/// Only `SF:`, `DA:` and `end_of_record` lines are interpreted; everything
/// else (`FN:`, `FNDA:`, `BRDA:`, `LF:`, `LH:`, blank lines) is ignored.
/// Line totals are derived from `DA:` records rather than trusting the
/// `LF:`/`LH:` summary lines lcov also emits, which keeps the parser
/// self-consistent.
///
/// A `DA:` line that fails to parse is skipped and counted in
/// [LcovSummary.malformedLines] rather than thrown - one bad line should
/// not sink the whole report.
LcovSummary parseLcov(String report, {PathFilter include = excludeGenerated}) {
  var hitLines = 0;
  var totalLines = 0;
  var malformedLines = 0;
  final files = <String>[];

  String? currentPath;
  var currentIncluded = false;

  for (final rawLine in report.split('\n')) {
    final line = rawLine.trim();
    if (line.startsWith('SF:')) {
      currentPath = line.substring(3);
      currentIncluded = include(currentPath);
      if (currentIncluded) {
        files.add(currentPath);
      }
    } else if (line.startsWith('DA:')) {
      if (!currentIncluded) {
        continue;
      }
      final fields = line.substring(3).split(',');
      if (fields.length < 2) {
        malformedLines++;
        continue;
      }
      final lineNumber = int.tryParse(fields[0]);
      final hitCount = int.tryParse(fields[1]);
      if (lineNumber == null || hitCount == null) {
        malformedLines++;
        continue;
      }
      totalLines++;
      if (hitCount > 0) {
        hitLines++;
      }
    } else if (line == 'end_of_record') {
      currentPath = null;
      currentIncluded = false;
    }
  }

  return LcovSummary(
    hitLines: hitLines,
    totalLines: totalLines,
    files: files,
    malformedLines: malformedLines,
  );
}

/// Result of comparing an [LcovSummary] against a floor percentage.
class CoverageCheck {
  const CoverageCheck({required this.passed, required this.message});

  final bool passed;
  final String message;
}

/// Ratchet check: this is a floor that only ever moves up as coverage
/// improves, not a fixed 80% gate - see tool/check_coverage.dart for the
/// policy. The comparison is inclusive, so a run that lands exactly on the
/// floor passes.
CoverageCheck evaluate(LcovSummary summary, int floorPercent) {
  if (summary.isEmpty) {
    return const CoverageCheck(
      passed: false,
      message:
          'Coverage report has no measurable lines after filtering - the '
          'coverage run may have produced no data. Failing rather than '
          'reporting a false pass.',
    );
  }

  final percentage = summary.percentage;
  if (percentage >= floorPercent) {
    return CoverageCheck(
      passed: true,
      message:
          'Coverage ${percentage.toStringAsFixed(1)}% meets the floor of '
          '$floorPercent%.',
    );
  }

  return CoverageCheck(
    passed: false,
    message:
        'Coverage ${percentage.toStringAsFixed(1)}% is below the floor of '
        '$floorPercent%.',
  );
}
