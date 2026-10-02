import 'dart:async';
import 'package:truehub/models/server_health.dart';
import 'package:truehub/models/file_item.dart';
import 'package:truehub/models/user_info.dart';
import 'package:truehub/models/alert.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/models/job.dart';
import 'package:truehub/models/pool.dart';
import 'package:truehub/models/service_status.dart';
import 'package:truehub/models/system_stats.dart';

/// Interface for TrueNAS API clients to enable dependency injection and testing
abstract class ApiClientInterface {
  // Connection management
  Future<void> close();
  Future<bool> testConnection();

  // Keepalive management
  void setKeepaliveInterval(Duration interval);
  void enableKeepalive(bool enabled);
  bool get isKeepaliveActive;

  // Authentication methods
  Future<bool> validateLogin(
    String username,
    String password, [
    String? otpToken,
  ]);
  Future<UserInfo> getCurrentUser();

  // Pool management methods
  Future<List<Pool>> getPools();

  // Dataset management methods
  Future<List<Map<String, dynamic>>> getDatasets();

  // File system methods
  Future<List<FileItem>> getDirectoryListing(String path);

  // Higher-level methods
  Future<ServerHealth> getServerHealth();

  // Health center methods
  Future<List<Alert>> getAlerts();
  Future<List<ServiceStatus>> getServices();

  // App management methods
  Future<List<App>> getAvailableApps();
  Future<List<App>> getInstalledApps();
  Future<List<String>> getAppCategories();
  Future<bool> upgradeApp(String appName, {String? version});
  Future<bool> startApp(String appName);
  Future<bool> stopApp(String appName);
  Future<bool> restartApp(String appName);

  // System stats subscription methods
  Stream<SystemStats> get systemStatsStream;

  /// Verify the connection is still usable and recover it if it is not.
  /// Called when the app returns to the foreground.
  Future<void> ensureConnectionAlive();

  Future<void> subscribeToSystemStats();
  Future<void> unsubscribeFromSystemStats();

  // App stats subscription methods
  Stream<Map<String, AppResourceUsage>> get appStatsStream;
  Future<void> subscribeToAppStats();
  Future<void> unsubscribeFromAppStats();

  // Job management methods
  Stream<List<Job>> get jobsStream;
  Future<List<Job>> getJobs();
  Future<void> subscribeToJobs();
  Future<void> unsubscribeFromJobs();
  Future<void> abortJob(int jobId);

  /// Re-submits a finished job's original call, e.g. to retry a failed one.
  /// Returns the new job's id.
  Future<int> rerunJob(Job job);
}
