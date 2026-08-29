import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/system_stats.dart';

void main() {
  group('CpuCore', () {
    test('fromJson parses full payload', () {
      final core = CpuCore.fromJson({'usage': 42.5, 'temp': 55.0});
      expect(core.usage, equals(42.5));
      expect(core.temperature, equals(55.0));
    });

    test('fromJson applies defaults for missing fields', () {
      final core = CpuCore.fromJson({});
      expect(core.usage, equals(0.0));
      expect(core.temperature, isNull);
    });

    test('fromJson handles int values coerced to double', () {
      final core = CpuCore.fromJson({'usage': 10, 'temp': 20});
      expect(core.usage, equals(10.0));
      expect(core.temperature, equals(20.0));
    });

    test('toJson round-trips', () {
      const core = CpuCore(usage: 12.3, temperature: 45.6);
      final json = core.toJson();
      expect(json, equals({'usage': 12.3, 'temp': 45.6}));
      final roundTripped = CpuCore.fromJson(json);
      expect(roundTripped, equals(core));
    });

    test('equality holds for same fields and differs on change', () {
      const a = CpuCore(usage: 1.0, temperature: 2.0);
      const b = CpuCore(usage: 1.0, temperature: 2.0);
      const c = CpuCore(usage: 1.0, temperature: 3.0);
      expect(a, equals(b));
      expect(a == c, isFalse);
    });
  });

  group('CpuStats', () {
    test('fromJson separates overall cpu entry from per-core entries', () {
      final stats = CpuStats.fromJson({
        'cpu': {'usage': 30.0, 'temp': 40.0},
        'cpu0': {'usage': 10.0, 'temp': 35.0},
        'cpu1': {'usage': 20.0, 'temp': 36.0},
      });

      expect(stats.overall.usage, equals(30.0));
      expect(stats.cores.length, equals(2));
      expect(stats.cores['cpu0']!.usage, equals(10.0));
      expect(stats.cores['cpu1']!.usage, equals(20.0));
    });

    test('fromJson defaults overall when no cpu key present', () {
      final stats = CpuStats.fromJson({
        'cpu0': {'usage': 10.0},
      });

      expect(stats.overall.usage, equals(0.0));
      expect(stats.overall.temperature, isNull);
      expect(stats.cores.length, equals(1));
    });

    test('fromJson handles empty map', () {
      final stats = CpuStats.fromJson({});
      expect(stats.overall.usage, equals(0.0));
      expect(stats.cores, isEmpty);
    });

    test('toJson round-trips', () {
      final stats = CpuStats.fromJson({
        'cpu': {'usage': 30.0, 'temp': 40.0},
        'cpu0': {'usage': 10.0, 'temp': 35.0},
      });
      final json = stats.toJson();
      expect(json['cpu'], equals({'usage': 30.0, 'temp': 40.0}));
      expect(json['cpu0'], equals({'usage': 10.0, 'temp': 35.0}));

      final roundTripped = CpuStats.fromJson(json);
      expect(roundTripped, equals(stats));
    });

    test('equality holds for equal instances and differs on change', () {
      const overall = CpuCore(usage: 1.0);
      const a = CpuStats(overall: overall, cores: {});
      const b = CpuStats(overall: overall, cores: {});
      final c = CpuStats(
        overall: overall,
        cores: {'cpu0': const CpuCore(usage: 5.0)},
      );
      expect(a, equals(b));
      expect(a == c, isFalse);
    });
  });

  group('MemoryStats', () {
    test('fromJson parses full payload', () {
      final mem = MemoryStats.fromJson({
        'arc_size': 100,
        'arc_free_memory': 50,
        'arc_available_memory': 60,
        'physical_memory_total': 1000,
        'physical_memory_available': 400,
      });

      expect(mem.arcSize, equals(100));
      expect(mem.arcFreeMemory, equals(50));
      expect(mem.arcAvailableMemory, equals(60));
      expect(mem.physicalMemoryTotal, equals(1000));
      expect(mem.physicalMemoryAvailable, equals(400));
    });

    test('fromJson applies defaults for missing fields', () {
      final mem = MemoryStats.fromJson({});
      expect(mem.arcSize, equals(0));
      expect(mem.arcFreeMemory, equals(0));
      expect(mem.arcAvailableMemory, equals(0));
      expect(mem.physicalMemoryTotal, equals(0));
      expect(mem.physicalMemoryAvailable, equals(0));
    });

    test('toJson round-trips', () {
      const mem = MemoryStats(
        arcSize: 10,
        arcFreeMemory: 20,
        arcAvailableMemory: 30,
        physicalMemoryTotal: 1000,
        physicalMemoryAvailable: 500,
      );
      final json = mem.toJson();
      final roundTripped = MemoryStats.fromJson(json);
      expect(roundTripped, equals(mem));
    });

    test('physicalMemoryUsagePercent computes correctly', () {
      const mem = MemoryStats(
        arcSize: 0,
        arcFreeMemory: 0,
        arcAvailableMemory: 0,
        physicalMemoryTotal: 1000,
        physicalMemoryAvailable: 250,
      );
      expect(mem.physicalMemoryUsagePercent, equals(75.0));
    });

    test('physicalMemoryUsagePercent guards division by zero', () {
      const mem = MemoryStats(
        arcSize: 0,
        arcFreeMemory: 0,
        arcAvailableMemory: 0,
        physicalMemoryTotal: 0,
        physicalMemoryAvailable: 0,
      );
      expect(mem.physicalMemoryUsagePercent, equals(0.0));
    });

    test('arcUsagePercent computes correctly', () {
      const mem = MemoryStats(
        arcSize: 200,
        arcFreeMemory: 0,
        arcAvailableMemory: 0,
        physicalMemoryTotal: 1000,
        physicalMemoryAvailable: 0,
      );
      expect(mem.arcUsagePercent, equals(20.0));
    });

    test('arcUsagePercent guards division by zero', () {
      const mem = MemoryStats(
        arcSize: 200,
        arcFreeMemory: 0,
        arcAvailableMemory: 0,
        physicalMemoryTotal: 0,
        physicalMemoryAvailable: 0,
      );
      expect(mem.arcUsagePercent, equals(0.0));
    });

    test('equality holds for equal instances and differs on change', () {
      const a = MemoryStats(
        arcSize: 1,
        arcFreeMemory: 2,
        arcAvailableMemory: 3,
        physicalMemoryTotal: 4,
        physicalMemoryAvailable: 5,
      );
      const b = MemoryStats(
        arcSize: 1,
        arcFreeMemory: 2,
        arcAvailableMemory: 3,
        physicalMemoryTotal: 4,
        physicalMemoryAvailable: 5,
      );
      const c = MemoryStats(
        arcSize: 9,
        arcFreeMemory: 2,
        arcAvailableMemory: 3,
        physicalMemoryTotal: 4,
        physicalMemoryAvailable: 5,
      );
      expect(a, equals(b));
      expect(a == c, isFalse);
    });
  });

  group('ZfsStats', () {
    final fullJson = {
      'demand_accesses_per_second': 1.0,
      'demand_data_accesses_per_second': 2.0,
      'demand_metadata_accesses_per_second': 3.0,
      'demand_data_hits_per_second': 4.0,
      'demand_data_io_hits_per_second': 5.0,
      'demand_data_misses_per_second': 6.0,
      'demand_data_hit_percentage': 7.0,
      'demand_data_io_hit_percentage': 8.0,
      'demand_data_miss_percentage': 9.0,
      'demand_metadata_hits_per_second': 10.0,
      'demand_metadata_io_hits_per_second': 11.0,
      'demand_metadata_misses_per_second': 12.0,
      'demand_metadata_hit_percentage': 13.0,
      'demand_metadata_io_hit_percentage': 14.0,
      'demand_metadata_miss_percentage': 15.0,
      'l2arc_hits_per_second': 16.0,
      'l2arc_misses_per_second': 17.0,
      'total_l2arc_accesses_per_second': 18.0,
      'l2arc_access_hit_percentage': 19.0,
      'l2arc_miss_percentage': 20.0,
      'bytes_read_per_second_from_the_l2arc': 21.0,
      'bytes_written_per_second_to_the_l2arc': 22.0,
    };

    test('fromJson parses full payload', () {
      final zfs = ZfsStats.fromJson(fullJson);
      expect(zfs.demandAccessesPerSecond, equals(1.0));
      expect(zfs.demandDataAccessesPerSecond, equals(2.0));
      expect(zfs.demandMetadataAccessesPerSecond, equals(3.0));
      expect(zfs.demandDataHitsPerSecond, equals(4.0));
      expect(zfs.demandDataIoHitsPerSecond, equals(5.0));
      expect(zfs.demandDataMissesPerSecond, equals(6.0));
      expect(zfs.demandDataHitPercentage, equals(7.0));
      expect(zfs.demandDataIoHitPercentage, equals(8.0));
      expect(zfs.demandDataMissPercentage, equals(9.0));
      expect(zfs.demandMetadataHitsPerSecond, equals(10.0));
      expect(zfs.demandMetadataIoHitsPerSecond, equals(11.0));
      expect(zfs.demandMetadataMissesPerSecond, equals(12.0));
      expect(zfs.demandMetadataHitPercentage, equals(13.0));
      expect(zfs.demandMetadataIoHitPercentage, equals(14.0));
      expect(zfs.demandMetadataMissPercentage, equals(15.0));
      expect(zfs.l2arcHitsPerSecond, equals(16.0));
      expect(zfs.l2arcMissesPerSecond, equals(17.0));
      expect(zfs.totalL2arcAccessesPerSecond, equals(18.0));
      expect(zfs.l2arcAccessHitPercentage, equals(19.0));
      expect(zfs.l2arcMissPercentage, equals(20.0));
      expect(zfs.bytesReadPerSecondFromTheL2arc, equals(21.0));
      expect(zfs.bytesWrittenPerSecondToTheL2arc, equals(22.0));
    });

    test('fromJson applies zero defaults for missing fields', () {
      final zfs = ZfsStats.fromJson({});
      expect(zfs.demandAccessesPerSecond, equals(0.0));
      expect(zfs.l2arcMissPercentage, equals(0.0));
      expect(zfs.bytesWrittenPerSecondToTheL2arc, equals(0.0));
    });

    test('toJson round-trips', () {
      final zfs = ZfsStats.fromJson(fullJson);
      final json = zfs.toJson();
      final roundTripped = ZfsStats.fromJson(json);
      expect(roundTripped, equals(zfs));
      expect(json['demand_accesses_per_second'], equals(1.0));
    });

    test('equality holds and differs on a single changed field', () {
      final a = ZfsStats.fromJson(fullJson);
      final b = ZfsStats.fromJson(fullJson);
      final changedJson = Map<String, dynamic>.from(fullJson);
      changedJson['demand_accesses_per_second'] = 999.0;
      final c = ZfsStats.fromJson(changedJson);
      expect(a, equals(b));
      expect(a == c, isFalse);
    });
  });

  group('DiskStats', () {
    test('fromJson parses full payload', () {
      final disk = DiskStats.fromJson({
        'read_ops': 1.0,
        'read_bytes': 2.0,
        'write_ops': 3.0,
        'write_bytes': 4.0,
        'busy': 5.0,
      });
      expect(disk.readOps, equals(1.0));
      expect(disk.readBytes, equals(2.0));
      expect(disk.writeOps, equals(3.0));
      expect(disk.writeBytes, equals(4.0));
      expect(disk.busy, equals(5.0));
    });

    test('fromJson applies defaults for missing fields', () {
      final disk = DiskStats.fromJson({});
      expect(disk.readOps, equals(0.0));
      expect(disk.readBytes, equals(0.0));
      expect(disk.writeOps, equals(0.0));
      expect(disk.writeBytes, equals(0.0));
      expect(disk.busy, equals(0.0));
    });

    test('toJson round-trips', () {
      const disk = DiskStats(
        readOps: 1,
        readBytes: 2,
        writeOps: 3,
        writeBytes: 4,
        busy: 5,
      );
      final json = disk.toJson();
      final roundTripped = DiskStats.fromJson(json);
      expect(roundTripped, equals(disk));
    });

    test('totalOps and totalBytes sum read and write', () {
      const disk = DiskStats(
        readOps: 10,
        readBytes: 100,
        writeOps: 5,
        writeBytes: 50,
        busy: 0,
      );
      expect(disk.totalOps, equals(15));
      expect(disk.totalBytes, equals(150));
    });

    test('equality holds for equal instances and differs on change', () {
      const a = DiskStats(
        readOps: 1,
        readBytes: 2,
        writeOps: 3,
        writeBytes: 4,
        busy: 5,
      );
      const b = DiskStats(
        readOps: 1,
        readBytes: 2,
        writeOps: 3,
        writeBytes: 4,
        busy: 5,
      );
      const c = DiskStats(
        readOps: 9,
        readBytes: 2,
        writeOps: 3,
        writeBytes: 4,
        busy: 5,
      );
      expect(a, equals(b));
      expect(a == c, isFalse);
    });
  });

  group('NetworkInterfaceStats', () {
    test('fromJson parses full payload', () {
      final iface = NetworkInterfaceStats.fromJson({
        'link_state': 'LINK_STATE_UP',
        'speed': 1000.0,
        'received_bytes_rate': 500.0,
        'sent_bytes_rate': 250.0,
      });
      expect(iface.linkState, equals('LINK_STATE_UP'));
      expect(iface.speed, equals(1000.0));
      expect(iface.receivedBytesRate, equals(500.0));
      expect(iface.sentBytesRate, equals(250.0));
    });

    test('fromJson applies defaults for missing fields', () {
      final iface = NetworkInterfaceStats.fromJson({});
      expect(iface.linkState, equals('UNKNOWN'));
      expect(iface.speed, equals(0.0));
      expect(iface.receivedBytesRate, equals(0.0));
      expect(iface.sentBytesRate, equals(0.0));
    });

    test('toJson round-trips', () {
      const iface = NetworkInterfaceStats(
        linkState: 'LINK_STATE_UP',
        speed: 1000.0,
        receivedBytesRate: 500.0,
        sentBytesRate: 250.0,
      );
      final json = iface.toJson();
      final roundTripped = NetworkInterfaceStats.fromJson(json);
      expect(roundTripped, equals(iface));
    });

    test('isUp is true only when link state is LINK_STATE_UP', () {
      const up = NetworkInterfaceStats(
        linkState: 'LINK_STATE_UP',
        speed: 0,
        receivedBytesRate: 0,
        sentBytesRate: 0,
      );
      const down = NetworkInterfaceStats(
        linkState: 'LINK_STATE_DOWN',
        speed: 0,
        receivedBytesRate: 0,
        sentBytesRate: 0,
      );
      expect(up.isUp, isTrue);
      expect(down.isUp, isFalse);
    });

    test('totalBytesRate sums received and sent', () {
      const iface = NetworkInterfaceStats(
        linkState: 'LINK_STATE_UP',
        speed: 0,
        receivedBytesRate: 300.0,
        sentBytesRate: 100.0,
      );
      expect(iface.totalBytesRate, equals(400.0));
    });

    test('equality holds for equal instances and differs on change', () {
      const a = NetworkInterfaceStats(
        linkState: 'LINK_STATE_UP',
        speed: 1,
        receivedBytesRate: 2,
        sentBytesRate: 3,
      );
      const b = NetworkInterfaceStats(
        linkState: 'LINK_STATE_UP',
        speed: 1,
        receivedBytesRate: 2,
        sentBytesRate: 3,
      );
      const c = NetworkInterfaceStats(
        linkState: 'LINK_STATE_DOWN',
        speed: 1,
        receivedBytesRate: 2,
        sentBytesRate: 3,
      );
      expect(a, equals(b));
      expect(a == c, isFalse);
    });
  });

  group('SystemStats', () {
    Map<String, dynamic> buildFullJson() => {
      'cpu': {
        'cpu': {'usage': 10.0, 'temp': 40.0},
        'cpu0': {'usage': 5.0, 'temp': 38.0},
      },
      'memory': {
        'arc_size': 100,
        'arc_free_memory': 50,
        'arc_available_memory': 60,
        'physical_memory_total': 1000,
        'physical_memory_available': 400,
      },
      'zfs': {'demand_accesses_per_second': 1.0},
      'disks': {'read_ops': 1.0, 'write_ops': 2.0},
      'interfaces': {
        'eth0': {
          'link_state': 'LINK_STATE_UP',
          'speed': 1000.0,
          'received_bytes_rate': 10.0,
          'sent_bytes_rate': 5.0,
        },
      },
      'failed_to_connect': false,
    };

    test('fromJson parses a full payload', () {
      final stats = SystemStats.fromJson(buildFullJson());

      expect(stats.cpu.overall.usage, equals(10.0));
      expect(stats.cpu.cores['cpu0']!.usage, equals(5.0));
      expect(stats.memory.arcSize, equals(100));
      expect(stats.zfs.demandAccessesPerSecond, equals(1.0));
      expect(stats.disks.readOps, equals(1.0));
      expect(stats.interfaces.length, equals(1));
      expect(stats.interfaces['eth0']!.linkState, equals('LINK_STATE_UP'));
      expect(stats.failedToConnect, isFalse);
      expect(stats.timestamp, isA<DateTime>());
    });

    test('fromJson applies defaults for missing/null optional fields', () {
      final stats = SystemStats.fromJson({});

      expect(stats.cpu.overall.usage, equals(0.0));
      expect(stats.cpu.cores, isEmpty);
      expect(stats.memory.arcSize, equals(0));
      expect(stats.zfs.demandAccessesPerSecond, equals(0.0));
      expect(stats.disks.readOps, equals(0.0));
      expect(stats.interfaces, isEmpty);
      expect(stats.failedToConnect, isFalse);
    });

    test('fromJson honors failed_to_connect true', () {
      final json = buildFullJson();
      json['failed_to_connect'] = true;
      final stats = SystemStats.fromJson(json);
      expect(stats.failedToConnect, isTrue);
    });

    test('toJson emits nested structures including interfaces', () {
      final stats = SystemStats.fromJson(buildFullJson());
      final json = stats.toJson();

      expect(json['cpu'], isA<Map>());
      expect(json['memory'], isA<Map>());
      expect(json['zfs'], isA<Map>());
      expect(json['disks'], isA<Map>());
      expect(json['interfaces'], isA<Map>());
      expect((json['interfaces'] as Map)['eth0'], isA<Map>());
      expect(json['failed_to_connect'], isFalse);
    });

    test('equality is based on props including timestamp', () {
      final timestamp = DateTime(2024, 1, 1);
      const cpu = CpuStats(overall: CpuCore(usage: 0), cores: {});
      const memory = MemoryStats(
        arcSize: 0,
        arcFreeMemory: 0,
        arcAvailableMemory: 0,
        physicalMemoryTotal: 0,
        physicalMemoryAvailable: 0,
      );
      const zfs = ZfsStats(
        demandAccessesPerSecond: 0,
        demandDataAccessesPerSecond: 0,
        demandMetadataAccessesPerSecond: 0,
        demandDataHitsPerSecond: 0,
        demandDataIoHitsPerSecond: 0,
        demandDataMissesPerSecond: 0,
        demandDataHitPercentage: 0,
        demandDataIoHitPercentage: 0,
        demandDataMissPercentage: 0,
        demandMetadataHitsPerSecond: 0,
        demandMetadataIoHitsPerSecond: 0,
        demandMetadataMissesPerSecond: 0,
        demandMetadataHitPercentage: 0,
        demandMetadataIoHitPercentage: 0,
        demandMetadataMissPercentage: 0,
        l2arcHitsPerSecond: 0,
        l2arcMissesPerSecond: 0,
        totalL2arcAccessesPerSecond: 0,
        l2arcAccessHitPercentage: 0,
        l2arcMissPercentage: 0,
        bytesReadPerSecondFromTheL2arc: 0,
        bytesWrittenPerSecondToTheL2arc: 0,
      );
      const disks = DiskStats(
        readOps: 0,
        readBytes: 0,
        writeOps: 0,
        writeBytes: 0,
        busy: 0,
      );

      final a = SystemStats(
        cpu: cpu,
        memory: memory,
        zfs: zfs,
        disks: disks,
        interfaces: const {},
        timestamp: timestamp,
      );
      final b = SystemStats(
        cpu: cpu,
        memory: memory,
        zfs: zfs,
        disks: disks,
        interfaces: const {},
        timestamp: timestamp,
      );
      final c = SystemStats(
        cpu: cpu,
        memory: memory,
        zfs: zfs,
        disks: disks,
        interfaces: const {},
        timestamp: timestamp.add(const Duration(seconds: 1)),
      );

      expect(a, equals(b));
      expect(a == c, isFalse);
    });
  });
}
