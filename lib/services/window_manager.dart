import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WindowManager {
  static const platform = MethodChannel('com.truenas.manager/window');

  static Future<void> showWindow() async {
    // Only available on desktop platforms
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) return;

    try {
      await platform.invokeMethod('showWindow');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to show window: ${e.message}');
      }
    }
  }

  static Future<void> hideWindow() async {
    // Only available on desktop platforms
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) return;

    try {
      await platform.invokeMethod('hideWindow');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to hide window: ${e.message}');
      }
    }
  }

  static Future<void> quitApp() async {
    // Only available on desktop platforms
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) return;

    try {
      await platform.invokeMethod('quitApp');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to quit app: ${e.message}');
      }
    }
  }

  static Future<void> setDockVisibility(bool visible) async {
    // Only available on desktop platforms
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) return;

    try {
      await platform.invokeMethod('setDockVisibility', {'visible': visible});
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to set dock visibility: ${e.message}');
      }
    }
  }
}
