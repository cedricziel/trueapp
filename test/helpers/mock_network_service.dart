import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:truehub/services/network_service.dart';

/// Mock implementation of NetworkService for testing
class MockNetworkService implements NetworkService {
  bool _hasLocationPermission = false;
  bool _isConnectedToWifi = false;
  String? _currentWifiSsid;
  bool _shouldFailOperations = false;

  @override
  Future<bool> hasLocationPermission() async {
    if (_shouldFailOperations) throw Exception('Mock error');
    return _hasLocationPermission;
  }

  @override
  Future<bool> requestLocationPermission() async {
    if (_shouldFailOperations) throw Exception('Mock error');
    _hasLocationPermission = true;
    return true;
  }

  @override
  Future<bool> isConnectedToWifi() async {
    if (_shouldFailOperations) throw Exception('Mock error');
    return _isConnectedToWifi;
  }

  @override
  Future<String?> getCurrentWifiSsid() async {
    if (_shouldFailOperations) throw Exception('Mock error');
    if (!_isConnectedToWifi) return null;
    if (!_hasLocationPermission) return null;
    return _currentWifiSsid;
  }

  @override
  Future<String?> getCurrentWifiSsidWithPermission() async {
    if (_shouldFailOperations) throw Exception('Mock error');
    if (!_isConnectedToWifi) return null;
    _hasLocationPermission = true;
    return _currentWifiSsid;
  }

  // Test helpers
  void setHasLocationPermission(bool value) {
    _hasLocationPermission = value;
  }

  void setIsConnectedToWifi(bool value) {
    _isConnectedToWifi = value;
  }

  void setCurrentWifiSsid(String? ssid) {
    _currentWifiSsid = ssid;
  }

  void setShouldFailOperations(bool value) {
    _shouldFailOperations = value;
  }

  @override
  Future<bool> isOnTrustedNetwork(List<String> trustedSsids) async {
    if (_shouldFailOperations) throw Exception('Mock error');
    if (trustedSsids.isEmpty) return false;
    if (_currentWifiSsid == null) return false;
    return trustedSsids.contains(_currentWifiSsid);
  }

  @override
  Stream<List<ConnectivityResult>> get connectivityStream {
    return Stream.value([
      _isConnectedToWifi ? ConnectivityResult.wifi : ConnectivityResult.none,
    ]);
  }

  @override
  Stream<String?> get wifiSsidStream {
    return Stream.value(_currentWifiSsid);
  }
}
