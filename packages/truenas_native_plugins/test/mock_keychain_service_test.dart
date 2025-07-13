import 'package:flutter_test/flutter_test.dart';
import 'package:truenas_native_plugins/truenas_native_plugins.dart';

void main() {
  group('MockKeychainService', () {
    late MockKeychainService mockKeychain;

    setUp(() {
      mockKeychain = MockKeychainService();
    });

    group('Password Storage', () {
      test('should store and retrieve passwords', () async {
        const serverId = 'test-server-id';
        const password = 'test-password';

        // Store password
        final storeResult = await mockKeychain.storePassword(
          serverId: serverId,
          password: password,
        );
        expect(storeResult, isTrue);

        // Retrieve password
        final retrievedPassword = await mockKeychain.getPassword(
          serverId: serverId,
        );
        expect(retrievedPassword, equals(password));
      });

      test('should return null for non-existent passwords', () async {
        final password = await mockKeychain.getPassword(
          serverId: 'non-existent',
        );
        expect(password, isNull);
      });

      test('should delete passwords', () async {
        const serverId = 'test-server-id';
        const password = 'test-password';

        // Store password
        await mockKeychain.storePassword(
          serverId: serverId,
          password: password,
        );

        // Delete password
        final deleteResult = await mockKeychain.deletePassword(
          serverId: serverId,
        );
        expect(deleteResult, isTrue);

        // Verify it's gone
        final retrievedPassword = await mockKeychain.getPassword(
          serverId: serverId,
        );
        expect(retrievedPassword, isNull);
      });

      test('should check if password exists', () async {
        const serverId = 'test-server-id';
        const password = 'test-password';

        // Initially should not exist
        expect(await mockKeychain.hasPassword(serverId: serverId), isFalse);

        // Store password
        await mockKeychain.storePassword(
          serverId: serverId,
          password: password,
        );

        // Now should exist
        expect(await mockKeychain.hasPassword(serverId: serverId), isTrue);
      });
    });

    group('Batch Operations', () {
      test('should get all server IDs', () async {
        const serverIds = ['server1', 'server2', 'server3'];

        // Store passwords for multiple servers
        for (final serverId in serverIds) {
          await mockKeychain.storePassword(
            serverId: serverId,
            password: 'password-$serverId',
          );
        }

        final retrievedIds = await mockKeychain.getAllServerIds();
        expect(retrievedIds, unorderedEquals(serverIds));
      });

      test('should delete all passwords', () async {
        // Store multiple passwords
        await mockKeychain.storePassword(
          serverId: 'server1',
          password: 'password1',
        );
        await mockKeychain.storePassword(
          serverId: 'server2',
          password: 'password2',
        );

        // Delete all
        final deleteResult = await mockKeychain.deleteAllPasswords();
        expect(deleteResult, isTrue);

        // Verify all are gone
        final serverIds = await mockKeychain.getAllServerIds();
        expect(serverIds, isEmpty);
      });
    });

    group('Test Helpers', () {
      test('should fail operations when configured', () async {
        mockKeychain.setShouldFailOperations(true);

        // All operations should fail
        expect(
          await mockKeychain.storePassword(
            serverId: 'test',
            password: 'test',
          ),
          isFalse,
        );
        expect(
          await mockKeychain.getPassword(serverId: 'test'),
          isNull,
        );
        expect(
          await mockKeychain.deletePassword(serverId: 'test'),
          isFalse,
        );
        expect(
          await mockKeychain.hasPassword(serverId: 'test'),
          isFalse,
        );
        expect(
          await mockKeychain.getAllServerIds(),
          isEmpty,
        );
        expect(
          await mockKeychain.deleteAllPasswords(),
          isFalse,
        );
      });

      test('should add delay when configured', () async {
        mockKeychain.setOperationDelay(100);

        final stopwatch = Stopwatch()..start();
        await mockKeychain.storePassword(
          serverId: 'test',
          password: 'test',
        );
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(90));
      });

      test('should support direct password manipulation', () async {
        const serverId = 'test-server';
        const password = 'test-password';

        // Add password directly
        mockKeychain.addPassword(serverId, password);

        // Verify it can be retrieved
        final retrieved = await mockKeychain.getPassword(serverId: serverId);
        expect(retrieved, equals(password));

        // Test helper methods
        expect(mockKeychain.passwordCount, equals(1));
        expect(mockKeychain.hasStoredPassword(serverId), isTrue);
        expect(mockKeychain.getStoredPassword(serverId), equals(password));

        // Clear passwords
        mockKeychain.clearPasswords();
        expect(mockKeychain.passwordCount, equals(0));
      });

      test('should provide access to all passwords', () async {
        const passwords = {
          'server1': 'password1',
          'server2': 'password2',
          'server3': 'password3',
        };

        // Add passwords
        for (final entry in passwords.entries) {
          mockKeychain.addPassword(entry.key, entry.value);
        }

        // Get all passwords
        final allPasswords = mockKeychain.allPasswords;
        expect(allPasswords, equals(passwords));
      });
    });
  });
}
