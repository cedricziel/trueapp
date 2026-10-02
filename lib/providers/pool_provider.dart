import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/connection_error.dart';
import 'package:truehub/models/pool.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/services/api_client_manager_interface.dart';
import 'package:truehub/services/server_client_session.dart';
import 'package:truehub/services/server_credentials_lookup.dart';
import 'package:truehub/services/telemetry_service_interface.dart';

class PoolProvider extends ChangeNotifier {
  final ServerClientSession _session;
  final TelemetryServiceInterface? _telemetryService;
  List<Pool> _pools = [];
  bool _isLoading = false;
  ConnectionError? _connectionError;

  PoolProvider(
    ServerCredentialsLookup credentials, {
    required ApiClientManagerInterface clientManager,
    TelemetryServiceInterface? telemetryService,
  }) : _telemetryService = telemetryService,
       _session = ServerClientSession(
         owner: 'PoolProvider',
         clientManager: clientManager,
         credentials: credentials,
         telemetry: telemetryService,
       );

  ApiClientInterface? get _apiClient => _session.client;

  List<Pool> get pools => _pools;
  bool get isLoading => _isLoading;
  ConnectionError? get connectionError => _connectionError;
  String? get error => _connectionError?.shortMessage;

  Future<void> setServer(NasServer? server) async {
    _pools = [];
    _connectionError = null;

    if (server == null) {
      await _session.disconnect();
    } else if (!await _session.connect(server)) {
      return;
    }
    notifyListeners();
  }

  Future<void> setApiClient(NasServer server) => setServer(server);

  Future<void> loadPools() async {
    if (_apiClient == null) return;

    _isLoading = true;
    _connectionError = null;
    notifyListeners();

    try {
      final rawPools = await _apiClient!.getPools();
      _pools = rawPools.map(Pool.fromJson).toList();
      // Clear any previous errors on successful load
      _connectionError = null;
    } on ConnectionException catch (e, stackTrace) {
      _connectionError = e.error;
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'PoolProvider.loadPools',
      );
    } catch (e, stackTrace) {
      // Handle unexpected errors
      _connectionError = ConnectionError.unknown(details: e.toString());
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'PoolProvider.loadPools',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPools() async {
    await loadPools();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }
}
