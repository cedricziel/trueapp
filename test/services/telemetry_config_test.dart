import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/services/telemetry_config.dart';

void main() {
  group('TelemetryConfig.parseHeaders', () {
    test('parses a single key=value pair', () {
      expect(TelemetryConfig.parseHeaders('x-api-key=secret'), {
        'x-api-key': 'secret',
      });
    });

    test('parses multiple comma-separated pairs', () {
      expect(
        TelemetryConfig.parseHeaders(
          'authorization=Bearer abc,x-tenant-id=homelab,x-dataset-id=apps',
        ),
        {
          'authorization': 'Bearer abc',
          'x-tenant-id': 'homelab',
          'x-dataset-id': 'apps',
        },
      );
    });

    test(
      'splits each pair on the first "=" only, keeping later "="s in the value',
      () {
        expect(TelemetryConfig.parseHeaders('authorization=Bearer a=b=c'), {
          'authorization': 'Bearer a=b=c',
        });
      },
    );

    test('trims whitespace around keys, values, and pairs', () {
      expect(TelemetryConfig.parseHeaders(' key1 = value1 , key2 = value2 '), {
        'key1': 'value1',
        'key2': 'value2',
      });
    });

    test('returns an empty map for an empty string', () {
      expect(TelemetryConfig.parseHeaders(''), isEmpty);
    });

    test('skips blank entries from stray commas', () {
      expect(TelemetryConfig.parseHeaders('key1=value1,,key2=value2,'), {
        'key1': 'value1',
        'key2': 'value2',
      });
    });

    test('skips entries with no "=" separator', () {
      expect(
        TelemetryConfig.parseHeaders('key1=value1,not-a-pair,key2=value2'),
        {'key1': 'value1', 'key2': 'value2'},
      );
    });

    test('skips entries with an empty key', () {
      expect(TelemetryConfig.parseHeaders('=value,key=value2'), {
        'key': 'value2',
      });
    });

    test('allows an empty value', () {
      expect(TelemetryConfig.parseHeaders('key='), {'key': ''});
    });
  });

  group('TelemetryConfig.enabled', () {
    test('is false when otlpEndpoint is empty', () {
      const config = TelemetryConfig(
        otlpEndpoint: '',
        otlpHeaders: {},
        serviceName: 'truehub',
        deploymentEnvironment: 'development',
      );

      expect(config.enabled, isFalse);
    });

    test('is true when otlpEndpoint is non-empty', () {
      const config = TelemetryConfig(
        otlpEndpoint: 'https://collector.example.com',
        otlpHeaders: {},
        serviceName: 'truehub',
        deploymentEnvironment: 'development',
      );

      expect(config.enabled, isTrue);
    });
  });

  group('TelemetryConfig.fromEnvironment', () {
    test('falls back to documented defaults when no --dart-define is set', () {
      // The test runner is not invoked with any of these dart-defines, so
      // this exercises the actual compiled-in default values.
      final config = TelemetryConfig.fromEnvironment();

      expect(config.otlpEndpoint, isEmpty);
      expect(config.otlpHeaders, isEmpty);
      expect(config.serviceName, 'truehub');
      expect(config.deploymentEnvironment, 'development');
      expect(config.enabled, isFalse);
    });
  });
}
