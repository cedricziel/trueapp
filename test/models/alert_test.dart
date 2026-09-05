import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/alert.dart';

void main() {
  group('Alert.fromJson', () {
    test(r'parses a critical alert with a $date-shaped datetime', () {
      final alert = Alert.fromJson({
        'uuid': 'abc-123',
        'level': 'CRITICAL',
        'formatted': 'Pool "tank" is degraded',
        'datetime': {r'$date': 1735689600000},
        'dismissed': false,
      });

      expect(alert.id, 'abc-123');
      expect(alert.level, AlertLevel.critical);
      expect(alert.message, 'Pool "tank" is degraded');
      expect(
        alert.occurredAt,
        DateTime.fromMillisecondsSinceEpoch(1735689600000),
      );
      expect(alert.dismissed, isFalse);
    });

    test('falls back to text when formatted is absent', () {
      final alert = Alert.fromJson({
        'id': 42,
        'level': 'WARNING',
        'text': 'Disk temperature high',
      });

      expect(alert.id, '42');
      expect(alert.level, AlertLevel.warning);
      expect(alert.message, 'Disk temperature high');
    });

    test(
      'maps NOTICE and INFO to AlertLevel.info, and an unknown level safely',
      () {
        expect(Alert.fromJson({'level': 'NOTICE'}).level, AlertLevel.info);
        expect(Alert.fromJson({'level': 'INFO'}).level, AlertLevel.info);
        expect(
          Alert.fromJson({'level': 'SOMETHING_NEW'}).level,
          AlertLevel.unknown,
        );
      },
    );

    test('parses a bare millisecond int and an ISO string datetime', () {
      final fromMillis = Alert.fromJson({'datetime': 1735689600000});
      final fromIso = Alert.fromJson({'datetime': '2025-01-01T00:00:00.000Z'});

      expect(fromMillis.occurredAt, isNotNull);
      expect(fromIso.occurredAt, isNotNull);
    });

    test('defaults to an empty, unknown-level alert for missing fields', () {
      final alert = Alert.fromJson(const {});

      expect(alert.id, '');
      expect(alert.level, AlertLevel.unknown);
      expect(alert.message, 'Alert');
      expect(alert.occurredAt, isNull);
      expect(alert.dismissed, isFalse);
    });
  });
}
