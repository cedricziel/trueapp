import 'dart:async';

import 'package:truehub/models/alert.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/models/file_item.dart';
import 'package:truehub/models/job.dart';
import 'package:truehub/models/pool.dart';
import 'package:truehub/models/service_status.dart';
import 'package:truehub/models/server_health.dart';
import 'package:truehub/models/system_stats.dart';
import 'package:truehub/models/user_info.dart';
import 'package:truehub/services/api_client_interface.dart';

/// In-memory [ApiClientInterface] double for provider tests.
///
/// Providers only ever reach the API client through [ApiClientManagerInterface]
/// (see `MockApiClientManager.addMockClient`), so this fake is what lets a
/// provider test exercise the success path of a method - `getPools()`,
/// `getDatasets()`, `getAvailableApps()`, ... - without a real WebSocket
/// connection. Every response is a settable field with a reasonable empty
/// default; set it before calling into the provider under test.
///
/// Any method can be made to throw by adding its name to [failingMethods].
class FakeApiClient implements ApiClientInterface {
  final List<String> calls = [];
  final Set<String> failingMethods = {};

  void _recordAndMaybeThrow(String method) {
    calls.add(method);
    if (failingMethods.contains(method)) {
      throw Exception('FakeApiClient: $method configured to fail');
    }
  }

  @override
  Future<void> close() async {
    _recordAndMaybeThrow('close');
  }

  @override
  Future<bool> testConnection() async {
    _recordAndMaybeThrow('testConnection');
    return testConnectionResult;
  }

  bool testConnectionResult = true;

  @override
  void setKeepaliveInterval(Duration interval) {
    calls.add('setKeepaliveInterval');
    keepaliveInterval = interval;
  }

  Duration keepaliveInterval = const Duration(seconds: 30);

  @override
  void enableKeepalive(bool enabled) {
    calls.add('enableKeepalive');
    isKeepaliveActive = enabled;
  }

  @override
  bool isKeepaliveActive = true;

  @override
  Future<bool> validateLogin(
    String username,
    String password, [
    String? otpToken,
  ]) async {
    _recordAndMaybeThrow('validateLogin');
    return validateLoginResult;
  }

  bool validateLoginResult = true;

  @override
  Future<UserInfo> getCurrentUser() async {
    _recordAndMaybeThrow('getCurrentUser');
    return currentUser;
  }

  UserInfo currentUser = const UserInfo(
    username: 'admin',
    fullName: 'Administrator',
    homeDirectory: '/home/admin',
    shell: '/bin/bash',
    uid: 0,
    gid: 0,
    source: 'LOCAL',
    isLocal: true,
    groupList: [],
    attributes: {},
    hasTwoFactor: false,
    privilege: {},
  );

  List<Map<String, dynamic>> pools = [];

  @override
  Future<List<Pool>> getPools() async {
    _recordAndMaybeThrow('getPools');
    return pools.map(Pool.fromJson).toList();
  }

  List<Map<String, dynamic>> datasets = [];

  @override
  Future<List<Map<String, dynamic>>> getDatasets() async {
    _recordAndMaybeThrow('getDatasets');
    return datasets;
  }

  @override
  Future<List<FileItem>> getDirectoryListing(String path) async {
    _recordAndMaybeThrow('getDirectoryListing');
    return directoryListing;
  }

  List<FileItem> directoryListing = [];

  @override
  Future<List<Alert>> getAlerts() async {
    _recordAndMaybeThrow('getAlerts');
    return alerts.map(Alert.fromJson).toList();
  }

  List<Map<String, dynamic>> alerts = [];

  @override
  Future<List<ServiceStatus>> getServices() async {
    _recordAndMaybeThrow('getServices');
    return services.map(ServiceStatus.fromJson).toList();
  }

  List<Map<String, dynamic>> services = [];

  @override
  Future<ServerHealth> getServerHealth() async {
    _recordAndMaybeThrow('getServerHealth');
    return serverHealth;
  }

  ServerHealth serverHealth = ServerHealth(
    serverId: 'test-server',
    timestamp: DateTime(2026),
    cpuUsage: 0,
    memoryUsage: 0,
    diskUsage: 0,
    temperature: 0,
    isOnline: true,
    disks: const [],
    network: const NetworkInfo(
      downloadSpeed: 0,
      uploadSpeed: 0,
      totalDownload: 0,
      totalUpload: 0,
    ),
  );

  @override
  Future<List<App>> getAvailableApps() async {
    _recordAndMaybeThrow('getAvailableApps');
    return availableApps;
  }

  List<App> availableApps = [];

  @override
  Future<List<App>> getInstalledApps() async {
    _recordAndMaybeThrow('getInstalledApps');
    return installedApps;
  }

  List<App> installedApps = [];

  @override
  Future<List<String>> getAppCategories() async {
    _recordAndMaybeThrow('getAppCategories');
    return appCategories;
  }

  List<String> appCategories = [];

  @override
  Future<bool> upgradeApp(String appName, {String? version}) async {
    _recordAndMaybeThrow('upgradeApp');
    return upgradeAppResult;
  }

  bool upgradeAppResult = true;

  @override
  Future<bool> startApp(String appName) async {
    _recordAndMaybeThrow('startApp');
    return startAppResult;
  }

  bool startAppResult = true;

  @override
  Future<bool> stopApp(String appName) async {
    _recordAndMaybeThrow('stopApp');
    return stopAppResult;
  }

  bool stopAppResult = true;

  @override
  Future<bool> restartApp(String appName) async {
    _recordAndMaybeThrow('restartApp');
    return restartAppResult;
  }

  bool restartAppResult = true;

  final StreamController<SystemStats> _systemStatsController =
      StreamController<SystemStats>.broadcast();

  @override
  Stream<SystemStats> get systemStatsStream => _systemStatsController.stream;

  /// Pushes [stats] to every current [systemStatsStream] listener.
  void emitSystemStats(SystemStats stats) => _systemStatsController.add(stats);

  @override
  Future<void> ensureConnectionAlive() async {
    _recordAndMaybeThrow('ensureConnectionAlive');
  }

  @override
  Future<void> subscribeToSystemStats() async {
    _recordAndMaybeThrow('subscribeToSystemStats');
  }

  @override
  Future<void> unsubscribeFromSystemStats() async {
    _recordAndMaybeThrow('unsubscribeFromSystemStats');
  }

  final StreamController<Map<String, AppResourceUsage>> _appStatsController =
      StreamController<Map<String, AppResourceUsage>>.broadcast();

  @override
  Stream<Map<String, AppResourceUsage>> get appStatsStream =>
      _appStatsController.stream;

  /// Pushes [usage] to every current [appStatsStream] listener.
  void emitAppStats(Map<String, AppResourceUsage> usage) =>
      _appStatsController.add(usage);

  @override
  Future<void> subscribeToAppStats() async {
    _recordAndMaybeThrow('subscribeToAppStats');
  }

  @override
  Future<void> unsubscribeFromAppStats() async {
    _recordAndMaybeThrow('unsubscribeFromAppStats');
  }

  @override
  Future<List<Job>> getJobs() async {
    _recordAndMaybeThrow('getJobs');
    return jobs;
  }

  List<Job> jobs = [];

  final StreamController<List<Job>> _jobsController =
      StreamController<List<Job>>.broadcast();

  @override
  Stream<List<Job>> get jobsStream => _jobsController.stream;

  /// Pushes [jobList] to every current [jobsStream] listener.
  void emitJobs(List<Job> jobList) => _jobsController.add(jobList);

  @override
  Future<void> subscribeToJobs() async {
    _recordAndMaybeThrow('subscribeToJobs');
  }

  @override
  Future<void> unsubscribeFromJobs() async {
    _recordAndMaybeThrow('unsubscribeFromJobs');
  }

  @override
  Future<void> abortJob(int jobId) async {
    _recordAndMaybeThrow('abortJob');
    lastAbortedJobId = jobId;
  }

  int? lastAbortedJobId;

  @override
  Future<int> rerunJob(Job job) async {
    _recordAndMaybeThrow('rerunJob');
    lastRerunJob = job;
    return rerunJobResult;
  }

  Job? lastRerunJob;
  int rerunJobResult = 0;

  /// Closes the stream controllers backing [systemStatsStream],
  /// [appStatsStream] and [jobsStream]. Call from a test's `tearDown` if the
  /// fake was used with subscriptions.
  Future<void> dispose() async {
    await _systemStatsController.close();
    await _appStatsController.close();
    await _jobsController.close();
  }
}
