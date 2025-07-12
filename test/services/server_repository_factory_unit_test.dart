import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/services/server_repository_factory.dart';

void main() {
  group('ServerRepositoryFactory Unit Tests', () {
    setUp(() async {
      await ServerRepositoryFactory.reset();
    });

    tearDown(() async {
      await ServerRepositoryFactory.reset();
    });

    test('should detect CloudKit support correctly', () {
      final supportsCloudKit = ServerRepositoryFactory.supportsCloudKit;
      final expectedSupport = Platform.isIOS || Platform.isMacOS;

      expect(supportsCloudKit, equals(expectedSupport));
    });

    test('should provide singleton access pattern', () async {
      // Should throw before initialization
      expect(
        () => ServerRepositoryFactory.instance,
        throwsA(isA<StateError>()),
      );
    });

    test('should support factory reset', () async {
      await ServerRepositoryFactory.reset();

      // Should not throw
      expect(() => ServerRepositoryFactory.reset(), returnsNormally);
    });

    test('should detect platform correctly', () {
      // Test platform detection logic
      if (Platform.isIOS || Platform.isMacOS) {
        expect(ServerRepositoryFactory.supportsCloudKit, isTrue);
      } else {
        expect(ServerRepositoryFactory.supportsCloudKit, isFalse);
      }
    });
  });
}
