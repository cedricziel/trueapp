import 'package:equatable/equatable.dart';

/// Mirrors the `state` field of a TrueNAS `core.get_jobs` job record.
enum JobState { waiting, running, success, failed, aborted, held, unknown }

JobState _parseJobState(String? value) {
  switch (value) {
    case 'WAITING':
      return JobState.waiting;
    case 'RUNNING':
      return JobState.running;
    case 'SUCCESS':
      return JobState.success;
    case 'FAILED':
      return JobState.failed;
    case 'ABORTED':
      return JobState.aborted;
    case 'HELD':
      return JobState.held;
    default:
      return JobState.unknown;
  }
}

String _jobStateToJson(JobState state) {
  switch (state) {
    case JobState.waiting:
      return 'WAITING';
    case JobState.running:
      return 'RUNNING';
    case JobState.success:
      return 'SUCCESS';
    case JobState.failed:
      return 'FAILED';
    case JobState.aborted:
      return 'ABORTED';
    case JobState.held:
      return 'HELD';
    case JobState.unknown:
      return 'UNKNOWN';
  }
}

/// TrueNAS encodes `datetime` fields as `{"$date": <epoch milliseconds>}`.
/// Accepts that shape defensively, plus a raw epoch-millisecond number or an
/// ISO 8601 string, since the exact wire shape depends on the middleware
/// version talking to the client.
DateTime? _parseTrueNasDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Map) {
    final millis = value[r'$date'];
    if (millis is num) {
      return DateTime.fromMillisecondsSinceEpoch(millis.toInt());
    }
    return null;
  }
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

dynamic _dateTimeToJson(DateTime? value) {
  if (value == null) return null;
  return {r'$date': value.millisecondsSinceEpoch};
}

/// The `progress` field of a TrueNAS job: percent complete plus an optional
/// human-readable description of the current step.
class JobProgress extends Equatable {
  final double percent;
  final String? description;

  const JobProgress({required this.percent, this.description});

  factory JobProgress.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const JobProgress(percent: 0);
    return JobProgress(
      percent: (json['percent'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'percent': percent,
    'description': description,
  };

  @override
  List<Object?> get props => [percent, description];
}

/// A TrueNAS job as returned by `core.get_jobs` / pushed through a
/// `core.get_jobs` collection_update subscription.
class Job extends Equatable {
  final int id;
  final String method;
  final List<dynamic> arguments;
  final String? description;
  final JobProgress progress;
  final JobState state;
  final DateTime? timeStarted;
  final DateTime? timeFinished;
  final String? error;
  final String? logsExcerpt;
  final bool abortable;

  const Job({
    required this.id,
    required this.method,
    required this.arguments,
    this.description,
    required this.progress,
    required this.state,
    this.timeStarted,
    this.timeFinished,
    this.error,
    this.logsExcerpt,
    this.abortable = false,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as int,
      method: json['method'] as String? ?? '',
      arguments: (json['arguments'] as List<dynamic>?) ?? const [],
      description: json['description'] as String?,
      progress: JobProgress.fromJson(json['progress'] as Map<String, dynamic>?),
      state: _parseJobState(json['state'] as String?),
      timeStarted: _parseTrueNasDateTime(json['time_started']),
      timeFinished: _parseTrueNasDateTime(json['time_finished']),
      error: json['error'] as String?,
      logsExcerpt: json['logs_excerpt'] as String?,
      abortable: json['abortable'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'method': method,
    'arguments': arguments,
    'description': description,
    'progress': progress.toJson(),
    'state': _jobStateToJson(state),
    'time_started': _dateTimeToJson(timeStarted),
    'time_finished': _dateTimeToJson(timeFinished),
    'error': error,
    'logs_excerpt': logsExcerpt,
    'abortable': abortable,
  };

  bool get isWaiting => state == JobState.waiting || state == JobState.held;
  bool get isRunning => state == JobState.running;
  bool get isFinished =>
      state == JobState.success ||
      state == JobState.failed ||
      state == JobState.aborted;
  bool get isFailed => state == JobState.failed;

  /// Time elapsed since the job started, through now if it hasn't finished
  /// yet. `null` if the job hasn't started (still queued).
  Duration? get elapsed {
    final started = timeStarted;
    if (started == null) return null;
    final end = timeFinished ?? DateTime.now();
    return end.difference(started);
  }

  @override
  List<Object?> get props => [
    id,
    method,
    arguments,
    description,
    progress,
    state,
    timeStarted,
    timeFinished,
    error,
    logsExcerpt,
    abortable,
  ];
}
