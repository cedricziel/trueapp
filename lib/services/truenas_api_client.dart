import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_otel/flutter_otel.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/pool.dart';
import 'package:truehub/models/service_status.dart';
import 'package:truehub/models/server_health.dart';
import 'package:truehub/models/file_item.dart';
import 'package:truehub/models/user_info.dart';
import 'package:truehub/models/connection_error.dart';
import 'package:truehub/models/alert.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/models/job.dart';
import 'package:truehub/models/system_stats.dart';
import 'package:truehub/services/network_service.dart';
import 'package:truehub/services/api/area_apis.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/providers/connection_status_provider.dart';
import 'package:truehub/services/telemetry_service_interface.dart';

part 'truenas_api_client/error_mapping.dart';
part 'truenas_api_client/connection.dart';
part 'truenas_api_client/keepalive.dart';
part 'truenas_api_client/session.dart';
part 'truenas_api_client/health.dart';
part 'truenas_api_client/pools.dart';
part 'truenas_api_client/datasets.dart';
part 'truenas_api_client/files.dart';
part 'truenas_api_client/apps.dart';
part 'truenas_api_client/system_stats.dart';
part 'truenas_api_client/app_stats.dart';
part 'truenas_api_client/jobs.dart';

/// Coalesces concurrent launches of one async operation: while a run is in
/// flight every caller shares its future, and completion (success or failure)
/// re-arms the latch for the next run. Used for connect, authenticate and
/// reconnect, where overlapping runs would clobber the shared socket state.
class _InFlight {
  Future<void>? _future;

  Future<void> run(Future<void> Function() op) =>
      _future ??= op().whenComplete(() => _future = null);

  /// Waits for any in-flight run to settle, swallowing its error - the
  /// callers that joined the run via [run] still receive it.
  Future<void> settle() async {
    try {
      await _future;
    } catch (_) {
      // Reported to the run's own callers.
    }
  }
}

/// Connection state, subscription bookkeeping and the hooks the transport
/// mixins in `truenas_api_client/` share. The subscription methods themselves
/// live in the area mixins; the base only needs to restore and tear them down.
abstract class _ClientBase
    with _ErrorMapping
    implements SystemStatsApi, AppStatsApi, JobsApi {
  final NasServer _server;
  final NetworkService _networkService = NetworkService();
  final ConnectionStatusProvider? _connectionStatusProvider;
  final TelemetryServiceInterface? _telemetry;
  Peer? _client;
  WebSocketChannel? _wsChannel;
  bool _isAuthenticated = false;
  String? _currentConnectionUrl;
  bool? _isLocalConnection;

  // System stats subscription management
  StreamController<SystemStats>? _systemStatsController;
  String? _realtimeSubscriptionId;
  bool _isSubscribedToRealtime = false;

  /// What the UI asked for, as opposed to what is currently live on the
  /// socket. A subscription that fails to restore is still wanted, so it must
  /// outlive the connection that carried it.
  bool _wantsSystemStats = false;

  // App stats subscription management
  StreamController<Map<String, AppResourceUsage>>? _appStatsController;
  String? _appStatsSubscriptionId;
  bool _isSubscribedToAppStats = false;
  bool _wantsAppStats = false;

  // Job subscription management
  StreamController<List<Job>>? _jobsController;
  String? _jobsSubscriptionId;
  bool _isSubscribedToJobs = false;
  bool _wantsJobs = false;

  /// Jobs seen so far, keyed by id. `core.get_jobs` collection_update events
  /// carry one changed job at a time, so this is what turns those deltas into
  /// the full list [jobsStream] emits.
  final Map<int, Job> _jobsById = {};

  // Keepalive mechanism
  Timer? _keepaliveTimer;
  bool _keepaliveEnabled = true;
  Duration _keepaliveInterval = const Duration(seconds: 30);

  /// Start times of the requests (other than the keepalive ping itself)
  /// still waiting for a reply on the current socket. Each request gets its
  /// own grace window, so a newer request is not left unprotected because an
  /// older one has been hanging for longer than [busyGracePeriod].
  final List<DateTime> _inFlightRequestStarts = [];

  /// How long an in-flight request vouches for the socket. While a request is
  /// pending and younger than this, the keepalive does not probe or recover
  /// the connection: a large reply (`app.available` is the whole catalog,
  /// readmes included - megabytes over a cellular link) keeps the socket
  /// legitimately busy for longer than the ping timeout, and a pong queues
  /// behind it. Reconnecting in that state is what used to kill the pending
  /// request with "The client closed with pending request". After the grace
  /// period a hung request is no longer taken as a sign of life.
  Duration busyGracePeriod = const Duration(minutes: 3);

  bool _awaitingPong = false;

  _ClientBase(this._server, this._connectionStatusProvider, this._telemetry);

  /// Whether the JSON-RPC socket is currently usable.
  bool get _hasLiveConnection => _client != null && !_client!.isClosed;

  /// In-flight connection attempt shared by concurrent callers. Without this,
  /// parallel requests on a fresh client (e.g. AppProvider._loadAppsOnline's
  /// Future.wait) each open their own WebSocket and clobber [_client] and
  /// [_wsChannel] mid-handshake.
  final _connecting = _InFlight();

  /// In-flight authentication attempt, same coalescing as [_connecting].
  final _authenticating = _InFlight();

  /// Set for good once [close] starts. Recovery triggers (keepalive timeout,
  /// app-resume hook) check it so they cannot rebuild the session close is
  /// tearing down; on-demand requests keep their reconnect behaviour.
  bool _isClosing = false;

  /// Guards against two triggers (the keepalive timer and the app-resume
  /// hook) starting overlapping reconnects, which would open two sessions.
  final _recovery = _InFlight();

  /// True when the UI asked for a stream that is not live on this socket.
  bool get _hasMissingSubscription =>
      (_wantsSystemStats && !_isSubscribedToRealtime) ||
      (_wantsAppStats && !_isSubscribedToAppStats) ||
      (_wantsJobs && !_isSubscribedToJobs);

  /// Re-subscribes to the streams the UI had asked for before the connection
  /// was lost. The stale subscription ids belong to the dead socket.
  Future<void> _restoreSubscriptions() async {
    // Independent RPCs over an established session; no reason to serialise
    // them on a path where round trips already stack up. The intent flags stay
    // set: a restore that fails here is retried by the next recovery.
    await Future.wait([
      if (_wantsSystemStats && !_isSubscribedToRealtime)
        subscribeToSystemStats(),
      if (_wantsAppStats && !_isSubscribedToAppStats) subscribeToAppStats(),
      if (_wantsJobs && !_isSubscribedToJobs) subscribeToJobs(),
    ]);
  }

  void _setupCollectionUpdateHandler() {
    if (_client == null) return;

    // Register method to handle collection_update notifications from TrueNAS
    _client!.registerMethod('collection_update', (parameters) {
      try {
        final collection = parameters['collection'].value as String?;

        if (collection == 'reporting.realtime') {
          final fields = parameters['fields'].value as Map<String, dynamic>;
          final systemStats = SystemStats.fromJson(fields);
          _systemStatsController?.add(systemStats);

          if (kDebugMode) {
            print(
              'TrueNAS API: Received realtime stats - CPU: ${systemStats.cpu.overall.usage.toStringAsFixed(1)}%',
            );
          }
        } else if (collection == 'app.stats') {
          final fields = parameters['fields'].value as List<dynamic>;
          final appStatsMap = <String, AppResourceUsage>{};

          for (final appData in fields) {
            final appStats = appData as Map<String, dynamic>;
            final appName = appStats['app_name'] as String;

            // Extract network statistics
            final networks = appStats['networks'] as List<dynamic>? ?? [];
            var totalRxBytes = 0.0;
            var totalTxBytes = 0.0;

            for (final network in networks) {
              final networkData = network as Map<String, dynamic>;
              totalRxBytes +=
                  (networkData['rx_bytes'] as num?)?.toDouble() ?? 0.0;
              totalTxBytes +=
                  (networkData['tx_bytes'] as num?)?.toDouble() ?? 0.0;
            }

            final resourceUsage = AppResourceUsage(
              cpuUsage: (appStats['cpu_usage'] as num?)?.toDouble() ?? 0.0,
              memoryUsage: (appStats['memory'] as num?)?.toInt() ?? 0,
              memoryLimit: 0, // Not available in real-time stats
              networkRxBytes: totalRxBytes,
              networkTxBytes: totalTxBytes,
              lastUpdated: DateTime.now(),
            );

            appStatsMap[appName] = resourceUsage;
          }

          _appStatsController?.add(appStatsMap);

          if (kDebugMode) {
            print(
              'TrueNAS API: Received app stats for ${appStatsMap.length} apps',
            );
          }
        } else if (collection == 'core.get_jobs') {
          final fields = parameters['fields'].value as Map<String, dynamic>;
          final job = Job.fromJson(fields);
          _jobsById[job.id] = job;
          _jobsController?.add(_jobsById.values.toList());

          if (kDebugMode) {
            print(
              'TrueNAS API: Job #${job.id} (${job.method}) -> ${job.state}',
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('TrueNAS API: Error parsing collection_update: $e');
        }
      }
    });
  }
}

abstract class _ClientTransport = _ClientBase
    with _Connection, _KeepaliveAndRecovery, _SessionOps;

class TrueNasApiClient extends _ClientTransport
    with
        _HealthOps,
        _PoolsOps,
        _DatasetsOps,
        _FilesOps,
        _AppsOps,
        _SystemStatsOps,
        _AppStatsOps,
        _JobsOps
    implements ApiClientInterface {
  TrueNasApiClient(
    super.server, [
    super.connectionStatusProvider,
    super.telemetry,
  ]);
}
