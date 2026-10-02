import 'package:flutter/foundation.dart';
import 'package:truehub/providers/active_server_follower.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/connection_error.dart';
import 'package:truehub/models/file_item.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/services/api_client_manager_interface.dart';
import 'package:truehub/services/server_client_session.dart';
import 'package:truehub/services/server_credentials_lookup.dart';
import 'package:truehub/services/telemetry_service_interface.dart';

class FileProvider extends ChangeNotifier with ActiveServerFollower {
  final ServerClientSession _session;
  final TelemetryServiceInterface? _telemetryService;
  List<FileItem> _files = [];
  String _currentPath = '/';
  String _searchQuery = '';
  bool _isLoading = false;
  ConnectionError? _connectionError;

  FileProvider(
    ServerCredentialsLookup credentials, {
    required ApiClientManagerInterface clientManager,
    TelemetryServiceInterface? telemetryService,
    ValueListenable<NasServer?>? activeServer,
  }) : _telemetryService = telemetryService,
       _session = ServerClientSession(
         owner: 'FileProvider',
         clientManager: clientManager,
         credentials: credentials,
         telemetry: telemetryService,
       ) {
    followActiveServer(activeServer);
  }

  ApiClientInterface? get _apiClient => _session.client;

  List<FileItem> get files => _files;

  /// [files] filtered by [searchQuery] (case-insensitive name match).
  List<FileItem> get filteredFiles {
    if (_searchQuery.isEmpty) return _files;
    final query = _searchQuery.toLowerCase();
    return _files
        .where((file) => file.name.toLowerCase().contains(query))
        .toList();
  }

  String get currentPath => _currentPath;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  ConnectionError? get connectionError => _connectionError;
  String? get error => _connectionError?.shortMessage;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  @override
  Future<void> setServer(NasServer server) async {
    _files = [];
    _currentPath = '/';
    _searchQuery = '';
    _connectionError = null;

    if (!await _session.connect(server)) return;
    notifyListeners();
  }

  Future<void> loadFiles(String path) async {
    final pendingSwitch = pendingServerSwitch;
    if (pendingSwitch != null) await pendingSwitch;
    if (_apiClient == null) return;

    _isLoading = true;
    _connectionError = null;
    notifyListeners();

    try {
      _files = await _apiClient!.getDirectoryListing(path);
      _currentPath = path;
      _connectionError = null;
    } on ConnectionException catch (e, stackTrace) {
      _connectionError = e.error;
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'FileProvider.loadFiles',
      );
    } catch (e, stackTrace) {
      _connectionError = ConnectionError.unknown(details: e.toString());
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'FileProvider.loadFiles',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> navigateToPath(String path) async {
    _searchQuery = '';
    await loadFiles(path);
  }

  Future<void> navigateUp() async {
    if (_currentPath == '/') return;
    final segments = _currentPath.split('/')..removeLast();
    final parentPath = segments.join('/');
    await navigateToPath(parentPath.isEmpty ? '/' : parentPath);
  }

  Future<void> refreshFiles() async {
    await loadFiles(_currentPath);
  }

  /// Seeds [files] directly, bypassing the API client, so search/sort logic
  /// can be unit-tested without a live server connection.
  @visibleForTesting
  void debugSetFiles(List<FileItem> files) {
    _files = files;
    notifyListeners();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }
}
