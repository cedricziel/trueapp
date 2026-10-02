import 'dart:async';

import 'package:truehub/models/alert.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/models/file_item.dart';
import 'package:truehub/models/job.dart';
import 'package:truehub/models/pool.dart';
import 'package:truehub/models/server_health.dart';
import 'package:truehub/models/service_status.dart';
import 'package:truehub/models/system_stats.dart';
import 'package:truehub/models/user_info.dart';

/// Connection lifecycle, authentication and keepalive.
abstract interface class SessionApi {
  Future<void> close();

  void setKeepaliveInterval(Duration interval);
  void enableKeepalive(bool enabled);
  bool get isKeepaliveActive;

  Future<bool> validateLogin(
    String username,
    String password, [
    String? otpToken,
  ]);
  Future<UserInfo> getCurrentUser();

  /// Verify the connection is still usable and recover it if it is not.
  /// Called when the app returns to the foreground.
  Future<void> ensureConnectionAlive();
}

abstract interface class HealthApi {
  Future<bool> testConnection();
  Future<ServerHealth> getServerHealth();
  Future<List<Alert>> getAlerts();
  Future<List<ServiceStatus>> getServices();
}

abstract interface class ServicesApi {
  Future<void> startService(String serviceId);
  Future<void> stopService(String serviceId);
  Future<void> restartService(String serviceId);
}

abstract interface class PoolsApi {
  Future<List<Pool>> getPools();
}

abstract interface class DatasetsApi {
  Future<List<Map<String, dynamic>>> getDatasets();
}

abstract interface class FilesApi {
  Future<List<FileItem>> getDirectoryListing(String path);
}

abstract interface class AppsApi {
  Future<List<App>> getAvailableApps();
  Future<List<App>> getInstalledApps();
  Future<List<String>> getAppCategories();
  Future<bool> upgradeApp(String appName, {String? version});
  Future<bool> startApp(String appName);
  Future<bool> stopApp(String appName);
  Future<bool> restartApp(String appName);
}

abstract interface class SystemStatsApi {
  Stream<SystemStats> get systemStatsStream;
  Future<void> subscribeToSystemStats();
  Future<void> unsubscribeFromSystemStats();
}

abstract interface class AppStatsApi {
  Stream<Map<String, AppResourceUsage>> get appStatsStream;
  Future<void> subscribeToAppStats();
  Future<void> unsubscribeFromAppStats();
}

abstract interface class JobsApi {
  Stream<List<Job>> get jobsStream;
  Future<List<Job>> getJobs();
  Future<void> subscribeToJobs();
  Future<void> unsubscribeFromJobs();
  Future<void> abortJob(int jobId);

  /// Re-submits a finished job's original call, e.g. to retry a failed one.
  /// Returns the new job's id.
  Future<int> rerunJob(Job job);
}
