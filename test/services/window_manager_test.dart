import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/services/window_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Same MethodChannel `test/providers/tray_provider_test.dart` mocks for
  // WindowManager - the native side is unmocked in the `flutter test` VM,
  // so a handler is registered here to both prove each method sends the
  // right call and to exercise the PlatformException catch branch on
  // demand.
  const channel = MethodChannel('com.truenas.manager/window');

  final calls = <MethodCall>[];
  Object? Function(MethodCall)? throwFor;

  setUp(() {
    calls.clear();
    throwFor = null;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          final thrown = throwFor?.call(call);
          if (thrown != null) throw thrown;
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('WindowManager - showWindow', () {
    test('invokes showWindow on the platform channel', () async {
      await WindowManager.showWindow();
      expect(calls, hasLength(1));
      expect(calls.single.method, 'showWindow');
    });

    test('swallows a PlatformException from the platform side', () async {
      throwFor = (_) => PlatformException(code: 'FAIL');
      await expectLater(WindowManager.showWindow(), completes);
    });
  });

  group('WindowManager - hideWindow', () {
    test('invokes hideWindow on the platform channel', () async {
      await WindowManager.hideWindow();
      expect(calls, hasLength(1));
      expect(calls.single.method, 'hideWindow');
    });

    test('swallows a PlatformException from the platform side', () async {
      throwFor = (_) => PlatformException(code: 'FAIL');
      await expectLater(WindowManager.hideWindow(), completes);
    });
  });

  group('WindowManager - quitApp', () {
    test('invokes quitApp on the platform channel', () async {
      await WindowManager.quitApp();
      expect(calls, hasLength(1));
      expect(calls.single.method, 'quitApp');
    });

    test('swallows a PlatformException from the platform side', () async {
      throwFor = (_) => PlatformException(code: 'FAIL');
      await expectLater(WindowManager.quitApp(), completes);
    });
  });

  group('WindowManager - setDockVisibility', () {
    test('invokes setDockVisibility with the requested visibility', () async {
      await WindowManager.setDockVisibility(true);
      expect(calls, hasLength(1));
      expect(calls.single.method, 'setDockVisibility');
      expect(calls.single.arguments, {'visible': true});

      await WindowManager.setDockVisibility(false);
      expect(calls.last.arguments, {'visible': false});
    });

    test('swallows a PlatformException from the platform side', () async {
      throwFor = (_) => PlatformException(code: 'FAIL');
      await expectLater(WindowManager.setDockVisibility(true), completes);
    });
  });
}
