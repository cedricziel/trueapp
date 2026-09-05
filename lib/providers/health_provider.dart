import 'package:flutter/foundation.dart';
import 'package:truehub/models/alert.dart';
import 'package:truehub/models/connection_error.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/server_health.dart';
import 'package:truehub/models/service_status.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/services/api_client_manager.dart';
import 'package:truehub/services/unified_server_service.dart';

class HealthProvider extends ChangeNotifier {
  final UnifiedServerService _serverService;
  ApiClientInterface? _apiClient;
  String? _currentServerId;
  List<Alert> _alerts = [];
  List<ServiceStatus> _services = [];
  ServerHealth? _serverHealth;
  bool _isLoading = false;
  ConnectionError? _connectionError;

  HealthProvider(this._serverService);

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
    // Release previous client if any
    if (_currentServerId != null) {
      await ApiClientManager.releaseClient(_currentServerId!);
    }

    _currentServerId = server.id;
    _apiClient = null;
    _alerts = [];
    _services = [];
    _serverHealth = null;
    _connectionError = null;

    try {
      final serverWithCredentials = await ServerProvider.loadServerCredentials(
        server,
        _serverService,
      );

      if (serverWithCredentials != null) {
        _apiClient = await ApiClientManager.getClient(serverWithCredentials);
      } else {
        if (kDebugMode) {
          print(
            'HealthProvider: No credentials available for server ${server.id}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('HealthProvider: Failed to get API client: $e');
      }
    }
    notifyListeners();
  }

  Future<void> loadHealth() async {
    if (_apiClient == null) return;

    _isLoading = true;
    _connectionError = null;
    notifyListeners();

    try {
      final rawAlerts = await _apiClient!.getAlerts();
      final rawServices = await _apiClient!.getServices();
      final serverHealth = await _apiClient!.getServerHealth();

      _alerts = rawAlerts.map(Alert.fromJson).toList();
      _services = rawServices.map(ServiceStatus.fromJson).toList();
      _serverHealth = serverHealth;
      _connectionError = null;
    } on ConnectionException catch (e) {
      _connectionError = e.error;
    } catch (e) {
      _connectionError = ConnectionError.unknown(details: e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshHealth() async {
    await loadHealth();
  }

  @override
  void dispose() {
    if (_currentServerId != null) {
      // Note: We can't await in dispose, so we do a fire-and-forget cleanup
      ApiClientManager.releaseClient(_currentServerId!);
    }
    super.dispose();
  }
}
