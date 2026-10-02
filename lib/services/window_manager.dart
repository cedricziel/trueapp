import 'dart:io';
import 'package:flutter/services.dart';
import 'package:truehub/services/app_logger.dart';

final _log = appLogger('platform.window');

class WindowManager {
  static const platform = MethodChannel('com.truenas.manager/window');

  static Future<void> showWindow() async {
    // Only available on desktop platforms
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) return;

    try {
      await platform.invokeMethod('showWindow');
    } on PlatformException catch (e) {
      _log.error('Failed to show window', error: e);
    }
  }

  static Future<void> hideWindow() async {
    // Only available on desktop platforms
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) return;

    try {
      await platform.invokeMethod('hideWindow');
    } on PlatformException catch (e) {
      _log.error('Failed to hide window', error: e);
    }
  }

  static Future<void> quitApp() async {
    // Only available on desktop platforms
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) return;

    try {
      await platform.invokeMethod('quitApp');
    } on PlatformException catch (e) {
      _log.error('Failed to quit app', error: e);
    }
  }

  static Future<void> setDockVisibility(bool visible) async {
    // Only available on desktop platforms
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) return;

    try {
      await platform.invokeMethod('setDockVisibility', {'visible': visible});
    } on PlatformException catch (e) {
      _log.error('Failed to set dock visibility', error: e);
    }
  }
}
