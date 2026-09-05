import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/service_status.dart';

void main() {
  group('ServiceStatus.fromJson', () {
    test('parses a running, enabled service and maps its display name', () {
      final service = ServiceStatus.fromJson({
        'service': 'cifs',
        'state': 'RUNNING',
        'enable': true,
      });

      expect(service.id, 'cifs');
      expect(service.isRunning, isTrue);
      expect(service.isEnabled, isTrue);
      expect(service.displayName, 'SMB');
    });

    test('parses a stopped service', () {
      final service = ServiceStatus.fromJson({
        'service': 'rsync',
        'state': 'STOPPED',
        'enable': false,
      });

      expect(service.isRunning, isFalse);
      expect(service.displayName, 'Rsync');
    });

    test('upper-cases an unmapped service id rather than failing', () {
      final service = ServiceStatus.fromJson({
        'service': 'some_future_service',
        'state': 'RUNNING',
      });

      expect(service.displayName, 'SOME_FUTURE_SERVICE');
    });

    test('defaults to a stopped, unknown service for missing fields', () {
      final service = ServiceStatus.fromJson(const {});

      expect(service.id, 'unknown');
      expect(service.isRunning, isFalse);
      expect(service.isEnabled, isFalse);
    });
  });
}
