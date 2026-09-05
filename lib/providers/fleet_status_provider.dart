import 'package:flutter/foundation.dart';
import 'package:truehub/models/alert.dart';
import 'package:truehub/models/fleet_server_status.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/services/api_client_manager.dart';
import 'package:truehub/services/unified_server_service.dart';

/// Fetches a bounded, one-shot health snapshot for every saved server so
/// the Home screen can show which one needs attention without the user
/// opening it first.
///
/// This is deliberately NOT a persistent per-server subscription - one
/// round trip per server, run once when Home appears (or on manual
/// refresh), each capped by [defaultTimeout] so a single unreachable NAS
/// can never hold up the rest of the fleet.
class FleetStatusProvider extends ChangeNotifier {
  static const Duration defaultTimeout = Duration(seconds: 6);

  final UnifiedServerService _serverService;
  final Map<String, FleetServerStatus> _statuses = {};

  FleetStatusProvider(this._serverService);

  FleetServerStatus statusFor(String serverId) =>
      _statuses[serverId] ?? FleetServerStatus(serverId: serverId);

  bool get isRefreshing => _statuses.values.any(
    (status) => status.connectivity == FleetServerConnectivity.loading,
  );

  Future<void> refreshAll(
    List<NasServer> servers, {
    Duration timeout = defaultTimeout,
  }) async {
    for (final server in servers) {
      _statuses[server.id] = statusFor(
        server.id,
      ).copyWith(connectivity: FleetServerConnectivity.loading);
    }
    notifyListeners();

    await Future.wait(servers.map((server) => _refreshOne(server, timeout)));
  }

  Future<void> _refreshOne(NasServer server, Duration timeout) async {
    String? checkedOutServerId;
    try {
      final serverWithCredentials = await ServerProvider.loadServerCredentials(
        server,
        _serverService,
      );
      if (serverWithCredentials == null) {
        _statuses[server.id] = FleetServerStatus(
          serverId: server.id,
          connectivity: FleetServerConnectivity.offline,
        );
        return;
      }

      final client = await ApiClientManager.getClient(
        serverWithCredentials,
      ).timeout(timeout);
      if (client == null) {
        _statuses[server.id] = FleetServerStatus(
          serverId: server.id,
          connectivity: FleetServerConnectivity.offline,
        );
        return;
      }
      checkedOutServerId = server.id;

      final health = await client.getServerHealth().timeout(timeout);

      var activeAlertCount = 0;
      try {
        final rawAlerts = await client.getAlerts().timeout(timeout);
        activeAlertCount = rawAlerts
            .map(Alert.fromJson)
            .where((alert) => !alert.dismissed)
            .length;
      } catch (e) {
        // Alerts are a bonus signal for this snapshot - a server that
        // answers system health but not alert.list (permissions, an older
        // middleware version) still counts as online.
        if (kDebugMode) {
          print(
            'FleetStatusProvider: Failed to load alerts for '
            '${server.id}: $e',
          );
        }
      }

      _statuses[server.id] = FleetServerStatus(
        serverId: server.id,
        connectivity: FleetServerConnectivity.online,
        cpuUsage: health.cpuUsage,
        storageUsage: health.diskUsage,
        activeAlertCount: activeAlertCount,
      );
    } catch (e) {
      _statuses[server.id] = FleetServerStatus(
        serverId: server.id,
        connectivity: FleetServerConnectivity.offline,
      );
      if (kDebugMode) {
        print('FleetStatusProvider: Failed to refresh ${server.id}: $e');
      }
    } finally {
      if (checkedOutServerId != null) {
        await ApiClientManager.releaseClient(checkedOutServerId);
      }
      notifyListeners();
    }
  }

  /// Seeds a status directly, bypassing the network round trip, so widget
  /// tests can render the fleet-aware list without a live server.
  @visibleForTesting
  void debugSetStatus(FleetServerStatus status) {
    _statuses[status.serverId] = status;
    notifyListeners();
  }
}
