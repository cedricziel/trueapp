import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/services/api_client_manager.dart';
import 'package:truehub/services/telemetry_service_interface.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/providers/server_provider.dart';

class DatasetProvider extends ChangeNotifier {
  final UnifiedServerService _serverService;
  final TelemetryServiceInterface? _telemetryService;
  ApiClientInterface? _apiClient;
  String? _currentServerId;
  List<Map<String, dynamic>> _datasets = [];
  bool _isLoading = false;
  String? _error;

  DatasetProvider(
    this._serverService, {
    TelemetryServiceInterface? telemetryService,
  }) : _telemetryService = telemetryService;

  List<Map<String, dynamic>> get datasets => _datasets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> setServer(NasServer? server) async {
    // Release previous client if any
    if (_currentServerId != null) {
      await ApiClientManager.releaseClient(_currentServerId!);
    }

    _currentServerId = server?.id;
    _apiClient = null;
    _datasets = [];
    _error = null;

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
              'DatasetProvider: No credentials available for server ${server.id}',
            );
          }
        }
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print('DatasetProvider: Failed to get API client: $e');
        }
        _telemetryService?.recordError(
          e,
          stackTrace,
          context: 'DatasetProvider.setServer',
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
    _datasets = [];
    _error = null;

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
            'DatasetProvider: No credentials available for server ${server.id}',
          );
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('DatasetProvider: Failed to get API client: $e');
      }
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'DatasetProvider.setApiClient',
      );
    }
    notifyListeners();
  }

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
    if (_currentServerId != null) {
      // Note: We can't await in dispose, so we do a fire-and-forget cleanup
      ApiClientManager.releaseClient(_currentServerId!);
    }
    super.dispose();
  }
}
