import 'package:flutter/foundation.dart';

enum TrueNASConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class ConnectionStatus {
  final TrueNASConnectionState state;
  final DateTime lastPing;
  final DateTime? lastPong;
  final String? error;
  final Duration? latency;
  final String? connectionUrl;
  final bool? isLocalConnection;

  const ConnectionStatus({
    required this.state,
    required this.lastPing,
    this.lastPong,
    this.error,
    this.latency,
    this.connectionUrl,
    this.isLocalConnection,
  });

  bool get isHealthy =>
      state == TrueNASConnectionState.connected &&
      lastPong != null &&
      DateTime.now().difference(lastPong!).inSeconds < 120;

  ConnectionStatus copyWith({
    TrueNASConnectionState? state,
    DateTime? lastPing,
    DateTime? lastPong,
    String? error,
    Duration? latency,
    String? connectionUrl,
    bool? isLocalConnection,
  }) {
    return ConnectionStatus(
      state: state ?? this.state,
      lastPing: lastPing ?? this.lastPing,
      lastPong: lastPong ?? this.lastPong,
      error: error ?? this.error,
      latency: latency ?? this.latency,
      connectionUrl: connectionUrl ?? this.connectionUrl,
      isLocalConnection: isLocalConnection ?? this.isLocalConnection,
    );
  }
}

class ConnectionStatusProvider extends ChangeNotifier {
  final Map<String, ConnectionStatus> _connectionStatuses = {};

  ConnectionStatus? getStatus(String serverId) {
    return _connectionStatuses[serverId];
  }

  void updateConnectionState(
    String serverId,
    TrueNASConnectionState state, {
    String? error,
    String? connectionUrl,
    bool? isLocalConnection,
  }) {
    final current = _connectionStatuses[serverId];
    final now = DateTime.now();

    // When transitioning to connected state, set both ping and pong to now
    // to show healthy status immediately
    final lastPong = state == TrueNASConnectionState.connected
        ? now
        : current?.lastPong;

    _connectionStatuses[serverId] = ConnectionStatus(
      state: state,
      lastPing: current?.lastPing ?? now,
      lastPong: lastPong,
      error: error,
      latency: current?.latency,
      connectionUrl: connectionUrl ?? current?.connectionUrl,
      isLocalConnection: isLocalConnection ?? current?.isLocalConnection,
    );

    if (kDebugMode) {
      debugPrint('ConnectionStatus: Server $serverId state changed to $state');
    }

    notifyListeners();
  }

  void updatePingStatus(
    String serverId, {
    DateTime? pingSent,
    DateTime? pongReceived,
    Duration? latency,
  }) {
    final current = _connectionStatuses[serverId];
    final now = DateTime.now();

    _connectionStatuses[serverId] =
        current?.copyWith(
          lastPing: pingSent ?? current.lastPing,
          lastPong: pongReceived ?? current.lastPong,
          latency: latency ?? current.latency,
        ) ??
        ConnectionStatus(
          state: TrueNASConnectionState.disconnected,
          lastPing: pingSent ?? now,
          lastPong: pongReceived,
          latency: latency,
        );

    if (kDebugMode && pongReceived != null) {
      debugPrint(
        'ConnectionStatus: Server $serverId pong received, latency: ${latency?.inMilliseconds}ms',
      );
    }

    notifyListeners();
  }

  void removeServer(String serverId) {
    _connectionStatuses.remove(serverId);
    notifyListeners();
  }

  void clearAll() {
    _connectionStatuses.clear();
    notifyListeners();
  }

  List<String> get connectedServers {
    return _connectionStatuses.entries
        .where((entry) => entry.value.state == TrueNASConnectionState.connected)
        .map((entry) => entry.key)
        .toList();
  }

  int get healthyConnectionCount {
    return _connectionStatuses.values
        .where((status) => status.isHealthy)
        .length;
  }
}
