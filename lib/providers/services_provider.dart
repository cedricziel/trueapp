import 'package:flutter/foundation.dart';
import 'package:truehub/models/connection_error.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/service_status.dart';
import 'package:truehub/providers/active_server_follower.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/services/api_client_manager_interface.dart';
import 'package:truehub/services/server_client_session.dart';
import 'package:truehub/services/server_credentials_lookup.dart';
import 'package:truehub/services/telemetry_service_interface.dart';

/// The services of the active server, with start/stop/restart actions.
class ServicesProvider extends ChangeNotifier with ActiveServerFollower {
  final ServerClientSession _session;
  final TelemetryServiceInterface? _telemetryService;
  List<ServiceStatus> _services = [];
  final Set<String> _busyServiceIds = {};
  bool _isLoading = false;
  ConnectionError? _connectionError;
  String? _actionError;

  ServicesProvider(
    ServerCredentialsLookup credentials, {
    required ApiClientManagerInterface clientManager,
    TelemetryServiceInterface? telemetryService,
    ValueListenable<NasServer?>? activeServer,
  }) : _telemetryService = telemetryService,
       _session = ServerClientSession(
         owner: 'ServicesProvider',
         clientManager: clientManager,
         credentials: credentials,
         telemetry: telemetryService,
       ) {
    followActiveServer(activeServer);
  }

  ApiClientInterface? get _apiClient => _session.client;

  List<ServiceStatus> get services => _services;
  bool get isLoading => _isLoading;
  ConnectionError? get connectionError => _connectionError;

  /// Why the last start/stop/restart failed, until dismissed.
  String? get actionError => _actionError;

  /// Whether a start/stop/restart for [serviceId] is still in flight.
  bool isBusy(String serviceId) => _busyServiceIds.contains(serviceId);

  @override
  Future<void> setServer(NasServer? server) async {
    _services = [];
    _busyServiceIds.clear();
    _connectionError = null;
    _actionError = null;

    if (server == null) {
      await _session.disconnect();
    } else if (!await _session.connect(server)) {
      return;
    }
    notifyListeners();
  }

  Future<void> loadServices() async {
    final pendingSwitch = pendingServerSwitch;
    if (pendingSwitch != null) await pendingSwitch;
    if (_apiClient == null) return;

    _isLoading = true;
    _connectionError = null;
    notifyListeners();

    try {
      _services = await _fetchServices();
    } on ConnectionException catch (e, stackTrace) {
      _connectionError = e.error;
      _recordError(e, stackTrace, 'loadServices');
    } catch (e, stackTrace) {
      _connectionError = ConnectionError.unknown(details: e.toString());
      _recordError(e, stackTrace, 'loadServices');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startService(String serviceId) => _control(
    serviceId,
    'startService',
    (client) => client.startService(serviceId),
  );

  Future<void> stopService(String serviceId) => _control(
    serviceId,
    'stopService',
    (client) => client.stopService(serviceId),
  );

  Future<void> restartService(String serviceId) => _control(
    serviceId,
    'restartService',
    (client) => client.restartService(serviceId),
  );

  void clearActionError() {
    if (_actionError == null) return;
    _actionError = null;
    notifyListeners();
  }

  Future<List<ServiceStatus>> _fetchServices() async {
    final fetched = await _apiClient!.getServices();
    return [...fetched]..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  Future<void> _control(
    String serviceId,
    String context,
    Future<void> Function(ApiClientInterface client) action,
  ) async {
    final client = _apiClient;
    if (client == null || !_busyServiceIds.add(serviceId)) return;

    _actionError = null;
    notifyListeners();

    try {
      await action(client);
      _services = await _fetchServices();
    } catch (e, stackTrace) {
      _actionError = e is ConnectionException
          ? e.error.shortMessage
          : e.toString();
      _recordError(e, stackTrace, context);
    } finally {
      _busyServiceIds.remove(serviceId);
      notifyListeners();
    }
  }

  void _recordError(Object error, StackTrace stackTrace, String method) {
    _telemetryService?.recordError(
      error,
      stackTrace,
      context: 'ServicesProvider.$method',
    );
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }
}
