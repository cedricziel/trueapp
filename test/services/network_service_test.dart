import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/services/network_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // `NetworkService` is a thin wrapper around three plugins
  // (connectivity_plus, network_info_plus, permission_handler), each
  // talking to the native side over its own `MethodChannel`. None has a
  // handler registered in the `flutter test` VM by default, so every call
  // through them is mocked here the same way
  // `test/providers/tray_provider_test.dart` mocks a plugin channel -
  // driving the service's actual logic (permission gating, SSID
  // quote-stripping, trusted-network matching) against a fake but faithful
  // native side, rather than fighting MissingPluginException.
  const connectivityChannel = MethodChannel(
    'dev.fluttercommunity.plus/connectivity',
  );
  const connectivityEventChannel = EventChannel(
    'dev.fluttercommunity.plus/connectivity_status',
  );
  const networkInfoChannel = MethodChannel(
    'dev.fluttercommunity.plus/network_info',
  );
  const permissionChannel = MethodChannel(
    'flutter.baseflow.com/permissions/methods',
  );

  // Permission.locationWhenInUse's platform-interface `.value` - the key
  // permission_handler uses to identify it across the channel.
  const locationWhenInUsePermissionValue = 5;
  const statusGranted = 1;
  const statusDenied = 0;

  var connectivityResult = <String>['wifi'];
  var wifiName = '"MyNetwork"';
  var permissionStatus = statusGranted;
  var requestResult = statusGranted;
  Object? networkInfoException;
  Object? permissionException;

  final permissionCalls = <MethodCall>[];

  setUp(() {
    connectivityResult = ['wifi'];
    wifiName = '"MyNetwork"';
    permissionStatus = statusGranted;
    requestResult = statusGranted;
    networkInfoException = null;
    permissionException = null;
    permissionCalls.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (call) async {
          if (call.method == 'check') return connectivityResult;
          return null;
        });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(networkInfoChannel, (call) async {
          if (networkInfoException != null) throw networkInfoException!;
          if (call.method == 'wifiName') return wifiName;
          return null;
        });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, (call) async {
          permissionCalls.add(call);
          if (permissionException != null) throw permissionException!;
          switch (call.method) {
            case 'checkPermissionStatus':
              return permissionStatus;
            case 'requestPermissions':
              // Native side returns {permissionValue: statusValue}.
              return <int, int>{
                locationWhenInUsePermissionValue: requestResult,
              };
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(networkInfoChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(connectivityEventChannel, null);
  });

  group('NetworkService - singleton', () {
    test('the factory constructor always returns the same instance', () {
      expect(identical(NetworkService(), NetworkService()), isTrue);
    });
  });

  group('NetworkService - hasLocationPermission', () {
    test('true when the platform reports granted', () async {
      permissionStatus = statusGranted;
      expect(await NetworkService().hasLocationPermission(), isTrue);
    });

    test('false when the platform reports denied', () async {
      permissionStatus = statusDenied;
      expect(await NetworkService().hasLocationPermission(), isFalse);
    });
  });

  group('NetworkService - requestLocationPermission', () {
    test('true when the platform grants the request', () async {
      requestResult = statusGranted;
      expect(await NetworkService().requestLocationPermission(), isTrue);
    });

    test('false when the platform denies the request', () async {
      requestResult = statusDenied;
      expect(await NetworkService().requestLocationPermission(), isFalse);
    });
  });

  group('NetworkService - isConnectedToWifi', () {
    test('true when connectivity includes wifi', () async {
      connectivityResult = ['wifi'];
      expect(await NetworkService().isConnectedToWifi(), isTrue);
    });

    test('false when only mobile is reported', () async {
      connectivityResult = ['mobile'];
      expect(await NetworkService().isConnectedToWifi(), isFalse);
    });

    test('false when nothing is connected', () async {
      connectivityResult = [];
      expect(await NetworkService().isConnectedToWifi(), isFalse);
    });
  });

  group('NetworkService - getCurrentWifiSsid', () {
    test(
      'returns null and skips permission/SSID lookups when off wifi',
      () async {
        connectivityResult = ['mobile'];

        final ssid = await NetworkService().getCurrentWifiSsid();

        expect(ssid, isNull);
        expect(permissionCalls, isEmpty);
      },
    );

    test(
      'returns null without requesting permission when not granted',
      () async {
        connectivityResult = ['wifi'];
        permissionStatus = statusDenied;

        final ssid = await NetworkService().getCurrentWifiSsid();

        expect(ssid, isNull);
        expect(permissionCalls.map((c) => c.method), [
          'checkPermissionStatus',
        ], reason: 'must never call requestPermissions itself');
      },
    );

    test('strips surrounding quotes from the platform SSID', () async {
      connectivityResult = ['wifi'];
      permissionStatus = statusGranted;
      wifiName = '"Home Network"';

      final ssid = await NetworkService().getCurrentWifiSsid();

      expect(ssid, 'Home Network');
    });

    test('returns null when the platform reports no SSID', () async {
      connectivityResult = ['wifi'];
      permissionStatus = statusGranted;
      wifiName = '';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(networkInfoChannel, (call) async => null);

      final ssid = await NetworkService().getCurrentWifiSsid();

      expect(ssid, isNull);
    });

    test('swallows a platform exception and returns null', () async {
      connectivityResult = ['wifi'];
      permissionStatus = statusGranted;
      networkInfoException = PlatformException(code: 'UNAVAILABLE');

      final ssid = await NetworkService().getCurrentWifiSsid();

      expect(ssid, isNull);
    });
  });

  group('NetworkService - getCurrentWifiSsidWithPermission', () {
    test('returns null and never touches permissions when off wifi', () async {
      connectivityResult = ['mobile'];

      final ssid = await NetworkService().getCurrentWifiSsidWithPermission();

      expect(ssid, isNull);
      expect(permissionCalls, isEmpty);
    });

    test(
      'requests permission when not already granted, then fetches the SSID',
      () async {
        connectivityResult = ['wifi'];
        permissionStatus = statusDenied;
        requestResult = statusGranted;
        wifiName = '"Requested Network"';

        final ssid = await NetworkService().getCurrentWifiSsidWithPermission();

        expect(ssid, 'Requested Network');
        expect(permissionCalls.map((c) => c.method), [
          'checkPermissionStatus',
          'requestPermissions',
        ]);
      },
    );

    test('returns null when the requested permission is denied', () async {
      connectivityResult = ['wifi'];
      permissionStatus = statusDenied;
      requestResult = statusDenied;

      final ssid = await NetworkService().getCurrentWifiSsidWithPermission();

      expect(ssid, isNull);
    });

    test(
      'skips the permission request entirely when already granted',
      () async {
        connectivityResult = ['wifi'];
        permissionStatus = statusGranted;
        wifiName = '"Already Granted"';

        final ssid = await NetworkService().getCurrentWifiSsidWithPermission();

        expect(ssid, 'Already Granted');
        expect(permissionCalls.map((c) => c.method), ['checkPermissionStatus']);
      },
    );

    test('swallows a platform exception and returns null', () async {
      connectivityResult = ['wifi'];
      permissionStatus = statusGranted;
      networkInfoException = PlatformException(code: 'UNAVAILABLE');

      final ssid = await NetworkService().getCurrentWifiSsidWithPermission();

      expect(ssid, isNull);
    });
  });

  group('NetworkService - isOnTrustedNetwork', () {
    test(
      'false immediately for an empty trusted list, no lookups made',
      () async {
        final result = await NetworkService().isOnTrustedNetwork([]);

        expect(result, isFalse);
        expect(permissionCalls, isEmpty);
      },
    );

    test('false when there is no current SSID', () async {
      connectivityResult = ['mobile'];

      final result = await NetworkService().isOnTrustedNetwork(['Home']);

      expect(result, isFalse);
    });

    test('true when the current SSID is in the trusted list', () async {
      connectivityResult = ['wifi'];
      permissionStatus = statusGranted;
      wifiName = '"Home"';

      final result = await NetworkService().isOnTrustedNetwork([
        'Office',
        'Home',
      ]);

      expect(result, isTrue);
    });

    test('false when the current SSID is not in the trusted list', () async {
      connectivityResult = ['wifi'];
      permissionStatus = statusGranted;
      wifiName = '"Coffee Shop"';

      final result = await NetworkService().isOnTrustedNetwork(['Home']);

      expect(result, isFalse);
    });
  });

  group('NetworkService - connectivityStream', () {
    test(
      'forwards and parses events from the platform event channel',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              connectivityEventChannel,
              MockStreamHandler.inline(
                onListen: (arguments, events) {
                  events.success(['wifi', 'vpn']);
                },
              ),
            );

        final results = await NetworkService().connectivityStream.first;

        expect(results, [ConnectivityResult.wifi, ConnectivityResult.vpn]);
      },
    );
  });

  group('NetworkService - wifiSsidStream', () {
    test('re-resolves the SSID whenever connectivity changes', () async {
      connectivityResult = ['wifi'];
      permissionStatus = statusGranted;
      wifiName = '"Streamed Network"';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(
            connectivityEventChannel,
            MockStreamHandler.inline(
              onListen: (arguments, events) {
                events.success(['wifi']);
              },
            ),
          );

      final ssid = await NetworkService().wifiSsidStream.first;

      expect(ssid, 'Streamed Network');
    });
  });
}
