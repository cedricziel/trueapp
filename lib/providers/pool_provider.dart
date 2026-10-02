import 'package:flutter/foundation.dart';
import 'package:truehub/providers/active_server_follower.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/connection_error.dart';
import 'package:truehub/models/pool.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/services/api_client_manager_interface.dart';
import 'package:truehub/services/server_client_session.dart';
import 'package:truehub/services/server_credentials_lookup.dart';
import 'package:truehub/services/telemetry_service_interface.dart';

class PoolProvider extends ChangeNotifier with ActiveServerFollower {
  final ServerClientSession _session;
  final TelemetryServiceInterface? _telemetryService;
  List<Pool> _pools = [];
  bool _isLoading = false;
  ConnectionError? _connectionError;

  PoolProvider(
    ServerCredentialsLookup credentials, {
    required ApiClientManagerInterface clientManager,
    TelemetryServiceInterface? telemetryService,
    ValueListenable<NasServer?>? activeServer,
  }) : _telemetryService = telemetryService,
       _session = ServerClientSession(
         owner: 'PoolProvider',
         clientManager: clientManager,
         credentials: credentials,
         telemetry: telemetryService,
       ) {
    followActiveServer(activeServer);
  }

  ApiClientInterface? get _apiClient => _session.client;

  List<Pool> get pools => _pools;
  bool get isLoading => _isLoading;
  ConnectionError? get connectionError => _connectionError;
  String? get error => _connectionError?.shortMessage;

  @override
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

  Future<void> loadPools() async {
    final pendingSwitch = pendingServerSwitch;
    if (pendingSwitch != null) await pendingSwitch;
    if (_apiClient == null) return;

    _isLoading = true;
    _connectionError = null;
    notifyListeners();

    try {
      _pools = await _apiClient!.getPools();
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
