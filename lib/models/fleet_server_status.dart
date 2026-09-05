import 'package:equatable/equatable.dart';

/// Whether a one-shot fleet health check for a server has run yet, and
/// what it found.
enum FleetServerConnectivity {
  /// No check has been attempted yet (the Home screen just mounted, or
  /// this server was added after the last fleet refresh).
  unknown,

  /// A check is in flight.
  loading,

  /// The last check reached the server successfully.
  online,

  /// The last check failed - unreachable, timed out, or rejected
  /// credentials.
  offline,
}

/// A snapshot of one server's reachability and headline health, gathered by
/// [FleetStatusProvider] so the servers list can surface which one needs
/// attention without the user opening it first.
class FleetServerStatus extends Equatable {
  final String serverId;
  final FleetServerConnectivity connectivity;
  final double? cpuUsage;
  final double? storageUsage;
  final int activeAlertCount;

  const FleetServerStatus({
    required this.serverId,
    this.connectivity = FleetServerConnectivity.unknown,
    this.cpuUsage,
    this.storageUsage,
    this.activeAlertCount = 0,
  });

  /// True when this server should be sorted to the top of the list and
  /// flagged in the fleet summary banner.
  bool get needsAttention =>
      connectivity == FleetServerConnectivity.offline || activeAlertCount > 0;

  FleetServerStatus copyWith({
    FleetServerConnectivity? connectivity,
    double? cpuUsage,
    double? storageUsage,
    int? activeAlertCount,
  }) {
    return FleetServerStatus(
      serverId: serverId,
      connectivity: connectivity ?? this.connectivity,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      storageUsage: storageUsage ?? this.storageUsage,
      activeAlertCount: activeAlertCount ?? this.activeAlertCount,
    );
  }

  @override
  List<Object?> get props => [
    serverId,
    connectivity,
    cpuUsage,
    storageUsage,
    activeAlertCount,
  ];
}
