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

    // tearDown removed - no real connections to close in these tests

    test('should create client with server configuration', () {
      expect(client, isNotNull);
    });

    // Note: Network tests are skipped for now - we need a mock server for proper testing
    // TODO: Add mock WebSocket server tests for validateLogin and testConnection

    test('should construct WebSocket URL correctly', () {
      final httpServer = NasServer.create(
        name: 'HTTP Server',
        host: '192.168.1.100',
        port: 80,
        username: 'admin',
        password: 'pass',
        useHttps: false,
      );

      final httpsServer = NasServer.create(
        name: 'HTTPS Server',
        host: '192.168.1.100',
        port: 443,
        username: 'admin',
        password: 'pass',
        useHttps: true,
      );

      // We can't directly test the WebSocket URL construction without exposing it,
      // but we can verify the base URL is correct
      expect(httpServer.baseUrl, 'http://192.168.1.100:80');
      expect(httpsServer.baseUrl, 'https://192.168.1.100:443');
    });
  });
}
