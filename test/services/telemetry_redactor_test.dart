import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/services/telemetry_redactor.dart';

void main() {
  group('telemetryRedactor', () {
    final redactor = telemetryRedactor();

    test('redacts TrueNAS API keys wherever they appear', () {
      final key = '3-${'aB9' * 21}x';

      expect(
        redactor.redact('auth.login_with_api_key failed for $key'),
        'auth.login_with_api_key failed for [REDACTED]',
      );
    });

    test('keeps server addresses and ordinary numbers', () {
      const message =
          'Connection to https://nas.local:443 failed after 3 retries (code 1-5)';

      expect(redactor.redact(message), message);
    });

    test('still applies the package defaults', () {
      expect(
        redactor.redact('auth.login rejected: password=hunter2'),
        'auth.login rejected: password=[REDACTED]',
      );
      expect(redactor.isSensitiveKey('authorization'), isTrue);
    });
  });
}
