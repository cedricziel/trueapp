import 'package:flutter_test/flutter_test.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/services/truenas_api_client.dart';

void main() {
  group('TrueNasApiClient Keepalive', () {
    late TrueNasApiClient apiClient;
    late NasServer testServer;

    setUp(() {
      testServer = NasServer(
        id: 'test-server',
        name: 'Test Server',
        host: 'localhost',
        port: 80,
        useHttps: false,
        username: 'test',
        password: 'test',
        localUrl: null,
        trustedWifiSsids: [],
        isDefault: false,
      );
      apiClient = TrueNasApiClient(testServer);
    });

    tearDown(() async {
      await apiClient.close();
    });

    test('should enable and disable keepalive', () {
      // Initially keepalive should be enabled by default
      expect(
        apiClient.isKeepaliveActive,
        false,
      ); // Not active until authenticated

      // Disable keepalive
      apiClient.enableKeepalive(false);
      expect(apiClient.isKeepaliveActive, false);

      // Re-enable keepalive
      apiClient.enableKeepalive(true);
      expect(
        apiClient.isKeepaliveActive,
        false,
      ); // Still not active until authenticated
    });

    test('should set keepalive interval', () {
      const newInterval = Duration(seconds: 30);

      // This should not throw
      apiClient.setKeepaliveInterval(newInterval);

      // Verify the interval was set (can't directly test private field, but method should execute)
      expect(
        () => apiClient.setKeepaliveInterval(newInterval),
        returnsNormally,
      );
    });

    test('should handle keepalive state correctly', () {
      // Test initial state
      expect(apiClient.isKeepaliveActive, false);

      // Test enabling/disabling
      apiClient.enableKeepalive(false);
      apiClient.enableKeepalive(true);

      // Should not crash
      expect(apiClient.isKeepaliveActive, false);
    });
  });
}
