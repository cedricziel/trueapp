import 'package:equatable/equatable.dart';
import 'package:truehub/models/alert.dart';

enum AlertEventType { added, changed, removed }

/// A change to the `alert.list` collection, as pushed by a TrueNAS
/// `collection_update` notification.
class AlertEvent extends Equatable {
  final AlertEventType type;
  final String id;

  /// The alert after the change; `null` for [AlertEventType.removed], which
  /// carries no fields.
  final Alert? alert;

  const AlertEvent({required this.type, required this.id, this.alert});

  /// Reads the `msg`, `id` and `fields` of a `collection_update` for
  /// `alert.list`. Returns `null` for an event it cannot interpret, so one
  /// malformed notification never disturbs the alerts already shown.
  static AlertEvent? parse({
    required String? msg,
    required Object? id,
    required Object? fields,
  }) {
    final type = switch (msg?.toLowerCase()) {
      'added' => AlertEventType.added,
      'changed' => AlertEventType.changed,
      'removed' => AlertEventType.removed,
      _ => null,
    };
    if (type == null) return null;

    final fieldMap = fields is Map ? fields.cast<String, dynamic>() : null;
    final eventId = id?.toString() ?? fieldMap?['uuid']?.toString();
    if (type == AlertEventType.removed) {
      return eventId == null ? null : AlertEvent(type: type, id: eventId);
    }
    if (fieldMap == null) return null;

    var alert = Alert.fromJson(fieldMap);
    if (alert.id.isEmpty && eventId != null) {
      alert = alert.copyWith(id: eventId);
    }
    if (alert.id.isEmpty) return null;
    return AlertEvent(type: type, id: alert.id, alert: alert);
  }

  @override
  List<Object?> get props => [type, id, alert];
}
