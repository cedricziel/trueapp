import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/server_health.dart';

void main() {
  group('DiskInfo', () {
    test('usagePercentage computes used/size as a percentage', () {
      const disk = DiskInfo(
        name: 'da0',
        model: 'Model',
        serial: 'ABC123',
        size: 1000,
        used: 250,
        temperature: 35,
        health: 'GOOD',
      );
      expect(disk.usagePercentage, equals(25.0));
    });

    test('usagePercentage guards against division by zero when size is 0', () {
      const disk = DiskInfo(
        name: 'da0',
        model: 'Model',
        serial: 'ABC123',
        size: 0,
        used: 0,
        temperature: 0,
        health: 'GOOD',
      );
      expect(disk.usagePercentage, equals(0.0));
    });

    test('equality holds for equal instances and differs on change', () {
      const a = DiskInfo(
        name: 'da0',
        model: 'Model',
        serial: 'ABC123',
        size: 1000,
        used: 250,
        temperature: 35,
        health: 'GOOD',
      );
      const b = DiskInfo(
        name: 'da0',
        model: 'Model',
        serial: 'ABC123',
        size: 1000,
        used: 250,
        temperature: 35,
        health: 'GOOD',
      );
      const c = DiskInfo(
        name: 'da0',
        model: 'Model',
        serial: 'ABC123',
        size: 1000,
        used: 999,
        temperature: 35,
        health: 'GOOD',
      );
      expect(a, equals(b));
      expect(a == c, isFalse);
    });
  });

  group('NetworkInfo', () {
    test('equality holds for equal instances and differs on change', () {
      const a = NetworkInfo(
        downloadSpeed: 100,
        uploadSpeed: 50,
        totalDownload: 1000,
        totalUpload: 500,
      );
      const b = NetworkInfo(
        downloadSpeed: 100,
        uploadSpeed: 50,
        totalDownload: 1000,
        totalUpload: 500,
      );
      const c = NetworkInfo(
        downloadSpeed: 200,
        uploadSpeed: 50,
        totalDownload: 1000,
        totalUpload: 500,
      );
      expect(a, equals(b));
      expect(a == c, isFalse);
    });
  });

  group('ServerHealth', () {
    ServerHealth buildHealth({double cpuUsage = 10.0}) => ServerHealth(
      serverId: 'server-1',
      timestamp: DateTime(2024, 1, 1),
      cpuUsage: cpuUsage,
      memoryUsage: 40.0,
      diskUsage: 55.0,
      temperature: 45,
      isOnline: true,
      disks: const [
        DiskInfo(
          name: 'da0',
          model: 'Model',
          serial: 'ABC123',
          size: 1000,
          used: 250,
          temperature: 35,
          health: 'GOOD',
        ),
      ],
      network: const NetworkInfo(
        downloadSpeed: 100,
        uploadSpeed: 50,
        totalDownload: 1000,
        totalUpload: 500,
      ),
    );

    test('holds constructor values', () {
      final health = buildHealth();
      expect(health.serverId, equals('server-1'));
      expect(health.cpuUsage, equals(10.0));
      expect(health.memoryUsage, equals(40.0));
      expect(health.diskUsage, equals(55.0));
      expect(health.temperature, equals(45));
      expect(health.isOnline, isTrue);
      expect(health.disks, hasLength(1));
      expect(health.network.downloadSpeed, equals(100));
    });

    test('equality holds for equal instances and differs on change', () {
      final a = buildHealth();
      final b = buildHealth();
      final c = buildHealth(cpuUsage: 99.0);
      expect(a, equals(b));
      expect(a == c, isFalse);
    });
  });
}
