part of '../truenas_api_client.dart';

mixin _KeepaliveAndRecovery on _ClientBase, _Connection implements SessionApi {
  @override
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

  /// True while any request younger than [busyGracePeriod] is still waiting
  /// for its reply - evidence the socket is in use, not dead.
  bool get _isBusyWithinGrace {
    final now = DateTime.now();
    return _inFlightRequestStarts.any(
      (startedAt) => now.difference(startedAt) < busyGracePeriod,
    );
  }

  @override
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
}
