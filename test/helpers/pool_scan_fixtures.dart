import 'package:truehub/models/pool_scan.dart';

/// TrueNAS encodes datetimes as `{"$date": <epoch ms>}`.
Map<String, int> truenasDate(DateTime value) => {
  r'$date': value.millisecondsSinceEpoch,
};

/// When the scans built by [poolScanJson] started, unless overridden.
final poolScanStart = DateTime.utc(2026, 10, 1, 12).toLocal();

const _defaultStart = Object();

/// A `pool.query` `scan` object. Defaults describe a scrub at 25%; override
/// individual fields (including with an explicit `null`, as the middleware
/// sends for fields that do not apply) per test. A scan started at
/// [poolScanStart] unless [startTime] says otherwise.
Map<String, dynamic> poolScanJson({
  String? function = 'SCRUB',
  String? state = 'SCANNING',
  Object? percentage = 25.0,
  Object? bytesToProcess = 1000,
  Object? bytesProcessed = 300,
  Object? bytesIssued = 250,
  Object? startTime = _defaultStart,
  Object? endTime,
  Object? pause,
  Object? errors = 0,
  Object? totalSecsLeft,
}) => {
  'function': function,
  'state': state,
  'start_time': identical(startTime, _defaultStart)
      ? truenasDate(poolScanStart)
      : startTime,
  'end_time': endTime,
  'percentage': percentage,
  'bytes_to_process': bytesToProcess,
  'bytes_processed': bytesProcessed,
  'bytes_issued': bytesIssued,
  'pause': pause,
  'errors': errors,
  'total_secs_left': totalSecsLeft,
};

/// [poolScanJson] parsed into a [PoolScan].
PoolScan poolScan({
  String? function = 'SCRUB',
  String? state = 'SCANNING',
  Object? percentage = 25.0,
  Object? bytesToProcess = 1000,
  Object? bytesIssued = 250,
  Object? startTime = _defaultStart,
  Object? endTime,
  Object? pause,
  Object? errors = 0,
  Object? totalSecsLeft,
}) => PoolScan.tryParse(
  poolScanJson(
    function: function,
    state: state,
    percentage: percentage,
    bytesToProcess: bytesToProcess,
    bytesIssued: bytesIssued,
    startTime: startTime,
    endTime: endTime,
    pause: pause,
    errors: errors,
    totalSecsLeft: totalSecsLeft,
  ),
)!;
