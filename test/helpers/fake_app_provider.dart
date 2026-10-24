import 'dart:async';

import 'package:truehub/models/app.dart';
import 'package:truehub/models/app_config.dart';
import 'package:truehub/providers/app_provider.dart';

import 'test_providers.dart';

/// An [AppProvider] whose apps, config, favorites and lifecycle results a
/// test drives directly, instead of routing everything through a drift
/// database and a fake API.
///
/// Lifecycle calls are recorded in [calls] as `'start:plex'`. Set
/// [actionResult] for the outcome, or [gate] to hold every action open until
/// the test completes it.
class FakeAppProvider extends AppProvider {
  FakeAppProvider({
    required super.daoSource,
    required super.serverService,
    AppConfig? config,
    bool favorite = false,
  }) : _config = config,
       _favorite = favorite,
       super(clientManager: TestProviders.mockApiClientManager);

  final AppConfig? _config;
  bool _favorite;
  List<App> _apps = const [];

  final List<String> calls = [];
  bool actionResult = true;
  Completer<void>? gate;

  int toggleCallCount = 0;
  String? lastToggledAppName;
  bool? lastToggledValue;

  @override
  List<App> get apps => _apps;

  set apps(List<App> value) {
    _apps = value;
    notifyListeners();
  }

  @override
  AppConfig? getAppConfig(String appName) => _config;

  @override
  bool isAppFavorite(String appName) => _favorite;

  @override
  Future<void> setAppFavorite(String appName, bool isFavorite) async {
    toggleCallCount++;
    lastToggledAppName = appName;
    lastToggledValue = isFavorite;
    _favorite = isFavorite;
    notifyListeners();
  }

  @override
  Future<bool> startApp(String appName) => _record('start', appName);

  @override
  Future<bool> stopApp(String appName) => _record('stop', appName);

  @override
  Future<bool> restartApp(String appName) => _record('restart', appName);

  @override
  Future<bool> upgradeApp(String appName, {String? version}) =>
      _record('upgrade', appName);

  Future<bool> _record(String verb, String appName) async {
    calls.add('$verb:$appName');
    await gate?.future;
    return actionResult;
  }
}
