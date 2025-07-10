import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final _connectivity = Connectivity();
  final _networkInfo = NetworkInfo();

  /// Check if device is connected to WiFi
  Future<bool> isConnectedToWifi() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.wifi);
  }

  /// Get current WiFi SSID
  Future<String?> getCurrentWifiSsid() async {
    try {
      if (await isConnectedToWifi()) {
        return await _networkInfo.getWifiName();
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
