import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:truehub/providers/active_server_follower.dart';
import 'package:truehub/models/job.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/services/api_client_manager_interface.dart';
import 'package:truehub/services/server_client_session.dart';
import 'package:truehub/services/server_credentials_lookup.dart';
import 'package:truehub/services/telemetry_service_interface.dart';
import 'package:truehub/services/app_logger.dart';

final _log = appLogger('providers.jobs');

/// How long a failed job keeps the nav bar's job indicator in its
/// "needs attention" state after it finished.
const kJobFailureAttentionWindow = Duration(hours: 24);

class JobsProvider extends ChangeNotifier with ActiveServerFollower {
  final ServerClientSession _session;
  final TelemetryServiceInterface? _telemetryService;
  List<Job> _jobs = [];
  String? _error;
  bool _isLoading = false;
  bool _isSubscribed = false;
  StreamSubscription<List<Job>>? _jobsSubscription;

  JobsProvider(
    ServerCredentialsLookup credentials, {
    required ApiClientManagerInterface clientManager,
    TelemetryServiceInterface? telemetryService,
    ValueListenable<NasServer?>? activeServer,
  }) : _telemetryService = telemetryService,
       _session = ServerClientSession(
         owner: 'JobsProvider',
         clientManager: clientManager,
         credentials: credentials,
         telemetry: telemetryService,
       ) {
    followActiveServer(activeServer);
  }

  ApiClientInterface? get _apiClient => _session.client;

  List<Job> get jobs => _jobs;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isSubscribed => _isSubscribed;
  bool get hasData => _jobs.isNotEmpty;

  List<Job> get runningJobs => _jobs.where((job) => job.isRunning).toList();
  List<Job> get waitingJobs => _jobs.where((job) => job.isWaiting).toList();
  List<Job> get historyJobs => _jobs.where((job) => job.isFinished).toList()
    ..sort(
      (a, b) => (b.timeFinished ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.timeFinished ?? DateTime.fromMillisecondsSinceEpoch(0)),
    );

  int get runningCount => runningJobs.length;
  int get waitingCount => waitingJobs.length;

  /// Jobs that failed within [kJobFailureAttentionWindow].
  List<Job> get recentFailures => historyJobs
      .where(
        (job) =>
            job.isFailed &&
            job.timeFinished != null &&
            DateTime.now().difference(job.timeFinished!) <
                kJobFailureAttentionWindow,
      )
      .toList();

  /// Whether the nav bar's job indicator should show the "needs attention"
  /// state: nothing running right now, but something failed recently.
  bool get needsAttention => runningCount == 0 && recentFailures.isNotEmpty;

  @override
  Future<void> setServer(NasServer server) async {
    if (_apiClient != null) {
      await unsubscribeFromJobs();
    }
    await _session.connect(server);
  }

  Future<void> subscribeToJobs() async {
    final pendingSwitch = pendingServerSwitch;
    if (pendingSwitch != null) await pendingSwitch;
    if (_apiClient == null) {
      _setError('No API client configured');
      return;
    }

    if (_isSubscribed) {
      _log.debug('Already subscribed to jobs');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      final initial = await _apiClient!.getJobs();
      _jobs = initial;
      notifyListeners();

      await _apiClient!.subscribeToJobs();

      _jobsSubscription = _apiClient!.jobsStream.listen(
        _onJobsReceived,
        onError: _onJobsError,
        onDone: _onJobsStreamDone,
      );

      _isSubscribed = true;
      _log.info('Successfully subscribed to jobs stream');
    } catch (e, stackTrace) {
      _setError('Failed to subscribe to jobs: ${e.toString()}');
      _log.error('Subscription error', error: e);
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'JobsProvider.subscribeToJobs',
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> unsubscribeFromJobs() async {
    if (!_isSubscribed) {
      return;
    }

    try {
      await _jobsSubscription?.cancel();
      _jobsSubscription = null;

      if (_apiClient != null) {
        await _apiClient!.unsubscribeFromJobs();
      }

      _isSubscribed = false;
      _jobs = [];
      _clearError();

      _log.info('Successfully unsubscribed from jobs');
    } catch (e, stackTrace) {
      _log.error('Error during unsubscription', error: e);
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'JobsProvider.unsubscribeFromJobs',
      );
    }

    notifyListeners();
  }

  /// Re-fetches the current job list without touching the live subscription;
  /// starts one if there isn't one yet. Used for a pull-to-refresh / manual
  /// reload affordance since job updates otherwise arrive push-only.
  Future<void> refreshJobs() async {
    if (_apiClient == null) {
      _setError('No API client configured');
      return;
    }

    if (!_isSubscribed) {
      await subscribeToJobs();
      return;
    }

    try {
      _clearError();
      _jobs = await _apiClient!.getJobs();
      notifyListeners();
    } catch (e, stackTrace) {
      _setError('Failed to refresh jobs: ${e.toString()}');
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'JobsProvider.refreshJobs',
      );
    }
  }

  Future<bool> abortJob(int jobId) async {
    if (_apiClient == null) {
      _setError('No API client configured');
      return false;
    }

    try {
      await _apiClient!.abortJob(jobId);
      return true;
    } catch (e, stackTrace) {
      _setError('Failed to cancel job: ${e.toString()}');
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'JobsProvider.abortJob',
      );
      return false;
    }
  }

  Future<bool> rerunJob(Job job) async {
    if (_apiClient == null) {
      _setError('No API client configured');
      return false;
    }

    try {
      await _apiClient!.rerunJob(job);
      return true;
    } catch (e, stackTrace) {
      _setError('Failed to retry job: ${e.toString()}');
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'JobsProvider.rerunJob',
      );
      return false;
    }
  }

  void _onJobsReceived(List<Job> jobs) {
    _jobs = jobs;
    _clearError();
    _setLoading(false);
    notifyListeners();
  }

  void _onJobsError(dynamic error) {
    _setError('Jobs stream error: ${error.toString()}');
    _setLoading(false);
    _log.error('Stream error', error: error);
  }

  void _onJobsStreamDone() {
    _isSubscribed = false;
    _setLoading(false);
    _log.debug('Jobs stream done');
    notifyListeners();
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    _setLoading(false);
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _log.info('Disposing');
    // Can't await in dispose(); fire-and-forget cleanup, same pattern as
    // SystemStatsProvider.dispose().
    _jobsSubscription?.cancel();
    _jobsSubscription = null;
    if (_apiClient != null) {
      _apiClient!.unsubscribeFromJobs().catchError((_) {});
    }
    _isSubscribed = false;

    _session.dispose();
    super.dispose();
  }
}
