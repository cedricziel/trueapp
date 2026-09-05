import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/connection_error.dart';
import 'package:truehub/models/file_item.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/services/api_client_manager.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/providers/server_provider.dart';

class FileProvider extends ChangeNotifier {
  final UnifiedServerService _serverService;
  ApiClientInterface? _apiClient;
  String? _currentServerId;
  List<FileItem> _files = [];
  String _currentPath = '/';
  String _searchQuery = '';
  bool _isLoading = false;
  ConnectionError? _connectionError;

  FileProvider(this._serverService);

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

  Future<void> setApiClient(NasServer server) async {
    // Release previous client if any
    if (_currentServerId != null) {
      await ApiClientManager.releaseClient(_currentServerId!);
    }

    _currentServerId = server.id;
    _apiClient = null;
    _files = [];
    _currentPath = '/';
    _searchQuery = '';
    _connectionError = null;

    try {
      // Load credentials for the server - NasServer as passed through
      // navigation carries no password, so the client would otherwise
      // authenticate with an empty one.
      final serverWithCredentials = await ServerProvider.loadServerCredentials(
        server,
        _serverService,
      );

      if (serverWithCredentials != null) {
        _apiClient = await ApiClientManager.getClient(serverWithCredentials);
      } else {
        if (kDebugMode) {
          print(
            'FileProvider: No credentials available for server ${server.id}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('FileProvider: Failed to get API client: $e');
      }
    }
    notifyListeners();
  }

  Future<void> loadFiles(String path) async {
    if (_apiClient == null) return;

    _isLoading = true;
    _connectionError = null;
    notifyListeners();

    try {
      _files = await _apiClient!.getDirectoryListing(path);
      _currentPath = path;
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
    if (_currentServerId != null) {
      // Note: We can't await in dispose, so we do a fire-and-forget cleanup
      ApiClientManager.releaseClient(_currentServerId!);
    }
    super.dispose();
  }
}
