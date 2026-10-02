import 'package:flutter/foundation.dart';
import 'package:truehub/models/alert.dart';
import 'package:truehub/models/connection_error.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/server_health.dart';
import 'package:truehub/models/service_status.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/services/api_client_manager_interface.dart';
import 'package:truehub/services/server_client_session.dart';
import 'package:truehub/services/server_credentials_lookup.dart';
import 'package:truehub/services/telemetry_service_interface.dart';

class HealthProvider extends ChangeNotifier {
  final ServerClientSession _session;
  final TelemetryServiceInterface? _telemetryService;
  List<Alert> _alerts = [];
  List<ServiceStatus> _services = [];
  ServerHealth? _serverHealth;
  bool _isLoading = false;
  ConnectionError? _connectionError;

  /// Bumped by every [setApiClient] call, so a [loadHealth] call for a
  /// server the caller has already switched away from can tell its own
  /// result is stale and discard it instead of overwriting the newer
  /// selection's alerts or services.
  int _generation = 0;

  HealthProvider(
    ServerCredentialsLookup credentials, {
    required ApiClientManagerInterface clientManager,
    TelemetryServiceInterface? telemetryService,
  }) : _telemetryService = telemetryService,
       _session = ServerClientSession(
         owner: 'HealthProvider',
         clientManager: clientManager,
         credentials: credentials,
         telemetry: telemetryService,
       );

  ApiClientInterface? get _apiClient => _session.client;

  List<Alert> get alerts => _alerts;

  /// Alerts the user has not dismissed - what a "N active alerts" banner
  /// should count.
  List<Alert> get activeAlerts =>
      _alerts.where((alert) => !alert.dismissed).toList();

  List<ServiceStatus> get services => _services;
  ServerHealth? get serverHealth => _serverHealth;
  bool get isLoading => _isLoading;
  ConnectionError? get connectionError => _connectionError;
  String? get error => _connectionError?.shortMessage;

  Future<void> setApiClient(NasServer server) async {
    _generation++;
    _alerts = [];
    _services = [];
    _serverHealth = null;
    _connectionError = null;

    if (!await _session.connect(server)) return;
    notifyListeners();
  }

  Future<void> loadHealth() async {
    final generation = _generation;
    final client = _apiClient;
    if (client == null) return;

    _isLoading = true;
    _connectionError = null;
    notifyListeners();

    try {
      final rawAlerts = await client.getAlerts();
      final rawServices = await client.getServices();
      final serverHealth = await client.getServerHealth();

      if (generation != _generation) return;

      _alerts = rawAlerts.map(Alert.fromJson).toList();
      _services = rawServices.map(ServiceStatus.fromJson).toList();
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

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }
}
