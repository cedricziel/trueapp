import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/alert.dart';
import 'package:truehub/models/alert_event.dart';

void main() {
  group('AlertEvent.parse', () {
    test('reads an ADDED event into the new alert', () {
      final event = AlertEvent.parse(
        msg: 'ADDED',
        id: 'abc',
        fields: {'uuid': 'abc', 'level': 'CRITICAL', 'formatted': 'Pool down'},
      );

      expect(event!.type, AlertEventType.added);
      expect(event.id, 'abc');
      expect(event.alert!.message, 'Pool down');
      expect(event.alert!.level, AlertLevel.critical);
    });

    test('reads a lowercase CHANGED event', () {
      final event = AlertEvent.parse(
        msg: 'changed',
        id: 'abc',
        fields: {'uuid': 'abc', 'formatted': 'Pool down', 'dismissed': true},
      );

      expect(event!.type, AlertEventType.changed);
      expect(event.alert!.dismissed, isTrue);
    });

    test('a REMOVED event carries only the id', () {
      final event = AlertEvent.parse(msg: 'REMOVED', id: 'abc', fields: null);

      expect(event!.type, AlertEventType.removed);
      expect(event.id, 'abc');
      expect(event.alert, isNull);
    });

    test('takes the id from the event when the fields lack one', () {
      final event = AlertEvent.parse(
        msg: 'ADDED',
        id: 'abc',
        fields: {'formatted': 'Pool down'},
      );

      expect(event!.alert!.id, 'abc');
    });

    test('ignores unknown message types and unusable payloads', () {
      expect(AlertEvent.parse(msg: 'WAT', id: 'a', fields: {}), isNull);
      expect(AlertEvent.parse(msg: null, id: 'a', fields: {}), isNull);
      expect(AlertEvent.parse(msg: 'ADDED', id: 'a', fields: null), isNull);
      expect(AlertEvent.parse(msg: 'ADDED', id: null, fields: {}), isNull);
      expect(AlertEvent.parse(msg: 'REMOVED', id: null, fields: null), isNull);
    });
  });
}
