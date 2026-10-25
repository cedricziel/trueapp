import 'package:equatable/equatable.dart';
import 'package:truehub/models/job.dart' show parseTrueNasDateTime;

enum PoolScanFunction { scrub, resilver, unknown }

enum PoolScanState { scanning, finished, canceled, unknown }

PoolScanFunction _parseFunction(Object? raw) =>
    switch (raw is String ? raw.toUpperCase() : null) {
      'SCRUB' => PoolScanFunction.scrub,
      'RESILVER' => PoolScanFunction.resilver,
      _ => PoolScanFunction.unknown,
    };

PoolScanState _parseState(Object? raw) =>
    switch (raw is String ? raw.toUpperCase() : null) {
      'SCANNING' => PoolScanState.scanning,
      'FINISHED' => PoolScanState.finished,
      'CANCELED' => PoolScanState.canceled,
      _ => PoolScanState.unknown,
    };

num? _asNum(Object? raw) => raw is num ? raw : null;

/// The `scan` object of a `pool.query` result: the running, or most recently
/// finished, scrub or resilver of a pool.
///
/// Every field is optional on the wire (the middleware sends `null` for the
/// ones that do not apply yet), so each is parsed defensively.
class PoolScan extends Equatable {
  final PoolScanFunction function;
  final PoolScanState state;

  /// Percent complete as reported by the middleware, 0 to 100.
  final double? percentage;
  final int? bytesToProcess;
  final int? bytesIssued;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isPaused;
  final int errors;

  /// The middleware's own estimate; see [timeLeft] for the one to display.
  final int? totalSecsLeft;

  const PoolScan({
    required this.function,
    required this.state,
    this.percentage,
    this.bytesToProcess,
    this.bytesIssued,
    this.startTime,
    this.endTime,
    this.isPaused = false,
    this.errors = 0,
    this.totalSecsLeft,
  });

  /// Parses [raw], returning null when it holds no scan: a missing or empty
  /// object, or the all-null one the middleware sends for a pool that has
  /// never been scanned.
  static PoolScan? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final json = raw.cast<String, dynamic>();
    if (json['function'] == null && json['state'] == null) return null;

    return PoolScan(
      function: _parseFunction(json['function']),
      state: _parseState(json['state']),
      percentage: _asNum(json['percentage'])?.toDouble(),
      bytesToProcess: _asNum(json['bytes_to_process'])?.toInt(),
      bytesIssued: _asNum(json['bytes_issued'])?.toInt(),
      startTime: parseTrueNasDateTime(json['start_time']),
      endTime: parseTrueNasDateTime(json['end_time']),
      isPaused: json['pause'] != null,
      errors: _asNum(json['errors'])?.toInt() ?? 0,
      totalSecsLeft: _asNum(json['total_secs_left'])?.toInt(),
    );
  }

  bool get isRunning => state == PoolScanState.scanning;

  /// Completion in the range 0..1, derived from the issued bytes when the
  /// middleware sent no percentage; null when neither is known.
  double? get fraction {
    final percent = percentage;
    if (percent != null) return (percent / 100).clamp(0.0, 1.0);
    final issued = bytesIssued;
    final total = bytesToProcess;
    if (issued == null || total == null || total <= 0) return null;
    return (issued / total).clamp(0.0, 1.0);
  }

  /// How long a finished or canceled scan ran.
  Duration? get duration {
    final start = startTime;
    final end = endTime;
    if (start == null || end == null) return null;
    return end.difference(start);
  }

  /// Average throughput since the scan started, or null when the scan is not
  /// actively progressing or too little has happened to measure.
  double? bytesPerSecond(DateTime now) {
    final start = startTime;
    final issued = bytesIssued;
    if (!isRunning || isPaused || start == null) return null;
    if (issued == null || issued <= 0) return null;
    final elapsedSeconds = now.difference(start).inMilliseconds / 1000;
    if (elapsedSeconds <= 0) return null;
    return issued / elapsedSeconds;
  }

  /// Estimated time until the scan completes: the middleware's estimate when
  /// it sent one, otherwise extrapolated from [bytesPerSecond].
  Duration? timeLeft(DateTime now) {
    if (!isRunning || isPaused) return null;
    final reported = totalSecsLeft;
    if (reported != null) return Duration(seconds: reported);

    final speed = bytesPerSecond(now);
    final issued = bytesIssued;
    final total = bytesToProcess;
    if (speed == null || issued == null || total == null) return null;
    final remaining = total - issued;
    if (remaining <= 0) return Duration.zero;
    return Duration(seconds: (remaining / speed).round());
  }

  @override
  List<Object?> get props => [
    function,
    state,
    percentage,
    bytesToProcess,
    bytesIssued,
    startTime,
    endTime,
    isPaused,
    errors,
    totalSecsLeft,
  ];
}
