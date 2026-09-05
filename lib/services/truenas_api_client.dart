import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_otel/flutter_otel.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/server_health.dart';
import 'package:truehub/models/file_item.dart';
import 'package:truehub/models/user_info.dart';
import 'package:truehub/models/connection_error.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/models/job.dart';
import 'package:truehub/models/system_stats.dart';
import 'package:truehub/services/network_service.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/providers/connection_status_provider.dart';
import 'package:truehub/services/telemetry_service_interface.dart';

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

class TrueNasApiClient implements ApiClientInterface {
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

  TrueNasApiClient(
    this._server, [
    this._connectionStatusProvider,
    this._telemetry,
  ]);

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

  Future<void> _ensureConnected() {
    if (_hasLiveConnection) {
      return Future.value();
    }
    return _connecting.run(_connect);
  }

  /// Only called through [_ensureConnected], which owns the already-connected
  /// check and the coalescing of concurrent attempts.
  Future<void> _connect() async {
    final telemetry = _telemetry;
    if (telemetry == null) {
      return _ensureConnectedTraced(null);
    }

    return telemetry.getTracer().startActiveSpan(
      'truenas.connect',
      (span) => _ensureConnectedTraced(span),
      kind: SpanKind.client,
      attributes: {'server.id': _server.id},
    );
  }

  /// The body of [_ensureConnected]. [span] is the active span for this
  /// connection attempt when telemetry is wired up, or `null` when it isn't
  /// - every telemetry touch below is guarded on it so this method's
  /// behaviour is identical either way beyond that instrumentation.
  Future<void> _ensureConnectedTraced(Span? span) async {
    _connectionStatusProvider?.updateConnectionState(
      _server.id,
      TrueNASConnectionState.connecting,
    );

    try {
      // Determine the appropriate URL based on network context
      final isOnTrustedNetwork = await _networkService.isOnTrustedNetwork(
        _server.trustedWifiSsids,
      );
      final baseUrl = _server.getUrlForNetwork(
        isOnTrustedNetwork: isOnTrustedNetwork,
      );

      final wsUrl = '${baseUrl.replaceFirst('http', 'ws')}/api/current';
      _currentConnectionUrl = baseUrl;
      _isLocalConnection = isOnTrustedNetwork;

      // Not the URL itself - it can carry user-info/credentials-shaped query
      // parameters - just whether this connection stayed on the trusted LAN.
      span?.setAttribute('server.network.trusted', isOnTrustedNetwork);

      if (kDebugMode) {
        print('TrueNAS API: Connecting to WebSocket: $wsUrl');
        print(
          'TrueNAS API: Using ${isOnTrustedNetwork ? 'local' : 'remote'} URL',
        );
      }

      // Connect with timeout to detect network issues early
      _wsChannel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
        protocols: ['json-rpc'],
      );

      // WebSocketChannel.connect is lazy: without awaiting readiness a failed
      // handshake surfaces as an unhandled asynchronous error instead of a
      // failure the caller can act on.
      await _wsChannel!.ready.timeout(const Duration(seconds: 15));

      _client = Peer(_wsChannel!.cast<String>());

      // Register method to handle collection_update notifications from server
      _setupCollectionUpdateHandler();

      // Start listening for responses with error handling
      // Socket-level failures arrive here asynchronously, with no caller to
      // receive them: rethrowing would only produce an unhandled zone error.
      // Record the state instead - the next request (or the resume hook) sees
      // the closed client and recovers.
      unawaited(
        _client!.listen().catchError((error) {
          if (kDebugMode) {
            print('TrueNAS API: WebSocket error: $error');
          }
          _isAuthenticated = false;
          _connectionStatusProvider?.updateConnectionState(
            _server.id,
            TrueNASConnectionState.error,
            error: error.toString(),
          );
        }),
      );

      _isAuthenticated = false;
      if (kDebugMode) {
        print('TrueNAS API: WebSocket connection established and listening');
      }
      span?.setStatus(StatusCode.ok);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('TrueNAS API: Connection failed: $e');
      }

      // Drop the half-open channel. Keeping it means a later close() awaits a
      // handshake that never completed, which never returns.
      final failedChannel = _wsChannel;
      _wsChannel = null;
      _client = null;
      _isAuthenticated = false;
      unawaited(failedChannel?.sink.close().catchError((_) {}));

      _connectionStatusProvider?.updateConnectionState(
        _server.id,
        TrueNASConnectionState.error,
        error: e.toString(),
      );
      // The span's own exception/error-status recording is handled by
      // Tracer.startActiveSpan's contract (it records whatever this method
      // throws and marks the span an error) - this only needs to get the
      // failure into the logs signal too.
      _telemetry?.getLogger().error(
        'TrueNAS API: Connection failed',
        error: e,
        stackTrace: stackTrace,
        attributes: {'server.id': _server.id},
      );
      throw _handleConnectionError(e);
    }
  }

  /// Runs [body] in a CLIENT span named [spanName] (a no-op wrapper when
  /// telemetry isn't wired up) and logs a failure via the telemetry Logger
  /// before rethrowing.
  ///
  /// `truenas.connect` (above) only covers establishing the socket and
  /// authenticating - it was added to diagnose "failed to load apps"
  /// reports, but a request that connects and authenticates fine and then
  /// fails while parsing the *response* (e.g. an app whose `last_update`
  /// or `resources` shape TrueNAS returns differently than expected) threw
  /// past that span entirely, with nothing recording what broke. Wrapping
  /// the request+parse methods themselves closes that gap.
  Future<T> _traced<T>(String spanName, Future<T> Function() body) async {
    final telemetry = _telemetry;
    if (telemetry == null) {
      return body();
    }

    return telemetry.getTracer().startActiveSpan(
      spanName,
      (span) async {
        try {
          final result = await body();
          span.setStatus(StatusCode.ok);
          return result;
        } catch (e, stackTrace) {
          // The span's own exception/error-status recording is handled by
          // Tracer.startActiveSpan's contract - this only needs to get the
          // failure into the logs signal too.
          telemetry.getLogger().error(
            'TrueNAS API: $spanName failed',
            error: e,
            stackTrace: stackTrace,
            attributes: {'server.id': _server.id},
          );
          rethrow;
        }
      },
      kind: SpanKind.client,
      attributes: {'server.id': _server.id},
    );
  }

  void _startKeepalive() {
    if (!_keepaliveEnabled || _keepaliveTimer != null) {
      return;
    }

    if (kDebugMode) {
      print(
        'TrueNAS API: Starting keepalive with ${_keepaliveInterval.inSeconds}s interval',
      );
    }

    _keepaliveTimer = Timer.periodic(_keepaliveInterval, (_) {
      _sendKeepalivePing();
    });
  }

  void _stopKeepalive() {
    _keepaliveTimer?.cancel();
    _keepaliveTimer = null;
    _awaitingPong = false;

    if (kDebugMode) {
      print('TrueNAS API: Stopped keepalive');
    }
  }

  /// Sends [method] over the current socket, tracking it as in flight for
  /// the keepalive's sake (see [busyGracePeriod]). Every application request
  /// goes through here; the keepalive ping itself does not.
  Future<dynamic> _request(String method, [dynamic parameters]) async {
    final startedAt = DateTime.now();
    _inFlightRequestStarts.add(startedAt);
    try {
      return await _client!.sendRequest(method, parameters);
    } finally {
      _inFlightRequestStarts.remove(startedAt);
    }
  }

  /// True while any request younger than [busyGracePeriod] is still waiting
  /// for its reply - evidence the socket is in use, not dead.
  bool get _isBusyWithinGrace {
    final now = DateTime.now();
    return _inFlightRequestStarts.any(
      (startedAt) => now.difference(startedAt) < busyGracePeriod,
    );
  }

  Future<void> _sendKeepalivePing() async {
    // A closed socket is precisely the case that needs recovering. Returning
    // here (as this used to) left the client dead until something else
    // happened to issue a request.
    if (!_hasLiveConnection || !_isAuthenticated) {
      await _handleKeepaliveTimeout();
      return;
    }

    // Don't probe a socket that is busy serving a request: the pong would
    // only queue behind the pending reply, and a timeout here would tear
    // down the very connection that request is waiting on.
    if (_isBusyWithinGrace) {
      if (kDebugMode) {
        print('TrueNAS API: Skipping keepalive ping, a request is in flight');
      }
      return;
    }

    if (_awaitingPong) {
      if (kDebugMode) {
        print(
          'TrueNAS API: Keepalive timeout - no pong received, reconnecting...',
        );
      }
      await _handleKeepaliveTimeout();
      return;
    }

    try {
      _awaitingPong = true;
      final pingTime = DateTime.now();

      if (kDebugMode) {
        print('TrueNAS API: Sending keepalive ping');
      }

      _connectionStatusProvider?.updatePingStatus(
        _server.id,
        pingSent: pingTime,
      );

      final result = await _client!
          .sendRequest('core.ping', [])
          .timeout(const Duration(seconds: 10));

      if (result == 'pong') {
        final pongTime = DateTime.now();
        final latency = pongTime.difference(pingTime);
        _awaitingPong = false;

        _connectionStatusProvider?.updatePingStatus(
          _server.id,
          pongReceived: pongTime,
          latency: latency,
        );

        if (kDebugMode) {
          print(
            'TrueNAS API: Received keepalive pong (${latency.inMilliseconds}ms)',
          );
        }
      } else {
        if (kDebugMode) {
          print('TrueNAS API: Unexpected keepalive response: $result');
        }
        _awaitingPong = false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Keepalive ping failed: $e');
      }
      // A request that started after this ping went out can hold the pong
      // up just the same; it vouches for the socket, so don't reconnect.
      if (_isBusyWithinGrace) {
        _awaitingPong = false;
        return;
      }
      await _handleKeepaliveTimeout();
    }
  }

  /// Guards against two triggers (the keepalive timer and the app-resume
  /// hook) starting overlapping reconnects, which would open two sessions.
  final _recovery = _InFlight();

  Future<void> _handleKeepaliveTimeout() {
    if (_isClosing) return Future.value();
    return _recovery.run(_recoverConnection);
  }

  Future<void> _recoverConnection() async {
    _awaitingPong = false;

    if (kDebugMode) {
      print('TrueNAS API: Keepalive failed, attempting reconnection');
    }

    _connectionStatusProvider?.updateConnectionState(
      _server.id,
      TrueNASConnectionState.reconnecting,
    );

    // Reset connection state. The subscriptions belonged to the socket that
    // just died; what the UI wants (_wantsSystemStats / _wantsAppStats) is
    // deliberately untouched so it can be restored below.
    _isSubscribedToRealtime = false;
    _realtimeSubscriptionId = null;
    _isSubscribedToAppStats = false;
    _appStatsSubscriptionId = null;
    _isSubscribedToJobs = false;
    _jobsSubscriptionId = null;

    try {
      // The session this recovery was invoked for is no longer trusted, even
      // when its Peer hasn't noticed the death yet (a timed-out ping on a
      // zombie socket leaves isClosed false). Only a login that completes
      // during the settle below may vouch for the session again.
      _isAuthenticated = false;

      // A connect or login already in flight is building the fresh session
      // this recovery wants. Let it settle instead of closing its socket
      // mid-handshake - tearing down here would kill the handshake, and
      // _ensureConnected below would then adopt that same doomed future.
      await _connecting.settle();
      await _authenticating.settle();

      if (!(_hasLiveConnection && _isAuthenticated)) {
        _isAuthenticated = false;

        // Detach and close only the stale session: awaiting a close yields,
        // and a concurrent request may assign a fresh channel to these
        // fields in the meantime - that one must survive.
        final staleClient = _client;
        final staleChannel = _wsChannel;
        _client = null;
        _wsChannel = null;
        await staleClient?.close();
        await staleChannel?.sink.close();

        // Re-establish connection
        await _ensureConnected();
        await _ensureAuthenticated();
      }
      await _restoreSubscriptions();

      _connectionStatusProvider?.updateConnectionState(
        _server.id,
        TrueNASConnectionState.connected,
      );

      if (kDebugMode) {
        print('TrueNAS API: Successfully reconnected after keepalive timeout');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Failed to reconnect after keepalive timeout: $e');
      }
      _connectionStatusProvider?.updateConnectionState(
        _server.id,
        TrueNASConnectionState.error,
        error: e.toString(),
      );
      // Stop keepalive on repeated failures to avoid continuous retry loops
      _stopKeepalive();
    }
  }

  /// Makes the client usable again after the connection may have died while
  /// the app was suspended.
  ///
  /// Cheap when the socket is healthy (a single ping); reconnects,
  /// re-authenticates and restores active subscriptions when it is not.
  /// Call this when the app returns to the foreground - no timer fires while
  /// the process is suspended, so nothing else notices the dead socket.
  /// True when the UI asked for a stream that is not live on this socket.
  bool get _hasMissingSubscription =>
      (_wantsSystemStats && !_isSubscribedToRealtime) ||
      (_wantsAppStats && !_isSubscribedToAppStats) ||
      (_wantsJobs && !_isSubscribedToJobs);

  @override
  Future<void> ensureConnectionAlive() async {
    // A closing client has nothing to keep alive.
    if (_isClosing) return;

    // _sendKeepalivePing already owns the "is this connection usable, and
    // recover it if not" decision; don't restate it here.
    await _sendKeepalivePing();

    // A healthy socket is not enough: a stream the UI wants may have failed to
    // restore on an earlier attempt, and the ping cannot see that. A refusal
    // here is a partial failure - the connection is fine and the intent is
    // kept, so the next attempt retries it - and must not be reported as a
    // lost connection.
    if (_hasLiveConnection && _isAuthenticated && _hasMissingSubscription) {
      try {
        await _restoreSubscriptions();
      } catch (e) {
        if (kDebugMode) {
          print('TrueNAS API: Subscription restore deferred: $e');
        }
      }
    }

    // Recovery reports its own failures to the connection status provider and
    // does not rethrow, because the periodic timer must not die on a blip. A
    // caller that asked for a usable connection needs the bad news.
    if (!_hasLiveConnection || !_isAuthenticated) {
      throw ConnectionException(
        ConnectionError.networkUnreachable(
          details: 'Could not restore the connection to ${_server.name}',
        ),
      );
    }
  }

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

  @override
  void setKeepaliveInterval(Duration interval) {
    _keepaliveInterval = interval;

    if (_keepaliveTimer != null) {
      _stopKeepalive();
      _startKeepalive();
    }
  }

  @override
  void enableKeepalive(bool enabled) {
    _keepaliveEnabled = enabled;

    if (enabled && _isAuthenticated) {
      _startKeepalive();
    } else {
      _stopKeepalive();
    }
  }

  @override
  bool get isKeepaliveActive => _keepaliveTimer?.isActive ?? false;

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

  Future<void> _ensureAuthenticated() {
    // Authentication belongs to a socket: once that socket is gone, so is the
    // session, no matter what the flag from the previous connection says.
    if (_isAuthenticated && _hasLiveConnection) return Future.value();
    return _authenticating.run(_authenticate);
  }

  /// Only called through [_ensureAuthenticated], which owns the
  /// already-authenticated check and the coalescing of concurrent attempts.
  Future<void> _authenticate() async {
    _isAuthenticated = false;

    try {
      await _ensureConnected();
      if (kDebugMode) {
        print(
          'TrueNAS API: Attempting authentication for user: ${_server.username}',
        );
      }

      final result = await _client!
          .sendRequest('auth.login', [_server.username, _server.password])
          .timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        print('TrueNAS API: Authentication result: $result');
      }

      if (result != true) {
        throw ConnectionException(
          ConnectionError.invalidCredentials(
            details: 'Server returned: $result',
          ),
        );
      }

      _isAuthenticated = true;
      if (kDebugMode) {
        print('TrueNAS API: Successfully authenticated');
      }

      // Update connection status to connected
      _connectionStatusProvider?.updateConnectionState(
        _server.id,
        TrueNASConnectionState.connected,
        connectionUrl: _currentConnectionUrl,
        isLocalConnection: _isLocalConnection,
      );

      // Start keepalive after successful authentication
      _startKeepalive();

      // Send immediate ping to get initial connection status
      _sendKeepalivePing();
    } on TimeoutException {
      throw ConnectionException(
        ConnectionError.connectionTimeout(
          details: 'Authentication request timed out after 15 seconds',
        ),
      );
    } catch (e) {
      if (e is ConnectionException) {
        rethrow;
      }
      throw _handleConnectionError(e);
    }
  }

  @override
  Future<void> close() async {
    // Refuse recovery work from here on: a keepalive timeout or app-resume
    // hook firing during the awaits below must not rebuild the session this
    // close is tearing down. Set before the first await so nothing sneaks
    // in between.
    _isClosing = true;

    // Let in-flight work settle first, so this close tears down the socket
    // those attempts produce instead of racing their handshakes - which
    // would leak the socket and the keepalive timer a successful login
    // starts.
    await _recovery.settle();
    await _connecting.settle();
    await _authenticating.settle();

    _stopKeepalive();
    _connectionStatusProvider?.updateConnectionState(
      _server.id,
      TrueNASConnectionState.disconnected,
    );
    await unsubscribeFromSystemStats();
    await unsubscribeFromAppStats();
    await unsubscribeFromJobs();
    final staleClient = _client;
    final staleChannel = _wsChannel;
    _client = null;
    _wsChannel = null;
    _isAuthenticated = false;
    await staleClient?.close();
    await staleChannel?.sink.close();
  }

  // Authentication methods
  @override
  Future<bool> validateLogin(
    String username,
    String password, [
    String? otpToken,
  ]) async {
    try {
      await _ensureConnected();
      if (kDebugMode) {
        print('TrueNAS API: Validating login for user: $username');
      }
      final result = await _client!
          .sendRequest('auth.login', [username, password, ?otpToken])
          .timeout(const Duration(seconds: 10));
      if (kDebugMode) {
        print('TrueNAS API: Login validation result: $result');
      }
      return result as bool;
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Login validation failed: $e');
      }
      return false;
    }
  }

  @override
  Future<UserInfo> getCurrentUser() async {
    try {
      await _ensureAuthenticated();
      final result = await _request('auth.me');
      return UserInfo.fromJson(result as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // System information methods
  @override
  Future<Map<String, dynamic>> getSystemInfo() async {
    try {
      await _ensureAuthenticated();
      final result = await _request('system.info');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getSystemCpuInfo() async {
    try {
      await _ensureAuthenticated();
      final result = await _request('system.cpu_info');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getSystemMemoryInfo() async {
    try {
      await _ensureAuthenticated();
      final result = await _request('system.memory_info');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<double> getSystemTemperature() async {
    try {
      await _ensureAuthenticated();
      final result = await _request('system.temperature');
      return (result as num).toDouble();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Pool management methods
  @override
  Future<List<Map<String, dynamic>>> queryPools() async {
    try {
      await _ensureAuthenticated();
      final result = await _request('pool.query');
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getPoolById(String id) async {
    try {
      await _ensureAuthenticated();
      final result = await _request('pool.query', {'id': id});
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Dataset management methods
  @override
  Future<List<Map<String, dynamic>>> queryDatasets() async {
    try {
      await _ensureAuthenticated();
      final result = await _request('pool.dataset.query');
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getDatasetById(String id) async {
    try {
      await _ensureAuthenticated();
      final result = await _request('pool.dataset.query', {'id': id});
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // File system methods
  @override
  Future<List<Map<String, dynamic>>> listDirectory(String path) async {
    try {
      await _ensureAuthenticated();
      final result = await _request('filesystem.listdir', {'path': path});
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getFileInfo(String path) async {
    try {
      await _ensureAuthenticated();
      final result = await _request('filesystem.stat', {'path': path});
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Disk information methods
  @override
  Future<List<Map<String, dynamic>>> queryDisks() async {
    try {
      await _ensureAuthenticated();
      final result = await _request('disk.query');
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getDiskById(String id) async {
    try {
      await _ensureAuthenticated();
      final result = await _request('disk.query', {'id': id});
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Network information methods
  @override
  Future<Map<String, dynamic>> getNetworkInfo() async {
    try {
      await _ensureAuthenticated();
      final result = await _request('network.general.summary');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getNetworkInterfaces() async {
    try {
      await _ensureAuthenticated();
      final result = await _request('interface.query');
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Higher-level methods
  @override
  Future<ServerHealth> getServerHealth() async {
    try {
      await getSystemInfo();
      final cpuInfo = await getSystemCpuInfo();
      final memoryInfo = await getSystemMemoryInfo();
      final diskInfo = await queryDisks();
      final temperature = await getSystemTemperature();
      final networkInfo = await getNetworkInfo();

      return ServerHealth(
        serverId: _server.id,
        timestamp: DateTime.now(),
        cpuUsage: _extractCpuUsage(cpuInfo),
        memoryUsage: _extractMemoryUsage(memoryInfo),
        diskUsage: _extractDiskUsage(diskInfo),
        temperature: temperature.toInt(),
        isOnline: true,
        disks: _extractDisks(diskInfo),
        network: _extractNetwork(networkInfo),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAlerts() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('alert.list');
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getServices() async {
    try {
      await _ensureAuthenticated();
      final result = await _client!.sendRequest('service.query');
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<FileItem>> getDirectoryListing(String path) async {
    try {
      final response = await listDirectory(path);
      return response.map((item) => FileItem.fromJson(item)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPools() async {
    try {
      return await queryPools();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getDatasets() async {
    try {
      return await queryDatasets();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      await getSystemInfo().timeout(const Duration(seconds: 10));
      return true;
    } catch (e) {
      return false;
    }
  }

  // App management methods
  @override
  Future<List<App>> getAvailableApps() async {
    try {
      return await _traced('truenas.apps.available', () async {
        await _ensureAuthenticated();
        final result = await _request('app.available');
        return _parseAppList(result, App.fromJson, method: 'app.available');
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<App>> getInstalledApps() async {
    try {
      return await _traced('truenas.apps.installed', () async {
        await _ensureAuthenticated();
        final result = await _request('app.query');
        return _parseAppList(
          result,
          _convertTrueNasAppToApp,
          method: 'app.query',
        );
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Parses a list-of-apps response entry by entry, so one app the server
  /// describes in an unexpected shape doesn't take the whole list down with
  /// it. TrueNAS has changed individual fields across releases more than
  /// once (`last_update`, `last_updated`, ...) and every such change used to
  /// surface as a bare "Connection error" for *all* apps. A skipped entry is
  /// logged with its name and cause; only when nothing at all could be
  /// parsed does this throw, since that means the whole response shape is
  /// off rather than one entry.
  List<App> _parseAppList(
    Object? result,
    App Function(Map<String, dynamic>) parse, {
    required String method,
  }) {
    if (result is! List) {
      throw FormatException(
        '$method: expected a list of apps, got ${result.runtimeType}',
      );
    }

    final apps = <App>[];
    Object? firstFailure;
    StackTrace? firstStackTrace;
    String? firstFailedName;
    var skipped = 0;
    for (final entry in result) {
      try {
        if (entry is! Map) {
          throw FormatException(
            'expected an app object, got ${entry.runtimeType}',
          );
        }
        apps.add(parse(Map<String, dynamic>.from(entry)));
      } catch (e, stackTrace) {
        skipped++;
        if (firstFailure == null) {
          firstFailure = e;
          firstStackTrace = stackTrace;
          firstFailedName = entry is Map ? entry['name']?.toString() : null;
        }
      }
    }

    // One record per response, not per entry: a field that changed shape in
    // a newer TrueNAS fails every entry the same way, and the catalog is
    // re-fetched on every refresh.
    if (skipped > 0) {
      if (kDebugMode) {
        print(
          'TrueNAS API: $method: skipped $skipped of ${result.length} app '
          'entries, first failure ("$firstFailedName"): $firstFailure',
        );
      }
      _telemetry?.getLogger().error(
        'TrueNAS API: $method returned app entries that could not be '
        'parsed; skipped them',
        error: firstFailure,
        stackTrace: firstStackTrace,
        attributes: {
          'server.id': _server.id,
          'truenas.method': method,
          'truenas.apps.skipped': skipped,
          'truenas.apps.total': result.length,
          'truenas.app.name': firstFailedName ?? '',
        },
      );
    }

    if (apps.isEmpty && skipped > 0) {
      throw FormatException(
        '$method: none of the $skipped app entries could be parsed: '
        '$firstFailure',
      );
    }
    return apps;
  }

  /// Convert TrueNAS app query response to our App model
  App _convertTrueNasAppToApp(Map<String, dynamic> trueNasApp) {
    // Extract upgrade info from the response
    final upgradeInfo = AppUpgradeInfo(
      upgradeAvailable: trueNasApp['upgrade_available'] as bool? ?? false,
      availableVersion: trueNasApp['latest_version'] as String?,
      currentVersion: trueNasApp['version'] as String?,
      upgradeNotes: null, // Not available in TrueNAS response
      canUpgrade:
          (trueNasApp['upgrade_available'] as bool? ?? false) &&
          (trueNasApp['state'] as String?) == 'RUNNING',
    );

    // Extract resource usage from limits (not real-time usage)
    AppResourceUsage? resourceUsage;
    final resources = trueNasApp['resources'] as Map<String, dynamic>?;
    if (resources != null) {
      final limits = resources['limits'] as Map<String, dynamic>?;
      if (limits != null) {
        resourceUsage = AppResourceUsage(
          cpuUsage: 0.0, // Not available in real-time
          memoryUsage: 0, // Not available in real-time
          memoryLimit: (limits['memory'] as num?)?.toInt() ?? 0,
          networkRxBytes: 0.0, // Not available
          networkTxBytes: 0.0, // Not available
          lastUpdated: DateTime.now(),
        );
      }
    }

    // Extract port information from active_workloads
    final activeWorkloads =
        trueNasApp['active_workloads'] as Map<String, dynamic>?;
    final usedPorts = <AppPortInfo>[];
    if (activeWorkloads != null) {
      final usedPortsData =
          activeWorkloads['used_ports'] as List<dynamic>? ?? [];
      for (final portData in usedPortsData) {
        usedPorts.add(AppPortInfo.fromJson(portData as Map<String, dynamic>));
      }
    }

    // Extract portal information
    final portals =
        (trueNasApp['portals'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, value.toString()),
        ) ??
        <String, String>{};

    // Extract metadata for app information
    final metadata = trueNasApp['metadata'] as Map<String, dynamic>?;

    // Extract commonly used values
    final appName = trueNasApp['name'] as String? ?? '';
    final appState = trueNasApp['state'] as String?;
    final isHealthy = appState == 'RUNNING';
    final healthError = !isHealthy
        ? 'App is ${appState?.toLowerCase() ?? 'stopped'}'
        : null;

    return App(
      name: appName,
      title: metadata?['title'] as String? ?? appName,
      description: metadata?['description'] as String? ?? '',
      installed: true, // These are installed apps
      healthy: isHealthy,
      healthyError: healthError,
      latestVersion: trueNasApp['latest_version'] as String? ?? '',
      latestAppVersion: metadata?['app_version'] as String? ?? '',
      latestHumanVersion: trueNasApp['human_version'] as String? ?? '',
      iconUrl: metadata?['icon'] as String?,
      categories:
          (metadata?['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      home: metadata?['home'] as String?,
      tags:
          (metadata?['keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      screenshots:
          (metadata?['screenshots'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      sources:
          (metadata?['sources'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      appReadme: null, // Not available in this response
      maintainers:
          (metadata?['maintainers'] as List<dynamic>?)
              ?.map((e) => AppMaintainer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdate: null, // Not available in this response format
      recommended: false, // Not available in this response
      catalog: 'community', // Default, not available in this response
      train: metadata?['train'] as String? ?? 'community',
      resourceUsage: resourceUsage,
      upgradeInfo: upgradeInfo,
      usedPorts: usedPorts,
      portals: portals,
    );
  }

  @override
  Future<List<String>> getAppCategories() async {
    try {
      return await _traced('truenas.apps.categories', () async {
        await _ensureAuthenticated();
        final result = await _request('app.categories');
        return (result as List<dynamic>).cast<String>();
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getDockerStatus() async {
    try {
      await _ensureAuthenticated();
      final result = await _request('docker.status');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getAppResourceUsage(String appName) async {
    // This method is not available in TrueNAS API
    // Resource usage is extracted from app.query response instead
    return {
      'cpu_usage': 0.0,
      'memory_usage': 0,
      'memory_limit': 0,
      'network_rx_bytes': 0.0,
      'network_tx_bytes': 0.0,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<Map<String, dynamic>> getAppUpgradeInfo(String appName) async {
    // This method is not available in TrueNAS API
    // Upgrade info is extracted from app.query response instead
    return {
      'upgrade_available': false,
      'available_version': null,
      'current_version': null,
      'upgrade_notes': null,
      'can_upgrade': false,
    };
  }

  @override
  Future<bool> upgradeApp(String appName, {String? version}) async {
    try {
      await _ensureAuthenticated();
      // The TrueNAS API takes just the app name as a string parameter
      final result = await _request('app.upgrade', [appName]);
      // The upgrade method returns the app object on success, so we check if it's not null
      return result != null;
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Failed to upgrade app $appName: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> startApp(String appName) async {
    try {
      await _ensureAuthenticated();
      final result = await _request('app.start', [appName]);
      return result != null;
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Failed to start app $appName: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> stopApp(String appName) async {
    try {
      await _ensureAuthenticated();
      final result = await _request('app.stop', [appName]);
      return result != null;
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Failed to stop app $appName: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> restartApp(String appName) async {
    try {
      await _ensureAuthenticated();
      final result = await _request('app.restart', [appName]);
      return result != null;
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Failed to restart app $appName: $e');
      }
      return false;
    }
  }

  // System stats subscription methods
  @override
  Stream<SystemStats> get systemStatsStream {
    _systemStatsController ??= StreamController<SystemStats>.broadcast();
    return _systemStatsController!.stream;
  }

  @override
  Future<void> subscribeToSystemStats() async {
    // A subscription only exists for as long as the socket that created it.
    // After the connection drops - which is what the OS does to a backgrounded
    // app - the flag is stale and re-subscribing is exactly what's needed.
    _wantsSystemStats = true;

    if (_isSubscribedToRealtime && _hasLiveConnection) {
      if (kDebugMode) {
        print('TrueNAS API: Already subscribed to realtime stats');
      }
      return;
    }

    _isSubscribedToRealtime = false;
    _realtimeSubscriptionId = null;

    try {
      await _ensureAuthenticated();

      _systemStatsController ??= StreamController<SystemStats>.broadcast();

      // Subscribe to realtime reporting data
      _realtimeSubscriptionId =
          await _request('core.subscribe', ['reporting.realtime']) as String;

      if (kDebugMode) {
        print(
          'TrueNAS API: Subscribed to realtime stats with ID: $_realtimeSubscriptionId',
        );
      }

      _isSubscribedToRealtime = true;

      if (kDebugMode) {
        print('TrueNAS API: Successfully subscribed to system stats stream');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Failed to subscribe to system stats: $e');
      }
      throw _handleError(e);
    }
  }

  @override
  Future<void> unsubscribeFromSystemStats() async {
    if (!_isSubscribedToRealtime || _realtimeSubscriptionId == null) {
      return;
    }

    try {
      if (_hasLiveConnection) {
        await _request('core.unsubscribe', [_realtimeSubscriptionId!]);

        if (kDebugMode) {
          print(
            'TrueNAS API: Unsubscribed from realtime stats with ID: $_realtimeSubscriptionId',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Error unsubscribing from system stats: $e');
      }
    } finally {
      _wantsSystemStats = false;
      _isSubscribedToRealtime = false;
      _realtimeSubscriptionId = null;
      await _systemStatsController?.close();
      _systemStatsController = null;

      if (kDebugMode) {
        print('TrueNAS API: System stats subscription cleaned up');
      }
    }
  }

  // App stats subscription methods
  @override
  Stream<Map<String, AppResourceUsage>> get appStatsStream {
    _appStatsController ??=
        StreamController<Map<String, AppResourceUsage>>.broadcast();
    return _appStatsController!.stream;
  }

  @override
  Future<void> subscribeToAppStats() async {
    _wantsAppStats = true;

    if (_isSubscribedToAppStats && _hasLiveConnection) {
      if (kDebugMode) {
        print('TrueNAS API: Already subscribed to app stats');
      }
      return;
    }

    try {
      await _ensureAuthenticated();

      _appStatsController ??=
          StreamController<Map<String, AppResourceUsage>>.broadcast();

      // Subscribe to app stats data
      _appStatsSubscriptionId =
          await _request('core.subscribe', ['app.stats']) as String;

      if (kDebugMode) {
        print(
          'TrueNAS API: Subscribed to app stats with ID: $_appStatsSubscriptionId',
        );
      }

      _isSubscribedToAppStats = true;

      if (kDebugMode) {
        print('TrueNAS API: Successfully subscribed to app stats stream');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Failed to subscribe to app stats: $e');
      }
      throw _handleError(e);
    }
  }

  @override
  Future<void> unsubscribeFromAppStats() async {
    if (!_isSubscribedToAppStats || _appStatsSubscriptionId == null) {
      return;
    }

    try {
      if (_hasLiveConnection) {
        await _request('core.unsubscribe', [_appStatsSubscriptionId!]);

        if (kDebugMode) {
          print(
            'TrueNAS API: Unsubscribed from app stats with ID: $_appStatsSubscriptionId',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Error unsubscribing from app stats: $e');
      }
    } finally {
      _wantsAppStats = false;
      _isSubscribedToAppStats = false;
      _appStatsSubscriptionId = null;
      await _appStatsController?.close();
      _appStatsController = null;

      if (kDebugMode) {
        print('TrueNAS API: App stats subscription cleaned up');
      }
    }
  }

  // System information methods (additional)
  @override
  Future<Map<String, dynamic>> getSystemGeneralConfig() async {
    try {
      await _ensureAuthenticated();
      final result = await _request('system.general.config');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getSystemAdvancedConfig() async {
    try {
      await _ensureAuthenticated();
      final result = await _request('system.advanced.config');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<String> getSystemProductType() async {
    try {
      await _ensureAuthenticated();
      final result = await _request('system.product_type');
      return result as String;
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<bool> isIxHardware() async {
    try {
      await _ensureAuthenticated();
      final result = await _request('truenas.is_ix_hardware');
      return result as bool;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Job management methods
  @override
  Future<List<Job>> getJobs() async {
    try {
      await _ensureAuthenticated();
      final result = await _request('core.get_jobs');
      final jobs = (result as List<dynamic>).cast<Map<String, dynamic>>().map(
        Job.fromJson,
      );
      _jobsById
        ..clear()
        ..addEntries(jobs.map((job) => MapEntry(job.id, job)));
      return _jobsById.values.toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Stream<List<Job>> get jobsStream {
    _jobsController ??= StreamController<List<Job>>.broadcast();
    return _jobsController!.stream;
  }

  @override
  Future<void> subscribeToJobs() async {
    _wantsJobs = true;

    if (_isSubscribedToJobs && _hasLiveConnection) {
      if (kDebugMode) {
        print('TrueNAS API: Already subscribed to jobs');
      }
      return;
    }

    _isSubscribedToJobs = false;
    _jobsSubscriptionId = null;

    try {
      await _ensureAuthenticated();

      _jobsController ??= StreamController<List<Job>>.broadcast();

      _jobsSubscriptionId =
          await _request('core.subscribe', ['core.get_jobs']) as String;

      _isSubscribedToJobs = true;

      if (kDebugMode) {
        print('TrueNAS API: Subscribed to jobs with ID: $_jobsSubscriptionId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Failed to subscribe to jobs: $e');
      }
      throw _handleError(e);
    }
  }

  @override
  Future<void> unsubscribeFromJobs() async {
    if (!_isSubscribedToJobs || _jobsSubscriptionId == null) {
      return;
    }

    try {
      if (_hasLiveConnection) {
        await _request('core.unsubscribe', [_jobsSubscriptionId!]);

        if (kDebugMode) {
          print(
            'TrueNAS API: Unsubscribed from jobs with ID: $_jobsSubscriptionId',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('TrueNAS API: Error unsubscribing from jobs: $e');
      }
    } finally {
      _wantsJobs = false;
      _isSubscribedToJobs = false;
      _jobsSubscriptionId = null;
      _jobsById.clear();
      await _jobsController?.close();
      _jobsController = null;

      if (kDebugMode) {
        print('TrueNAS API: Job subscription cleaned up');
      }
    }
  }

  @override
  Future<void> abortJob(int jobId) async {
    try {
      await _ensureAuthenticated();
      await _request('core.job_abort', [jobId]);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<int> rerunJob(Job job) async {
    try {
      await _ensureAuthenticated();
      final result = await _request(job.method, job.arguments);
      return result as int;
    } catch (e) {
      throw _handleError(e);
    }
  }

  double _extractCpuUsage(Map<String, dynamic> cpuInfo) {
    return (cpuInfo['usage'] as num?)?.toDouble() ?? 0.0;
  }

  double _extractMemoryUsage(Map<String, dynamic> memoryInfo) {
    final used = (memoryInfo['used'] as num?)?.toDouble() ?? 0.0;
    final total = (memoryInfo['total'] as num?)?.toDouble() ?? 1.0;
    return total > 0 ? (used / total) * 100 : 0.0;
  }

  double _extractDiskUsage(List<Map<String, dynamic>> diskInfo) {
    if (diskInfo.isEmpty) return 0.0;

    double totalUsed = 0.0;
    double totalSize = 0.0;

    for (final disk in diskInfo) {
      totalUsed += (disk['used'] as num?)?.toDouble() ?? 0.0;
      totalSize += (disk['size'] as num?)?.toDouble() ?? 0.0;
    }

    return totalSize > 0 ? (totalUsed / totalSize) * 100 : 0.0;
  }

  List<DiskInfo> _extractDisks(List<Map<String, dynamic>> diskInfo) {
    return diskInfo
        .map(
          (disk) => DiskInfo(
            name: disk['name'] as String? ?? 'Unknown',
            model: disk['model'] as String? ?? 'Unknown',
            serial: disk['serial'] as String? ?? 'Unknown',
            size: (disk['size'] as num?)?.toInt() ?? 0,
            used: (disk['used'] as num?)?.toInt() ?? 0,
            temperature: (disk['temperature'] as num?)?.toInt() ?? 0,
            health: disk['health'] as String? ?? 'Unknown',
          ),
        )
        .toList();
  }

  NetworkInfo _extractNetwork(Map<String, dynamic> networkInfo) {
    return NetworkInfo(
      downloadSpeed: (networkInfo['download_speed'] as num?)?.toInt() ?? 0,
      uploadSpeed: (networkInfo['upload_speed'] as num?)?.toInt() ?? 0,
      totalDownload: (networkInfo['total_download'] as num?)?.toInt() ?? 0,
      totalUpload: (networkInfo['total_upload'] as num?)?.toInt() ?? 0,
    );
  }

  ConnectionException _handleConnectionError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Network connectivity issues
    if (error is SocketException ||
        errorString.contains('network is unreachable') ||
        errorString.contains('no route to host') ||
        errorString.contains('connection refused')) {
      return ConnectionException(
        ConnectionError.networkUnreachable(details: error.toString()),
      );
    }

    // Timeout issues
    if (error is TimeoutException ||
        errorString.contains('timeout') ||
        errorString.contains('timed out') ||
        errorString.contains('client closed with pending request')) {
      return ConnectionException(
        ConnectionError.connectionTimeout(details: error.toString()),
      );
    }

    // A JSON-RPC error from the middleware itself. TrueNAS attaches a
    // `data` map ({error: errno, errname, reason, trace, extra}) to method
    // call failures, and its message alone ("Method call error") says
    // nothing - the reason is what the user needs to see.
    if (error is RpcException) {
      final data = error.data;
      final reason = data is Map ? data['reason']?.toString() : null;
      final errname = data is Map ? data['errname']?.toString() : null;
      final reasonLower = (reason ?? '').toLowerCase();
      final details = reason == null || reason.isEmpty
          ? 'JSON-RPC error ${error.code}: ${error.message}'
          : reason;

      if (errname == 'ENOTAUTHENTICATED' ||
          reasonLower.contains('not authenticated') ||
          reasonLower.contains('session is expired')) {
        return ConnectionException(
          ConnectionError.authenticationFailed(details: details),
        );
      }

      if (error.code == 401 ||
          errorString.contains('unauthorized') ||
          errorString.contains('authentication failed') ||
          errorString.contains('invalid credentials')) {
        return ConnectionException(
          ConnectionError.invalidCredentials(details: details),
        );
      }

      if (error.code == 403 ||
          errname == 'EACCES' ||
          errname == 'EPERM' ||
          errorString.contains('forbidden') ||
          reasonLower.contains('not authorized')) {
        return ConnectionException(
          ConnectionError.permissionDenied(details: details),
        );
      }

      // Anything else the middleware rejected (a method that failed, a
      // method that doesn't exist on this TrueNAS version, invalid params)
      // happened on the server, and is not a connectivity problem.
      return ConnectionException(ConnectionError.serverError(details: details));
    }

    // The server answered, but not in a shape this client understands.
    if (error is FormatException || error is TypeError) {
      return ConnectionException(
        ConnectionError.invalidResponse(details: error.toString()),
      );
    }

    // WebSocket specific errors
    if (errorString.contains('websocket') ||
        errorString.contains('handshake') ||
        errorString.contains('upgrade failed')) {
      return ConnectionException(
        ConnectionError.networkUnreachable(
          details: 'WebSocket connection failed: ${error.toString()}',
        ),
      );
    }

    // Default to unknown error
    return ConnectionException(
      ConnectionError.unknown(details: error.toString()),
    );
  }

  /// Normalises any failure into a [ConnectionException]. This used to
  /// re-wrap the classified error as a plain `Exception(message)`, which
  /// dropped both the [ConnectionErrorType] and the technical details on
  /// the floor - so every failure reached the UI as a generic "Connection
  /// error" with nothing to act on.
  ConnectionException _handleError(dynamic error) {
    if (error is ConnectionException) {
      return error;
    }
    return _handleConnectionError(error);
  }
}
