part of '../truenas_api_client.dart';

mixin _Connection on _ClientBase {
  void _startKeepalive();

  Future<void> _sendKeepalivePing();

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

  Future<void> _ensureAuthenticated() {
    // Authentication belongs to a socket: once that socket is gone, so is the
    // session, no matter what the flag from the previous connection says.
    if (_isAuthenticated && _hasLiveConnection) return Future.value();
    return _authenticating.run(_authenticate);
  }

  /// Sends a read-only request, retrying once if the socket carrying it gets
  /// recycled mid-flight - e.g. a keepalive-triggered [_recoverConnection]
  /// or an explicit [close] racing a slow call like `app.available`. That
  /// race surfaces as json_rpc_2 rejecting every pending request with
  /// `StateError('The client closed with pending request "$method".')`, and
  /// since it means no response was ever delivered for the first attempt,
  /// retrying against the freshly (re)authenticated connection is safe.
  Future<dynamic> _sendRequest(String method, [dynamic parameters]) async {
    await _ensureAuthenticated();
    try {
      return await _request(method, parameters);
    } on StateError catch (e) {
      if (!e.message.contains('client closed with pending request')) {
        rethrow;
      }
      await _ensureAuthenticated();
      return await _request(method, parameters);
    }
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
}
