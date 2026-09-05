import 'package:equatable/equatable.dart';

/// The reported state of a single physical disk within a [Vdev].
enum VdevDiskStatus {
  online,
  degraded,
  faulted,
  offline,
  removed,
  unavail,
  unknown,
}

VdevDiskStatus _parseDiskStatus(String? raw) {
  switch (raw?.toUpperCase()) {
    case 'ONLINE':
      return VdevDiskStatus.online;
    case 'DEGRADED':
      return VdevDiskStatus.degraded;
    case 'FAULTED':
      return VdevDiskStatus.faulted;
    case 'OFFLINE':
      return VdevDiskStatus.offline;
    case 'REMOVED':
      return VdevDiskStatus.removed;
    case 'UNAVAIL':
      return VdevDiskStatus.unavail;
    default:
      return VdevDiskStatus.unknown;
  }
}

/// One physical disk as it appears inside a pool's topology - either a leaf
/// of a [Vdev] (e.g. one drive of a mirror) or, for a single-disk vdev, the
/// vdev itself.
class VdevDisk extends Equatable {
  final String name;
  final VdevDiskStatus status;

  const VdevDisk({required this.name, required this.status});

  bool get isHealthy => status == VdevDiskStatus.online;

  factory VdevDisk.fromJson(Map<String, dynamic> json) {
    return VdevDisk(
      name:
          json['disk'] as String? ??
          json['path'] as String? ??
          json['name'] as String? ??
          'Unknown',
      status: _parseDiskStatus(json['status'] as String?),
    );
  }

  @override
  List<Object?> get props => [name, status];
}

/// One top-level vdev of a pool's data topology (a mirror, a RAID-Z group,
/// or a single disk), and the physical disks that make it up.
class Vdev extends Equatable {
  final String type;
  final List<VdevDisk> disks;

  const Vdev({required this.type, required this.disks});

  bool get isHealthy => disks.every((disk) => disk.isHealthy);

  /// A short, human description of this vdev's redundancy layout, matching
  /// the wording used across the app (e.g. "Mirror (2 drives)").
  String get typeDescription {
    switch (type) {
      case 'mirror':
        return 'Mirror (${disks.length} drives)';
      case 'raidz1':
        return 'RAID-Z1 (${disks.length} drives)';
      case 'raidz2':
        return 'RAID-Z2 (${disks.length} drives)';
      case 'raidz3':
        return 'RAID-Z3 (${disks.length} drives)';
      default:
        return disks.length == 1 ? 'Single drive' : 'Custom configuration';
    }
  }

  factory Vdev.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] as String? ?? 'disk').toLowerCase();
    final childrenJson = json['children'] as List<dynamic>?;
    final disks = childrenJson != null && childrenJson.isNotEmpty
        ? childrenJson
              .map((child) => VdevDisk.fromJson(child as Map<String, dynamic>))
              .toList()
        // A leaf vdev (a single disk with no striping/mirroring) carries its
        // disk fields directly rather than in a `children` list.
        : [VdevDisk.fromJson(json)];
    return Vdev(type: type, disks: disks);
  }

  @override
  List<Object?> get props => [type, disks];
}

/// A ZFS storage pool, typed from the raw `pool.query` JSON the TrueNAS API
/// returns - replacing the `Map<String, dynamic>` the pool and dataset
/// screens previously passed around, which could only expose a pool's
/// health as a status string and its topology as a text description with no
/// way to say which specific drive needed attention.
class Pool extends Equatable {
  final String id;
  final String name;
  final String status;
  final bool healthy;
  final int allocatedBytes;
  final int freeBytes;
  final List<Vdev> dataVdevs;

  const Pool({
    required this.id,
    required this.name,
    required this.status,
    required this.healthy,
    required this.allocatedBytes,
    required this.freeBytes,
    required this.dataVdevs,
  });

  int get totalBytes => allocatedBytes + freeBytes;

  /// Every physical disk across every top-level vdev in this pool.
  List<VdevDisk> get allDisks =>
      dataVdevs.expand((vdev) => vdev.disks).toList();

  /// A short, human description of the pool's redundancy layout - combining
  /// vdev descriptions when the pool has more than one top-level vdev.
  String get topologyDescription {
    if (dataVdevs.isEmpty) return 'Unknown configuration';
    if (dataVdevs.length == 1) return dataVdevs.first.typeDescription;
    return '${dataVdevs.length} × ${dataVdevs.first.typeDescription}';
  }

  factory Pool.fromJson(Map<String, dynamic> json) {
    final topology = json['topology'] as Map<String, dynamic>?;
    final dataJson = topology?['data'] as List<dynamic>?;
    return Pool(
      id: (json['id'] ?? json['name'] ?? '').toString(),
      name: json['name'] as String? ?? 'Unknown',
      status: json['status'] as String? ?? 'Unknown',
      healthy: json['healthy'] as bool? ?? false,
      allocatedBytes: (json['allocated'] as num?)?.toInt() ?? 0,
      freeBytes: (json['free'] as num?)?.toInt() ?? 0,
      dataVdevs: dataJson == null
          ? const []
          : dataJson
                .map((vdev) => Vdev.fromJson(vdev as Map<String, dynamic>))
                .toList(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    status,
    healthy,
    allocatedBytes,
    freeBytes,
    dataVdevs,
  ];
}
