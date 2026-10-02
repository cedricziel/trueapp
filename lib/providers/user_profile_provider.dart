import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/user_info.dart';
import 'package:truehub/providers/active_server_follower.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/services/api_client_manager_interface.dart';
import 'package:truehub/services/server_client_session.dart';
import 'package:truehub/services/server_credentials_lookup.dart';
import 'package:truehub/services/telemetry_service_interface.dart';

class UserProfileProvider extends ChangeNotifier with ActiveServerFollower {
  final ServerClientSession _session;
  final TelemetryServiceInterface? _telemetryService;
  UserInfo? _currentUser;
  bool _isLoading = false;
  String? _error;

  /// Bumped by every [setServer] call so a [loadCurrentUser] call for a server
  /// the caller has already switched away from discards its stale result.
  int _generation = 0;

  UserProfileProvider(
    ServerCredentialsLookup credentials, {
    required ApiClientManagerInterface clientManager,
    TelemetryServiceInterface? telemetryService,
    ValueListenable<NasServer?>? activeServer,
  }) : _telemetryService = telemetryService,
       _session = ServerClientSession(
         owner: 'UserProfileProvider',
         clientManager: clientManager,
         credentials: credentials,
         telemetry: telemetryService,
       ) {
    followActiveServer(activeServer);
  }

  ApiClientInterface? get _apiClient => _session.client;

  UserInfo? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  @override
  Future<void> setServer(NasServer server) async {
    _generation++;
    _currentUser = null;
    _error = null;
    _isLoading = false;

    if (!await _session.connect(server)) return;
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    final pendingSwitch = pendingServerSwitch;
    if (pendingSwitch != null) await pendingSwitch;
    final generation = _generation;
    final client = _apiClient;
    if (client == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await client.getCurrentUser();
      if (generation != _generation) return;
      _currentUser = user;
    } catch (e, stackTrace) {
      if (generation == _generation) _error = e.toString();
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'UserProfileProvider.loadCurrentUser',
      );
    } finally {
      if (generation == _generation) _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }
}
