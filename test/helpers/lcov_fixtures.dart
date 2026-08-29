/// Small builders for well-formed-ish lcov fragments, so coverage-parser
/// tests read as data instead of a wall of embedded strings.
library;

/// One `SF:`...`end_of_record` block for [path], with one `DA:` line per
/// entry in [hits] (line numbers start at 1). Pass raw lines instead via
/// [extraLines] when a test needs something the DA-only shorthand can't
/// express (a checksum field, a malformed line, no DA lines at all).
String lcovRecord(
  String path, {
  List<int> hits = const [],
  List<String> extraLines = const [],
}) {
  final buffer = StringBuffer('SF:$path\n');
  for (var i = 0; i < hits.length; i++) {
    buffer.writeln('DA:${i + 1},${hits[i]}');
  }
  for (final line in extraLines) {
    buffer.writeln(line);
  }
  buffer.writeln('end_of_record');
  return buffer.toString();
}

/// Joins whole records (or any raw lcov fragments) into one report.
String lcovReport(Iterable<String> records) => records.join();
