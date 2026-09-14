import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/connection_error.dart';
import 'package:truehub/models/pool.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/services/api_client_manager.dart';
import 'package:truehub/services/telemetry_service_interface.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/providers/server_provider.dart';

class PoolProvider extends ChangeNotifier {
  final UnifiedServerService _serverService;
  final TelemetryServiceInterface? _telemetryService;
  ApiClientInterface? _apiClient;
  String? _currentServerId;
  List<Pool> _pools = [];
  bool _isLoading = false;
  ConnectionError? _connectionError;

  PoolProvider(
    this._serverService, {
    TelemetryServiceInterface? telemetryService,
  }) : _telemetryService = telemetryService;

  List<Pool> get pools => _pools;
  bool get isLoading => _isLoading;
  ConnectionError? get connectionError => _connectionError;
  String? get error => _connectionError?.shortMessage;

  Future<void> setServer(NasServer? server) async {
    // Release previous client if any
    if (_currentServerId != null) {
      await ApiClientManager.releaseClient(_currentServerId!);
    }

    _currentServerId = server?.id;
    _apiClient = null;
    _pools = [];
    _connectionError = null;

    if (server != null) {
      try {
        // Load credentials for the server
        final serverWithCredentials =
            await ServerProvider.loadServerCredentials(server, _serverService);

        if (serverWithCredentials != null) {
          _apiClient = await ApiClientManager.getClient(serverWithCredentials);
        } else {
          if (kDebugMode) {
            print(
              'PoolProvider: No credentials available for server ${server.id}',
            );
          }
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print('PoolProvider: Failed to get API client: $e');
        }
        _telemetryService?.recordError(
          e,
          stackTrace,
          context: 'PoolProvider.setServer',
        );
      }
    }
    notifyListeners();
  }

  Future<void> setApiClient(NasServer server) async {
    // Release previous client if any
    if (_currentServerId != null) {
      await ApiClientManager.releaseClient(_currentServerId!);
    }

    _currentServerId = server.id;
    _pools = [];
    _connectionError = null;

    try {
      // Load credentials for the server
      final serverWithCredentials = await ServerProvider.loadServerCredentials(
        server,
        _serverService,
      );

      if (serverWithCredentials != null) {
        _apiClient = await ApiClientManager.getClient(serverWithCredentials);
      } else {
        if (kDebugMode) {
          print(
            'PoolProvider: No credentials available for server ${server.id}',
          );
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('PoolProvider: Failed to get API client: $e');
      }
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'PoolProvider.setApiClient',
      );
    }
    notifyListeners();
  }

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
    if (_currentServerId != null) {
      // Note: We can't await in dispose, so we do a fire-and-forget cleanup
      ApiClientManager.releaseClient(_currentServerId!);
    }
    super.dispose();
  }
}
