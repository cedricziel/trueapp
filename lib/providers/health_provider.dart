import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:truehub/providers/active_server_follower.dart';
import 'package:truehub/models/alert.dart';
import 'package:truehub/models/alert_event.dart';
import 'package:truehub/models/connection_error.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/server_health.dart';
import 'package:truehub/models/service_status.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/services/api_client_manager_interface.dart';
import 'package:truehub/services/server_client_session.dart';
import 'package:truehub/services/server_credentials_lookup.dart';
import 'package:truehub/services/telemetry_service_interface.dart';
import 'package:truehub/services/tray_status_ports.dart';

class HealthProvider extends ChangeNotifier
    with ActiveServerFollower
    implements TrayHealthSource {
  final ServerClientSession _session;
  final TelemetryServiceInterface? _telemetryService;
  List<Alert> _alerts = [];
  List<ServiceStatus> _services = [];
  ServerHealth? _serverHealth;
  bool _isLoading = false;
  ConnectionError? _connectionError;
  bool _showDismissed = false;
  StreamSubscription<AlertEvent>? _alertSubscription;

  /// The client [_alertSubscription] belongs to, kept so it can be
  /// unsubscribed after [_session] has moved on to another server.
  ApiClientInterface? _alertClient;

  /// Bumped by every [setServer] call, so a [loadHealth] call for a
  /// server the caller has already switched away from can tell its own
  /// result is stale and discard it instead of overwriting the newer
  /// selection's alerts or services.
  int _generation = 0;

  HealthProvider(
    ServerCredentialsLookup credentials, {
    required ApiClientManagerInterface clientManager,
    TelemetryServiceInterface? telemetryService,
    ValueListenable<NasServer?>? activeServer,
  }) : _telemetryService = telemetryService,
       _session = ServerClientSession(
         owner: 'HealthProvider',
         clientManager: clientManager,
         credentials: credentials,
         telemetry: telemetryService,
       ) {
    followActiveServer(activeServer);
  }

  ApiClientInterface? get _apiClient => _session.client;

  List<Alert> get alerts => _alerts;

  /// Alerts the user has not dismissed - what a "N active alerts" banner
  /// should count.
  List<Alert> get activeAlerts =>
      _alerts.where((alert) => !alert.dismissed).toList();

  /// Whether dismissed alerts are listed alongside the active ones.
  bool get showDismissed => _showDismissed;

  set showDismissed(bool value) {
    if (_showDismissed == value) return;
    _showDismissed = value;
    notifyListeners();
  }

  bool get hasDismissedAlerts => alerts.any((alert) => alert.dismissed);

  /// The alerts the health screen lists: dismissed ones only on request.
  List<Alert> get visibleAlerts => _showDismissed ? alerts : activeAlerts;

  List<ServiceStatus> get services => _services;
  ServerHealth? get serverHealth => _serverHealth;
  bool get isLoading => _isLoading;
  ConnectionError? get connectionError => _connectionError;
  String? get error => _connectionError?.shortMessage;

  @override
  String? get healthError => error;

  @override
  Future<void> setServer(NasServer server) async {
    _generation++;
    await _stopAlertUpdates();
    _alerts = [];
    _services = [];
    _serverHealth = null;
    _connectionError = null;

    if (!await _session.connect(server)) return;
    notifyListeners();
  }

  Future<void> loadHealth() async {
    final pendingSwitch = pendingServerSwitch;
    if (pendingSwitch != null) await pendingSwitch;
    final generation = _generation;
    final client = _apiClient;
    if (client == null) return;

    _isLoading = true;
    _connectionError = null;
    notifyListeners();

    try {
      // Subscribe before fetching, so a change landing between the two is in
      // the fetched list or arrives as an event, never neither.
      await _ensureAlertSubscription(client, generation);
      final alerts = await client.getAlerts();
      final services = await client.getServices();
      final serverHealth = await client.getServerHealth();

      if (generation != _generation) return;

      _alerts = alerts;
      _services = services;
      _serverHealth = serverHealth;
      _connectionError = null;
    } on ConnectionException catch (e, stackTrace) {
      if (generation == _generation) _connectionError = e.error;
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'HealthProvider.loadHealth',
      );
    } catch (e, stackTrace) {
      if (generation == _generation) {
        _connectionError = ConnectionError.unknown(details: e.toString());
      }
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'HealthProvider.loadHealth',
      );
    } finally {
      if (generation == _generation) _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshHealth() async {
    await loadHealth();
  }

  Future<bool> dismissAlert(String alertId) =>
      _setDismissed(alertId, dismissed: true);

  Future<bool> restoreAlert(String alertId) =>
      _setDismissed(alertId, dismissed: false);

  /// Flips the alert locally first so the list reacts at once, then asks the
  /// server. A failed request puts the alert back unless a live update has
  /// settled its state in the meantime.
  Future<bool> _setDismissed(String alertId, {required bool dismissed}) async {
    final client = _apiClient;
    if (client == null) return false;
    final generation = _generation;

    _flipDismissed(alertId, from: !dismissed);
    try {
      if (dismissed) {
        await client.dismissAlert(alertId);
      } else {
        await client.restoreAlert(alertId);
      }
      return true;
    } catch (e, stackTrace) {
      if (generation == _generation) {
        _flipDismissed(alertId, from: dismissed);
      }
      _telemetryService?.recordError(
        e,
        stackTrace,
        context:
            'HealthProvider.${dismissed ? 'dismissAlert' : 'restoreAlert'}',
      );
      return false;
    }
  }

  /// Toggles the alert's dismissed flag if it is currently [from].
  void _flipDismissed(String alertId, {required bool from}) {
    final index = _alerts.indexWhere((alert) => alert.id == alertId);
    if (index < 0 || _alerts[index].dismissed != from) return;
    _alerts = [..._alerts]..[index] = _alerts[index].copyWith(dismissed: !from);
    notifyListeners();
  }

  Future<void> _ensureAlertSubscription(
    ApiClientInterface client,
    int generation,
  ) async {
    if (_alertSubscription != null) return;

    _alertClient = client;
    _alertSubscription = client.alertEvents.listen(_onAlertEvent);
    try {
      await client.subscribeToAlerts();
      if (generation != _generation) {
        // A server switch ran while subscribing, so the cleanup it did came
        // before the subscription existed.
        unawaited(client.unsubscribeFromAlerts().catchError((_) {}));
      }
    } catch (e, stackTrace) {
      // Alerts still load without live updates; the next load retries.
      await _alertSubscription?.cancel();
      _alertSubscription = null;
      _alertClient = null;
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'HealthProvider.subscribeToAlerts',
      );
    }
  }

  Future<void> _stopAlertUpdates() async {
    final subscription = _alertSubscription;
    final client = _alertClient;
    _alertSubscription = null;
    _alertClient = null;
    await subscription?.cancel();
    try {
      await client?.unsubscribeFromAlerts();
    } catch (_) {
      // The client is going away; a failed unsubscribe leaves nothing to undo.
    }
  }

  void _onAlertEvent(AlertEvent event) {
    // Only a removal carries no alert.
    final alert = event.alert;
    if (alert == null) {
      _alerts = [
        for (final existing in _alerts)
          if (existing.id != event.id) existing,
      ];
    } else {
      final index = _alerts.indexWhere((a) => a.id == alert.id);
      _alerts = index < 0
          ? [..._alerts, alert]
          : ([..._alerts]..[index] = alert);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_stopAlertUpdates());
    _session.dispose();
    super.dispose();
  }
}
