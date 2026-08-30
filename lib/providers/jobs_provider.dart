import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:truehub/models/job.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/services/api_client_manager.dart';
import 'package:truehub/services/unified_server_service.dart';

/// How long a failed job keeps the nav bar's job indicator in its
/// "needs attention" state after it finished.
const kJobFailureAttentionWindow = Duration(hours: 24);

class JobsProvider extends ChangeNotifier {
  final UnifiedServerService _serverService;
  ApiClientInterface? _apiClient;
  String? _currentServerId;
  List<Job> _jobs = [];
  String? _error;
  bool _isLoading = false;
  bool _isSubscribed = false;
  StreamSubscription<List<Job>>? _jobsSubscription;

  JobsProvider(this._serverService);

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

  Future<void> setApiClient(NasServer server) async {
    if (_apiClient != null) {
      await unsubscribeFromJobs();
    }

    if (_currentServerId != null) {
      await ApiClientManager.releaseClient(_currentServerId!);
    }

    _currentServerId = server.id;

    try {
      final serverWithCredentials = await ServerProvider.loadServerCredentials(
        server,
        _serverService,
      );

      if (serverWithCredentials != null) {
        _apiClient = await ApiClientManager.getClient(serverWithCredentials);
      } else {
        if (kDebugMode) {
          print(
            'JobsProvider: No credentials available for server ${server.id}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('JobsProvider: Failed to get API client: $e');
      }
    }
  }

  Future<void> subscribeToJobs() async {
    if (_apiClient == null) {
      _setError('No API client configured');
      return;
    }

    if (_isSubscribed) {
      if (kDebugMode) {
        print('JobsProvider: Already subscribed to jobs');
      }
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
      if (kDebugMode) {
        print('JobsProvider: Successfully subscribed to jobs stream');
      }
    } catch (e) {
      _setError('Failed to subscribe to jobs: ${e.toString()}');
      if (kDebugMode) {
        print('JobsProvider: Subscription error: $e');
      }
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

      if (kDebugMode) {
        print('JobsProvider: Successfully unsubscribed from jobs');
      }
    } catch (e) {
      if (kDebugMode) {
        print('JobsProvider: Error during unsubscription: $e');
      }
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
    } catch (e) {
      _setError('Failed to refresh jobs: ${e.toString()}');
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
    } catch (e) {
      _setError('Failed to cancel job: ${e.toString()}');
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
    } catch (e) {
      _setError('Failed to retry job: ${e.toString()}');
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
    if (kDebugMode) {
      print('JobsProvider: Stream error: $error');
    }
  }

  void _onJobsStreamDone() {
    _isSubscribed = false;
    _setLoading(false);
    if (kDebugMode) {
      print('JobsProvider: Jobs stream done');
    }
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
    if (kDebugMode) {
      print('JobsProvider: Disposing');
    }
    // Can't await in dispose(); fire-and-forget cleanup, same pattern as
    // SystemStatsProvider.dispose().
    _jobsSubscription?.cancel();
    _jobsSubscription = null;
    if (_apiClient != null) {
      _apiClient!.unsubscribeFromJobs().catchError((_) {});
    }
    _isSubscribed = false;

    if (_currentServerId != null) {
      ApiClientManager.releaseClient(_currentServerId!);
    }
    super.dispose();
  }
}
