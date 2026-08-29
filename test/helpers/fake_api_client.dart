import 'dart:async';

import 'package:truehub/models/app.dart';
import 'package:truehub/models/file_item.dart';
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

  @override
  Future<Map<String, dynamic>> getSystemInfo() async {
    _recordAndMaybeThrow('getSystemInfo');
    return systemInfo;
  }

  Map<String, dynamic> systemInfo = {};

  @override
  Future<Map<String, dynamic>> getSystemCpuInfo() async {
    _recordAndMaybeThrow('getSystemCpuInfo');
    return systemCpuInfo;
  }

  Map<String, dynamic> systemCpuInfo = {};

  @override
  Future<Map<String, dynamic>> getSystemMemoryInfo() async {
    _recordAndMaybeThrow('getSystemMemoryInfo');
    return systemMemoryInfo;
  }

  Map<String, dynamic> systemMemoryInfo = {};

  @override
  Future<double> getSystemTemperature() async {
    _recordAndMaybeThrow('getSystemTemperature');
    return systemTemperature;
  }

  double systemTemperature = 0;

  @override
  Future<List<Map<String, dynamic>>> queryPools() async {
    _recordAndMaybeThrow('queryPools');
    return pools;
  }

  List<Map<String, dynamic>> pools = [];

  @override
  Future<Map<String, dynamic>> getPoolById(String id) async {
    _recordAndMaybeThrow('getPoolById');
    return poolById;
  }

  Map<String, dynamic> poolById = {};

  @override
  Future<List<Map<String, dynamic>>> getPools() async {
    _recordAndMaybeThrow('getPools');
    return pools;
  }

  @override
  Future<List<Map<String, dynamic>>> queryDatasets() async {
    _recordAndMaybeThrow('queryDatasets');
    return datasets;
  }

  List<Map<String, dynamic>> datasets = [];

  @override
  Future<Map<String, dynamic>> getDatasetById(String id) async {
    _recordAndMaybeThrow('getDatasetById');
    return datasetById;
  }

  Map<String, dynamic> datasetById = {};

  @override
  Future<List<Map<String, dynamic>>> getDatasets() async {
    _recordAndMaybeThrow('getDatasets');
    return datasets;
  }

  @override
  Future<List<Map<String, dynamic>>> listDirectory(String path) async {
    _recordAndMaybeThrow('listDirectory');
    return directoryEntries;
  }

  List<Map<String, dynamic>> directoryEntries = [];

  @override
  Future<Map<String, dynamic>> getFileInfo(String path) async {
    _recordAndMaybeThrow('getFileInfo');
    return fileInfo;
  }

  Map<String, dynamic> fileInfo = {};

  @override
  Future<List<FileItem>> getDirectoryListing(String path) async {
    _recordAndMaybeThrow('getDirectoryListing');
    return directoryListing;
  }

  List<FileItem> directoryListing = [];

  @override
  Future<List<Map<String, dynamic>>> queryDisks() async {
    _recordAndMaybeThrow('queryDisks');
    return disks;
  }

  List<Map<String, dynamic>> disks = [];

  @override
  Future<Map<String, dynamic>> getDiskById(String id) async {
    _recordAndMaybeThrow('getDiskById');
    return diskById;
  }

  Map<String, dynamic> diskById = {};

  @override
  Future<Map<String, dynamic>> getNetworkInfo() async {
    _recordAndMaybeThrow('getNetworkInfo');
    return networkInfo;
  }

  Map<String, dynamic> networkInfo = {};

  @override
  Future<List<Map<String, dynamic>>> getNetworkInterfaces() async {
    _recordAndMaybeThrow('getNetworkInterfaces');
    return networkInterfaces;
  }

  List<Map<String, dynamic>> networkInterfaces = [];

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
  Future<Map<String, dynamic>> getDockerStatus() async {
    _recordAndMaybeThrow('getDockerStatus');
    return dockerStatus;
  }

  Map<String, dynamic> dockerStatus = {};

  @override
  Future<Map<String, dynamic>> getAppResourceUsage(String appName) async {
    _recordAndMaybeThrow('getAppResourceUsage');
    return appResourceUsage;
  }

  Map<String, dynamic> appResourceUsage = {};

  @override
  Future<Map<String, dynamic>> getAppUpgradeInfo(String appName) async {
    _recordAndMaybeThrow('getAppUpgradeInfo');
    return appUpgradeInfo;
  }

  Map<String, dynamic> appUpgradeInfo = {};

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
  void emitSystemStats(SystemStats stats) =>
      _systemStatsController.add(stats);

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
  Future<Map<String, dynamic>> getSystemGeneralConfig() async {
    _recordAndMaybeThrow('getSystemGeneralConfig');
    return systemGeneralConfig;
  }

  Map<String, dynamic> systemGeneralConfig = {};

  @override
  Future<Map<String, dynamic>> getSystemAdvancedConfig() async {
    _recordAndMaybeThrow('getSystemAdvancedConfig');
    return systemAdvancedConfig;
  }

  Map<String, dynamic> systemAdvancedConfig = {};

  @override
  Future<String> getSystemProductType() async {
    _recordAndMaybeThrow('getSystemProductType');
    return systemProductType;
  }

  String systemProductType = 'COMMUNITY_EDITION';

  @override
  Future<bool> isIxHardware() async {
    _recordAndMaybeThrow('isIxHardware');
    return isIxHardwareResult;
  }

  bool isIxHardwareResult = false;

  /// Closes the stream controllers backing [systemStatsStream] and
  /// [appStatsStream]. Call from a test's `tearDown` if the fake was used
  /// with subscriptions.
  Future<void> dispose() async {
    await _systemStatsController.close();
    await _appStatsController.close();
  }
}
