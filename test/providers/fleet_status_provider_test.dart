import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/fleet_server_status.dart';
import 'package:truehub/providers/fleet_status_provider.dart';
import 'package:truehub/services/database.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';

void main() {
  late AppDatabase database;
  late FleetStatusProvider provider;

  setUp(() async {
    database = createTestDatabase();
    final service = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    provider = FleetStatusProvider(service);
  });

  tearDown(() async {
    await TestProviders.disposeTestStack(
      providers: [provider],
      database: database,
    );
  });

  group('FleetStatusProvider', () {
    test('returns an unknown-connectivity status for an unseen server', () {
      final status = provider.statusFor('server-1');

      expect(status.connectivity, FleetServerConnectivity.unknown);
      expect(status.needsAttention, isFalse);
    });

    test('debugSetStatus seeds a status and notifies listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.debugSetStatus(
        const FleetServerStatus(
          serverId: 'server-1',
          connectivity: FleetServerConnectivity.online,
          cpuUsage: 42,
          storageUsage: 60,
        ),
      );

      expect(notified, isTrue);
      final status = provider.statusFor('server-1');
      expect(status.connectivity, FleetServerConnectivity.online);
      expect(status.cpuUsage, 42);
      expect(status.needsAttention, isFalse);
    });
  });

  group('FleetServerStatus.needsAttention', () {
    test('is true when offline', () {
      const status = FleetServerStatus(
        serverId: 's',
        connectivity: FleetServerConnectivity.offline,
      );
      expect(status.needsAttention, isTrue);
    });

    test('is true when online but with active alerts', () {
      const status = FleetServerStatus(
        serverId: 's',
        connectivity: FleetServerConnectivity.online,
        activeAlertCount: 2,
      );
      expect(status.needsAttention, isTrue);
    });

    test('is false when online with no active alerts', () {
      const status = FleetServerStatus(
        serverId: 's',
        connectivity: FleetServerConnectivity.online,
        activeAlertCount: 0,
      );
      expect(status.needsAttention, isFalse);
    });

    test('is false while unknown or loading', () {
      expect(const FleetServerStatus(serverId: 's').needsAttention, isFalse);
      expect(
        const FleetServerStatus(
          serverId: 's',
          connectivity: FleetServerConnectivity.loading,
        ).needsAttention,
        isFalse,
      );
    });
  });
}
