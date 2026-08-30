import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/services/telemetry_bootstrap.dart';
import 'package:truehub/services/telemetry_config.dart';
import 'package:truehub/services/telemetry_service_interface.dart';

import '../helpers/fake_telemetry_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const disabledConfig = TelemetryConfig(
    otlpEndpoint: '',
    otlpHeaders: {},
    serviceName: 'truehub-test',
    deploymentEnvironment: 'test',
  );

  // FlutterError.onError and PlatformDispatcher.instance.onError are global
  // mutable state - restore whatever was installed before each test so
  // bootstrapTelemetry's wiring in one test can't leak into another.
  late FlutterExceptionHandler? originalFlutterOnError;
  late ErrorCallback? originalPlatformOnError;

  setUp(() {
    originalFlutterOnError = FlutterError.onError;
    originalPlatformOnError = PlatformDispatcher.instance.onError;
  });

  tearDown(() {
    FlutterError.onError = originalFlutterOnError;
    PlatformDispatcher.instance.onError = originalPlatformOnError;
  });

  group('bootstrapTelemetry', () {
    test('returns the service produced by the injected initializer', () async {
      final fake = FakeTelemetryService();

      final result = await bootstrapTelemetry(
        config: disabledConfig,
        initializeService: (config) async => fake,
      );

      expect(result, isA<TelemetryServiceInterface>());
      expect(result, same(fake));
    });

    test('a fatal platform error records it and flushes telemetry before '
        'forwarding to the previously-registered handler', () async {
      final fake = FakeTelemetryService();
      var previousHandlerCalled = false;
      PlatformDispatcher.instance.onError = (error, stack) {
        previousHandlerCalled = true;
        return true;
      };

      await bootstrapTelemetry(
        config: disabledConfig,
        initializeService: (config) async => fake,
      );

      final error = Exception('fatal platform error');
      final stack = StackTrace.current;
      final handled = PlatformDispatcher.instance.onError!(error, stack);

      expect(fake.recordedErrors, hasLength(1));
      final recorded = fake.recordedErrors.single;
      expect(recorded.error, same(error));
      expect(recorded.fatal, isTrue);
      expect(recorded.context, 'PlatformDispatcher.instance.onError');

      // flush() is fire-and-forget (unawaited) so the process can exit
      // right after onError returns per Flutter's docs - but it must
      // still have been invoked synchronously before that return.
      expect(fake.flushCount, 1);

      expect(previousHandlerCalled, isTrue);
      expect(handled, isTrue);
    });

    test('a FlutterError.onError call does not trigger a flush', () async {
      final fake = FakeTelemetryService();

      await bootstrapTelemetry(
        config: disabledConfig,
        initializeService: (config) async => fake,
      );

      FlutterError.onError!(
        FlutterErrorDetails(exception: Exception('widget build error')),
      );

      expect(fake.recordedErrors, hasLength(1));
      expect(fake.recordedErrors.single.fatal, isFalse);
      expect(fake.flushCount, 0);
    });
  });
}
