import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final _connectivity = Connectivity();
  final _networkInfo = NetworkInfo();

  /// Check if location permission is granted for Wi-Fi access
  Future<bool> hasLocationPermission() async {
    final status = await Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  /// Request location permission for Wi-Fi access
  Future<bool> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  /// Check if device is connected to WiFi
  Future<bool> isConnectedToWifi() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.wifi);
  }

  /// Get current WiFi SSID (with permission handling)
  Future<String?> getCurrentWifiSsid() async {
    try {
      if (!await isConnectedToWifi()) {
        return null;
      }

      // Check if we have permission
      if (!await hasLocationPermission()) {
        return null; // Don't request permission automatically
      }

      final ssid = await _networkInfo.getWifiName();
      if (ssid != null) {
        // Remove quotes if present (some platforms return quoted SSIDs)
        return ssid.replaceAll('"', '');
      }
      return null;
    } catch (e) {
      // WiFi name access may fail due to permissions or platform restrictions
      return null;
    }
  }

  /// Get current WiFi SSID with permission request
  Future<String?> getCurrentWifiSsidWithPermission() async {
    try {
      if (!await isConnectedToWifi()) {
        return null;
      }

      // Request permission if not granted
      if (!await hasLocationPermission()) {
        final granted = await requestLocationPermission();
        if (!granted) {
          return null;
        }
      }

      final ssid = await _networkInfo.getWifiName();
      if (ssid != null) {
        // Remove quotes if present (some platforms return quoted SSIDs)
        return ssid.replaceAll('"', '');
      }
      return null;
    } catch (e) {
      // WiFi name access may fail due to permissions or platform restrictions
      return null;
    }
  }

  /// Check if current WiFi SSID is in the list of trusted SSIDs
  Future<bool> isOnTrustedNetwork(List<String> trustedSsids) async {
    if (trustedSsids.isEmpty) return false;

    final currentSsid = await getCurrentWifiSsid();
    if (currentSsid == null) return false;

    // Remove quotes from SSID if present (some platforms return quoted SSIDs)
    final cleanSsid = currentSsid.replaceAll('"', '');

    return trustedSsids.contains(cleanSsid);
  }

  /// Stream of connectivity changes
  Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  /// Stream of network changes (including WiFi SSID changes)
  Stream<String?> get wifiSsidStream {
    return _connectivity.onConnectivityChanged.asyncMap((_) async {
      return await getCurrentWifiSsid();
    });
  }
}
