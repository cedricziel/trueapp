part of '../truenas_api_client.dart';

mixin _JobsOps on _ClientTransport implements JobsApi {
  @override
  Future<List<Job>> getJobs() async {
    try {
      final result = await _sendRequest('core.get_jobs');
      final jobs = (result as List<dynamic>).cast<Map<String, dynamic>>().map(
        Job.fromJson,
      );
      _jobsById
        ..clear()
        ..addEntries(jobs.map((job) => MapEntry(job.id, job)));
      return _jobsById.values.toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Stream<List<Job>> get jobsStream {
    _jobsController ??= StreamController<List<Job>>.broadcast();
    return _jobsController!.stream;
  }

  @override
  Future<void> subscribeToJobs() async {
    _wantsJobs = true;

    if (_isSubscribedToJobs && _hasLiveConnection) {
      _log.debug('Already subscribed to jobs');
      return;
    }

    _isSubscribedToJobs = false;
    _jobsSubscriptionId = null;

    try {
      await _ensureAuthenticated();

      _jobsController ??= StreamController<List<Job>>.broadcast();

      _jobsSubscriptionId =
          await _request('core.subscribe', ['core.get_jobs']) as String;

      _isSubscribedToJobs = true;

      _log.info(
        'Subscribed to jobs',
        attributes: {'subscription.id': _jobsSubscriptionId},
      );
    } catch (e) {
      _log.error('Failed to subscribe to jobs', error: e);
      throw _handleError(e);
    }
  }

  @override
  Future<void> unsubscribeFromJobs() async {
    if (!_isSubscribedToJobs || _jobsSubscriptionId == null) {
      return;
    }

    try {
      if (_hasLiveConnection) {
        await _request('core.unsubscribe', [_jobsSubscriptionId!]);

        _log.info(
          'Unsubscribed from jobs',
          attributes: {'subscription.id': _jobsSubscriptionId},
        );
      }
    } catch (e) {
      _log.error('Error unsubscribing from jobs', error: e);
    } finally {
      _wantsJobs = false;
      _isSubscribedToJobs = false;
      _jobsSubscriptionId = null;
      _jobsById.clear();
      await _jobsController?.close();
      _jobsController = null;

      _log.info('Job subscription cleaned up');
    }
  }

  @override
  Future<void> abortJob(int jobId) async {
    try {
      await _ensureAuthenticated();
      await _request('core.job_abort', [jobId]);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<int> rerunJob(Job job) async {
    try {
      await _ensureAuthenticated();
      final result = await _request(job.method, job.arguments);
      return result as int;
    } catch (e) {
      throw _handleError(e);
    }
  }
}
