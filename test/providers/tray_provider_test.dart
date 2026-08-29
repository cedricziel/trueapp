import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/providers/tray_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // WindowManager talks to the native side over this MethodChannel. There is
  // no handler registered for it in the `flutter test` VM, so any call would
  // otherwise throw a MissingPluginException - a type WindowManager's own
  // try/catch (which only catches PlatformException) does not swallow. A
  // mock handler that just answers `null` keeps `setShowInDock`/etc. inert
  // and safe to exercise, the way the real platform channel would be once
  // handled by the native host.
  const windowChannel = MethodChannel('com.truenas.manager/window');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, (call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(windowChannel, null);
  });

  group('TrayProvider - initial state', () {
    test('starts with tray/dock enabled and not initialized', () {
      final provider = TrayProvider();

      expect(provider.minimizeToTray, isTrue);
      expect(provider.showInDock, isTrue);
      expect(provider.isInitialized, isFalse);
    });
  });

  group('TrayProvider - setMinimizeToTray', () {
    test('updates the flag and notifies', () {
      final provider = TrayProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.setMinimizeToTray(false);

      expect(provider.minimizeToTray, isFalse);
      expect(notifications, 1);

      provider.setMinimizeToTray(true);
      expect(provider.minimizeToTray, isTrue);
      expect(notifications, 2);
    });
  });

  group('TrayProvider - setShowInDock', () {
    test('updates the flag, notifies, and does not throw', () {
      final provider = TrayProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.setShowInDock(false);

      expect(provider.showInDock, isFalse);
      expect(notifications, 1);
    });
  });

  group('TrayProvider - setCallbacks', () {
    test('stores callbacks without throwing', () {
      final provider = TrayProvider();
      var showCalled = false;
      var quitCalled = false;
      var refreshCalled = false;

      expect(
        () => provider.setCallbacks(
          onShowWindow: () => showCalled = true,
          onQuitApp: () => quitCalled = true,
          onRefresh: () => refreshCalled = true,
        ),
        returnsNormally,
      );

      // Callbacks are only invoked by tray menu clicks (a native/plugin
      // event this test environment can't simulate); this just proves
      // wiring them up doesn't throw and leaves the flags untouched.
      expect(showCalled, isFalse);
      expect(quitCalled, isFalse);
      expect(refreshCalled, isFalse);
    });

    test('accepts being called with no callbacks', () {
      final provider = TrayProvider();
      expect(() => provider.setCallbacks(), returnsNormally);
    });
  });

  group('TrayProvider - initializeTray', () {
    test('marks itself initialized and notifies exactly once', () async {
      final provider = TrayProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.initializeTray();

      expect(provider.isInitialized, isTrue);
      expect(notifications, 1);
    });

    test('is idempotent on a second call', () async {
      final provider = TrayProvider();
      await provider.initializeTray();

      var notifications = 0;
      provider.addListener(() => notifications++);
      await provider.initializeTray();

      expect(provider.isInitialized, isTrue);
      expect(notifications, 0);
    });
  });

  group('TrayProvider - updateServerStatus / updateTheme', () {
    test('updateServerStatus before initialization is a no-op', () async {
      final provider = TrayProvider();

      await expectLater(
        provider.updateServerStatus(connectedServers: 1, totalServers: 2),
        completes,
      );
    });

    test('updateServerStatus after initialization does not throw', () async {
      final provider = TrayProvider();
      await provider.initializeTray();

      await expectLater(
        provider.updateServerStatus(
          connectedServers: 1,
          totalServers: 2,
          alerts: const ['disk full'],
        ),
        completes,
      );
    });

    test('updateTheme does not throw regardless of init state', () async {
      final provider = TrayProvider();

      await expectLater(provider.updateTheme(isDarkMode: true), completes);

      await provider.initializeTray();
      await expectLater(provider.updateTheme(isDarkMode: false), completes);
    });
  });

  group('TrayProvider - dispose', () {
    test('does not throw', () async {
      final provider = TrayProvider();
      await provider.initializeTray();

      expect(provider.dispose, returnsNormally);
    });
  });
}
