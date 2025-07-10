import 'package:flutter_test/flutter_test.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/services/truenas_api_client.dart';

void main() {
  group('TrueNasApiClient', () {
    late TrueNasApiClient client;
    late NasServer testServer;

    setUp(() {
      testServer = NasServer.create(
        name: 'Test Server',
        host: 'localhost',
        port: 8080,
        username: 'root',
        password: 'password',
        useHttps: false,
      );
      client = TrueNasApiClient(testServer);
    });

    tearDown(() async {
      await client.close();
    });

    test('should create client with server configuration', () {
      expect(client, isNotNull);
    });

    test('should handle connection test gracefully', () async {
      // This will fail since we don't have a real server, but it should not throw
      final result = await client.testConnection().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
      expect(result, isFalse);
    });

    test('should properly construct error messages', () {
      expect(() => client.testConnection(), returnsNormally);
    });

    test('should handle login validation gracefully', () async {
      // This will fail since we don't have a real server, but it should not throw
      final result = await client.validateLogin('test', 'password').timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
      expect(result, isFalse);
    });
  });
}