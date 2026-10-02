import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/services/api_client_manager_interface.dart';
import 'package:truehub/services/server_client_session.dart';
import 'package:truehub/services/server_credentials_lookup.dart';
import 'package:truehub/services/telemetry_service_interface.dart';

class DatasetProvider extends ChangeNotifier {
  final ServerClientSession _session;
  final TelemetryServiceInterface? _telemetryService;
  List<Map<String, dynamic>> _datasets = [];
  bool _isLoading = false;
  String? _error;

  DatasetProvider(
    ServerCredentialsLookup credentials, {
    required ApiClientManagerInterface clientManager,
    TelemetryServiceInterface? telemetryService,
  }) : _telemetryService = telemetryService,
       _session = ServerClientSession(
         owner: 'DatasetProvider',
         clientManager: clientManager,
         credentials: credentials,
         telemetry: telemetryService,
       );

  ApiClientInterface? get _apiClient => _session.client;

  List<Map<String, dynamic>> get datasets => _datasets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> setServer(NasServer? server) async {
    _datasets = [];
    _error = null;

    if (server == null) {
      await _session.disconnect();
    } else if (!await _session.connect(server)) {
      return;
    }
    notifyListeners();
  }

  Future<void> setApiClient(NasServer server) => setServer(server);

  Future<void> loadDatasets() async {
    if (_apiClient == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _datasets = await _apiClient!.getDatasets();
    } catch (e, stackTrace) {
      _error = e.toString();
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'DatasetProvider.loadDatasets',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDatasets() async {
    await loadDatasets();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }
}
