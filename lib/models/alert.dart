import 'package:equatable/equatable.dart';

/// The severity TrueNAS reports for an alert, coarsened from its raw
/// `level` string (INFO/NOTICE, WARNING, ERROR, CRITICAL/ALERT/EMERGENCY).
enum AlertLevel { info, warning, error, critical, unknown }

AlertLevel _parseLevel(String? raw) {
  switch (raw?.toUpperCase()) {
    case 'INFO':
    case 'NOTICE':
      return AlertLevel.info;
    case 'WARNING':
      return AlertLevel.warning;
    case 'ERROR':
      return AlertLevel.error;
    case 'CRITICAL':
    case 'ALERT':
    case 'EMERGENCY':
      return AlertLevel.critical;
    default:
      return AlertLevel.unknown;
  }
}

/// TrueNAS represents an alert's time as `{"$date": <millis>}`, a bare
/// millis int, or (in some middleware versions) an ISO string - accept all
/// three rather than crashing on whichever this server sends.
DateTime? _parseAlertDateTime(dynamic raw) {
  if (raw is Map) {
    final millis = raw[r'$date'];
    if (millis is int) return DateTime.fromMillisecondsSinceEpoch(millis);
  }
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  if (raw is String) return DateTime.tryParse(raw);
  return null;
}

/// A system alert as returned by the TrueNAS `alert.list` API.
class Alert extends Equatable {
  final String id;
  final AlertLevel level;
  final String message;
  final DateTime? occurredAt;
  final bool dismissed;

  const Alert({
    required this.id,
    required this.level,
    required this.message,
    this.occurredAt,
    this.dismissed = false,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['uuid'] as String? ?? json['id']?.toString() ?? '',
      level: _parseLevel(json['level'] as String?),
      message:
          json['formatted'] as String? ?? json['text'] as String? ?? 'Alert',
      occurredAt: _parseAlertDateTime(
        json['datetime'] ?? json['last_occurrence'],
      ),
      dismissed: json['dismissed'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, level, message, occurredAt, dismissed];
}
