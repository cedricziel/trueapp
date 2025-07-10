import 'package:equatable/equatable.dart';

class SystemStats extends Equatable {
  final CpuStats cpu;
  final MemoryStats memory;
  final ZfsStats zfs;
  final DiskStats disks;
  final Map<String, NetworkInterfaceStats> interfaces;
  final bool failedToConnect;
  final DateTime timestamp;

  const SystemStats({
    required this.cpu,
    required this.memory,
    required this.zfs,
    required this.disks,
    required this.interfaces,
    this.failedToConnect = false,
    required this.timestamp,
  });

  factory SystemStats.fromJson(Map<String, dynamic> json) {
    final interfacesData = json['interfaces'] as Map<String, dynamic>? ?? {};
    final interfaces = <String, NetworkInterfaceStats>{};

    for (final entry in interfacesData.entries) {
      interfaces[entry.key] = NetworkInterfaceStats.fromJson(
        entry.value as Map<String, dynamic>,
      );
    }

    return SystemStats(
      cpu: CpuStats.fromJson(json['cpu'] as Map<String, dynamic>? ?? {}),
      memory: MemoryStats.fromJson(
        json['memory'] as Map<String, dynamic>? ?? {},
      ),
      zfs: ZfsStats.fromJson(json['zfs'] as Map<String, dynamic>? ?? {}),
      disks: DiskStats.fromJson(json['disks'] as Map<String, dynamic>? ?? {}),
      interfaces: interfaces,
      failedToConnect: json['failed_to_connect'] as bool? ?? false,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final interfacesJson = <String, dynamic>{};
    for (final entry in interfaces.entries) {
      interfacesJson[entry.key] = entry.value.toJson();
    }

    return {
      'cpu': cpu.toJson(),
      'memory': memory.toJson(),
      'zfs': zfs.toJson(),
      'disks': disks.toJson(),
      'interfaces': interfacesJson,
      'failed_to_connect': failedToConnect,
    };
  }

  @override
  List<Object?> get props => [
    cpu,
    memory,
    zfs,
    disks,
    interfaces,
    failedToConnect,
    timestamp,
  ];
}

class CpuStats extends Equatable {
  final CpuCore overall;
  final Map<String, CpuCore> cores;

  const CpuStats({required this.overall, required this.cores});

  factory CpuStats.fromJson(Map<String, dynamic> json) {
    final cores = <String, CpuCore>{};

    CpuCore? overall;
    for (final entry in json.entries) {
      final coreData = entry.value as Map<String, dynamic>;
      final core = CpuCore.fromJson(coreData);

      if (entry.key == 'cpu') {
        overall = core;
      } else {
        cores[entry.key] = core;
      }
    }

    return CpuStats(
      overall: overall ?? const CpuCore(usage: 0.0, temperature: null),
      cores: cores,
    );
  }

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{'cpu': overall.toJson()};

    for (final entry in cores.entries) {
      result[entry.key] = entry.value.toJson();
    }

    return result;
  }

  @override
  List<Object?> get props => [overall, cores];
}

class CpuCore extends Equatable {
  final double usage;
  final double? temperature;

  const CpuCore({required this.usage, this.temperature});

  factory CpuCore.fromJson(Map<String, dynamic> json) {
    return CpuCore(
      usage: (json['usage'] as num?)?.toDouble() ?? 0.0,
      temperature: (json['temp'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'usage': usage, 'temp': temperature};
  }

  @override
  List<Object?> get props => [usage, temperature];
}

class MemoryStats extends Equatable {
  final int arcSize;
  final int arcFreeMemory;
  final int arcAvailableMemory;
  final int physicalMemoryTotal;
  final int physicalMemoryAvailable;

  const MemoryStats({
    required this.arcSize,
    required this.arcFreeMemory,
    required this.arcAvailableMemory,
    required this.physicalMemoryTotal,
    required this.physicalMemoryAvailable,
  });

  factory MemoryStats.fromJson(Map<String, dynamic> json) {
    return MemoryStats(
      arcSize: json['arc_size'] as int? ?? 0,
      arcFreeMemory: json['arc_free_memory'] as int? ?? 0,
      arcAvailableMemory: json['arc_available_memory'] as int? ?? 0,
      physicalMemoryTotal: json['physical_memory_total'] as int? ?? 0,
      physicalMemoryAvailable: json['physical_memory_available'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'arc_size': arcSize,
      'arc_free_memory': arcFreeMemory,
      'arc_available_memory': arcAvailableMemory,
      'physical_memory_total': physicalMemoryTotal,
      'physical_memory_available': physicalMemoryAvailable,
    };
  }

  double get physicalMemoryUsagePercent {
    if (physicalMemoryTotal == 0) return 0.0;
    final used = physicalMemoryTotal - physicalMemoryAvailable;
    return (used / physicalMemoryTotal) * 100;
  }

  double get arcUsagePercent {
    if (physicalMemoryTotal == 0) return 0.0;
    return (arcSize / physicalMemoryTotal) * 100;
  }

  @override
  List<Object?> get props => [
    arcSize,
    arcFreeMemory,
    arcAvailableMemory,
    physicalMemoryTotal,
    physicalMemoryAvailable,
  ];
}

class ZfsStats extends Equatable {
  final double demandAccessesPerSecond;
  final double demandDataAccessesPerSecond;
  final double demandMetadataAccessesPerSecond;
  final double demandDataHitsPerSecond;
  final double demandDataIoHitsPerSecond;
  final double demandDataMissesPerSecond;
  final double demandDataHitPercentage;
  final double demandDataIoHitPercentage;
  final double demandDataMissPercentage;
  final double demandMetadataHitsPerSecond;
  final double demandMetadataIoHitsPerSecond;
  final double demandMetadataMissesPerSecond;
  final double demandMetadataHitPercentage;
  final double demandMetadataIoHitPercentage;
  final double demandMetadataMissPercentage;
  final double l2arcHitsPerSecond;
  final double l2arcMissesPerSecond;
  final double totalL2arcAccessesPerSecond;
  final double l2arcAccessHitPercentage;
  final double l2arcMissPercentage;
  final double bytesReadPerSecondFromTheL2arc;
  final double bytesWrittenPerSecondToTheL2arc;

  const ZfsStats({
    required this.demandAccessesPerSecond,
    required this.demandDataAccessesPerSecond,
    required this.demandMetadataAccessesPerSecond,
    required this.demandDataHitsPerSecond,
    required this.demandDataIoHitsPerSecond,
    required this.demandDataMissesPerSecond,
    required this.demandDataHitPercentage,
    required this.demandDataIoHitPercentage,
    required this.demandDataMissPercentage,
    required this.demandMetadataHitsPerSecond,
    required this.demandMetadataIoHitsPerSecond,
    required this.demandMetadataMissesPerSecond,
    required this.demandMetadataHitPercentage,
    required this.demandMetadataIoHitPercentage,
    required this.demandMetadataMissPercentage,
    required this.l2arcHitsPerSecond,
    required this.l2arcMissesPerSecond,
    required this.totalL2arcAccessesPerSecond,
    required this.l2arcAccessHitPercentage,
    required this.l2arcMissPercentage,
    required this.bytesReadPerSecondFromTheL2arc,
    required this.bytesWrittenPerSecondToTheL2arc,
  });

  factory ZfsStats.fromJson(Map<String, dynamic> json) {
    return ZfsStats(
      demandAccessesPerSecond:
          (json['demand_accesses_per_second'] as num?)?.toDouble() ?? 0.0,
      demandDataAccessesPerSecond:
          (json['demand_data_accesses_per_second'] as num?)?.toDouble() ?? 0.0,
      demandMetadataAccessesPerSecond:
          (json['demand_metadata_accesses_per_second'] as num?)?.toDouble() ??
          0.0,
      demandDataHitsPerSecond:
          (json['demand_data_hits_per_second'] as num?)?.toDouble() ?? 0.0,
      demandDataIoHitsPerSecond:
          (json['demand_data_io_hits_per_second'] as num?)?.toDouble() ?? 0.0,
      demandDataMissesPerSecond:
          (json['demand_data_misses_per_second'] as num?)?.toDouble() ?? 0.0,
      demandDataHitPercentage:
          (json['demand_data_hit_percentage'] as num?)?.toDouble() ?? 0.0,
      demandDataIoHitPercentage:
          (json['demand_data_io_hit_percentage'] as num?)?.toDouble() ?? 0.0,
      demandDataMissPercentage:
          (json['demand_data_miss_percentage'] as num?)?.toDouble() ?? 0.0,
      demandMetadataHitsPerSecond:
          (json['demand_metadata_hits_per_second'] as num?)?.toDouble() ?? 0.0,
      demandMetadataIoHitsPerSecond:
          (json['demand_metadata_io_hits_per_second'] as num?)?.toDouble() ??
          0.0,
      demandMetadataMissesPerSecond:
          (json['demand_metadata_misses_per_second'] as num?)?.toDouble() ??
          0.0,
      demandMetadataHitPercentage:
          (json['demand_metadata_hit_percentage'] as num?)?.toDouble() ?? 0.0,
      demandMetadataIoHitPercentage:
          (json['demand_metadata_io_hit_percentage'] as num?)?.toDouble() ??
          0.0,
      demandMetadataMissPercentage:
          (json['demand_metadata_miss_percentage'] as num?)?.toDouble() ?? 0.0,
      l2arcHitsPerSecond:
          (json['l2arc_hits_per_second'] as num?)?.toDouble() ?? 0.0,
      l2arcMissesPerSecond:
          (json['l2arc_misses_per_second'] as num?)?.toDouble() ?? 0.0,
      totalL2arcAccessesPerSecond:
          (json['total_l2arc_accesses_per_second'] as num?)?.toDouble() ?? 0.0,
      l2arcAccessHitPercentage:
          (json['l2arc_access_hit_percentage'] as num?)?.toDouble() ?? 0.0,
      l2arcMissPercentage:
          (json['l2arc_miss_percentage'] as num?)?.toDouble() ?? 0.0,
      bytesReadPerSecondFromTheL2arc:
          (json['bytes_read_per_second_from_the_l2arc'] as num?)?.toDouble() ??
          0.0,
      bytesWrittenPerSecondToTheL2arc:
          (json['bytes_written_per_second_to_the_l2arc'] as num?)?.toDouble() ??
          0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'demand_accesses_per_second': demandAccessesPerSecond,
      'demand_data_accesses_per_second': demandDataAccessesPerSecond,
      'demand_metadata_accesses_per_second': demandMetadataAccessesPerSecond,
      'demand_data_hits_per_second': demandDataHitsPerSecond,
      'demand_data_io_hits_per_second': demandDataIoHitsPerSecond,
      'demand_data_misses_per_second': demandDataMissesPerSecond,
      'demand_data_hit_percentage': demandDataHitPercentage,
      'demand_data_io_hit_percentage': demandDataIoHitPercentage,
      'demand_data_miss_percentage': demandDataMissPercentage,
      'demand_metadata_hits_per_second': demandMetadataHitsPerSecond,
      'demand_metadata_io_hits_per_second': demandMetadataIoHitsPerSecond,
      'demand_metadata_misses_per_second': demandMetadataMissesPerSecond,
      'demand_metadata_hit_percentage': demandMetadataHitPercentage,
      'demand_metadata_io_hit_percentage': demandMetadataIoHitPercentage,
      'demand_metadata_miss_percentage': demandMetadataMissPercentage,
      'l2arc_hits_per_second': l2arcHitsPerSecond,
      'l2arc_misses_per_second': l2arcMissesPerSecond,
      'total_l2arc_accesses_per_second': totalL2arcAccessesPerSecond,
      'l2arc_access_hit_percentage': l2arcAccessHitPercentage,
      'l2arc_miss_percentage': l2arcMissPercentage,
      'bytes_read_per_second_from_the_l2arc': bytesReadPerSecondFromTheL2arc,
      'bytes_written_per_second_to_the_l2arc': bytesWrittenPerSecondToTheL2arc,
    };
  }

  @override
  List<Object?> get props => [
    demandAccessesPerSecond,
    demandDataAccessesPerSecond,
    demandMetadataAccessesPerSecond,
    demandDataHitsPerSecond,
    demandDataIoHitsPerSecond,
    demandDataMissesPerSecond,
    demandDataHitPercentage,
    demandDataIoHitPercentage,
    demandDataMissPercentage,
    demandMetadataHitsPerSecond,
    demandMetadataIoHitsPerSecond,
    demandMetadataMissesPerSecond,
    demandMetadataHitPercentage,
    demandMetadataIoHitPercentage,
    demandMetadataMissPercentage,
    l2arcHitsPerSecond,
    l2arcMissesPerSecond,
    totalL2arcAccessesPerSecond,
    l2arcAccessHitPercentage,
    l2arcMissPercentage,
    bytesReadPerSecondFromTheL2arc,
    bytesWrittenPerSecondToTheL2arc,
  ];
}

class DiskStats extends Equatable {
  final double readOps;
  final double readBytes;
  final double writeOps;
  final double writeBytes;
  final double busy;

  const DiskStats({
    required this.readOps,
    required this.readBytes,
    required this.writeOps,
    required this.writeBytes,
    required this.busy,
  });

  factory DiskStats.fromJson(Map<String, dynamic> json) {
    return DiskStats(
      readOps: (json['read_ops'] as num?)?.toDouble() ?? 0.0,
      readBytes: (json['read_bytes'] as num?)?.toDouble() ?? 0.0,
      writeOps: (json['write_ops'] as num?)?.toDouble() ?? 0.0,
      writeBytes: (json['write_bytes'] as num?)?.toDouble() ?? 0.0,
      busy: (json['busy'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'read_ops': readOps,
      'read_bytes': readBytes,
      'write_ops': writeOps,
      'write_bytes': writeBytes,
      'busy': busy,
    };
  }

  double get totalOps => readOps + writeOps;
  double get totalBytes => readBytes + writeBytes;

  @override
  List<Object?> get props => [readOps, readBytes, writeOps, writeBytes, busy];
}

class NetworkInterfaceStats extends Equatable {
  final String linkState;
  final double speed;
  final double receivedBytesRate;
  final double sentBytesRate;

  const NetworkInterfaceStats({
    required this.linkState,
    required this.speed,
    required this.receivedBytesRate,
    required this.sentBytesRate,
  });

  factory NetworkInterfaceStats.fromJson(Map<String, dynamic> json) {
    return NetworkInterfaceStats(
      linkState: json['link_state'] as String? ?? 'UNKNOWN',
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      receivedBytesRate:
          (json['received_bytes_rate'] as num?)?.toDouble() ?? 0.0,
      sentBytesRate: (json['sent_bytes_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'link_state': linkState,
      'speed': speed,
      'received_bytes_rate': receivedBytesRate,
      'sent_bytes_rate': sentBytesRate,
    };
  }

  bool get isUp => linkState == 'LINK_STATE_UP';
  double get totalBytesRate => receivedBytesRate + sentBytesRate;

  @override
  List<Object?> get props => [
    linkState,
    speed,
    receivedBytesRate,
    sentBytesRate,
  ];
}
