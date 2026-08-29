import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:truehub/models/keychain_server_config.dart';
import 'package:truehub/services/authentication_session_service.dart';
import 'package:truehub/services/secure_storage_service.dart';

/// A fully-controllable fake for [LocalAuthPlatform] so tests can drive
/// [SecureStorageService]'s biometric-authentication branches without
/// touching a real platform channel.
class FakeLocalAuthPlatform extends LocalAuthPlatform {
  bool canCheckBiometrics = true;
  bool deviceSupported = true;
  List<BiometricType> enrolledBiometrics = <BiometricType>[
    BiometricType.fingerprint,
  ];
  bool authenticateResult = true;
  Object? authenticateError;
  Object? canCheckBiometricsError;
  Object? isDeviceSupportedError;
  Object? getEnrolledBiometricsError;

  int authenticateCallCount = 0;

  @override
  Future<bool> deviceSupportsBiometrics() async {
    if (canCheckBiometricsError != null) {
      throw canCheckBiometricsError!;
    }
    return canCheckBiometrics;
  }

  @override
  Future<bool> isDeviceSupported() async {
    if (isDeviceSupportedError != null) {
      throw isDeviceSupportedError!;
    }
    return deviceSupported;
  }

  @override
  Future<List<BiometricType>> getEnrolledBiometrics() async {
    if (getEnrolledBiometricsError != null) {
      throw getEnrolledBiometricsError!;
    }
    return enrolledBiometrics;
  }

  @override
  Future<bool> authenticate({
    required String localizedReason,
    required Iterable<AuthMessages> authMessages,
    AuthenticationOptions options = const AuthenticationOptions(),
  }) async {
    authenticateCallCount++;
    if (authenticateError != null) {
      throw authenticateError!;
    }
    return authenticateResult;
  }
}

void main() {
  late FakeLocalAuthPlatform fakeLocalAuth;
  late Map<String, String> storageData;

  setUp(() {
    // In-memory fake shipped by flutter_secure_storage itself for exactly
    // this purpose - it backs the package's platform-interface singleton,
    // so it transparently backs SecureStorageService's static `_storage`.
    storageData = <String, String>{};
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      storageData,
    );

    fakeLocalAuth = FakeLocalAuthPlatform();
    LocalAuthPlatform.instance = fakeLocalAuth;

    AuthenticationSessionService.instance.invalidateSession();
  });

  tearDown(() {
    AuthenticationSessionService.instance.invalidateSession();
  });

  group('isBiometricAvailable', () {
    test('returns true when biometrics are supported and available', () async {
      fakeLocalAuth.canCheckBiometrics = true;
      fakeLocalAuth.deviceSupported = true;

      final result = await SecureStorageService.isBiometricAvailable();

      expect(result, isTrue);
    });

    test('returns false when canCheckBiometrics is false', () async {
      fakeLocalAuth.canCheckBiometrics = false;
      fakeLocalAuth.deviceSupported = true;

      final result = await SecureStorageService.isBiometricAvailable();

      expect(result, isFalse);
    });

    test('returns false when isDeviceSupported is false', () async {
      fakeLocalAuth.canCheckBiometrics = true;
      fakeLocalAuth.deviceSupported = false;

      final result = await SecureStorageService.isBiometricAvailable();

      expect(result, isFalse);
    });

    test('returns false when the platform throws', () async {
      fakeLocalAuth.canCheckBiometricsError = Exception('boom');

      final result = await SecureStorageService.isBiometricAvailable();

      expect(result, isFalse);
    });
  });

  group('getAvailableBiometrics', () {
    test('returns the biometrics reported by the platform', () async {
      fakeLocalAuth.enrolledBiometrics = <BiometricType>[
        BiometricType.face,
        BiometricType.fingerprint,
      ];

      final result = await SecureStorageService.getAvailableBiometrics();

      expect(result, [BiometricType.face, BiometricType.fingerprint]);
    });

    test('returns an empty list when the platform throws', () async {
      fakeLocalAuth.getEnrolledBiometricsError = Exception('boom');

      final result = await SecureStorageService.getAvailableBiometrics();

      expect(result, isEmpty);
    });
  });

  group('authenticate', () {
    test(
      'short-circuits and extends the session when it is already valid',
      () async {
        AuthenticationSessionService.instance.markAuthenticated();

        final result = await SecureStorageService.authenticate(reason: 'test');

        expect(result, isTrue);
        // Should not have touched the platform at all.
        expect(fakeLocalAuth.authenticateCallCount, 0);
      },
    );

    test(
      'allows access without biometrics when unavailable and not required',
      () async {
        fakeLocalAuth.canCheckBiometrics = false;

        final result = await SecureStorageService.authenticate(
          reason: 'test',
          biometricOnly: false,
        );

        expect(result, isTrue);
        expect(AuthenticationSessionService.instance.isSessionValid, isTrue);
      },
    );

    test(
      'fails when biometrics are unavailable but biometricOnly is true',
      () async {
        fakeLocalAuth.canCheckBiometrics = false;

        final result = await SecureStorageService.authenticate(
          reason: 'test',
          biometricOnly: true,
        );

        expect(result, isFalse);
        expect(AuthenticationSessionService.instance.isSessionValid, isFalse);
      },
    );

    test('marks the session authenticated when the platform authenticates '
        'successfully', () async {
      fakeLocalAuth.canCheckBiometrics = true;
      fakeLocalAuth.deviceSupported = true;
      fakeLocalAuth.authenticateResult = true;

      final result = await SecureStorageService.authenticate(reason: 'test');

      expect(result, isTrue);
      expect(fakeLocalAuth.authenticateCallCount, 1);
      expect(AuthenticationSessionService.instance.isSessionValid, isTrue);
    });

    test(
      'does not mark the session when the platform authentication fails',
      () async {
        fakeLocalAuth.canCheckBiometrics = true;
        fakeLocalAuth.deviceSupported = true;
        fakeLocalAuth.authenticateResult = false;

        final result = await SecureStorageService.authenticate(reason: 'test');

        expect(result, isFalse);
        expect(AuthenticationSessionService.instance.isSessionValid, isFalse);
      },
    );

    test('does not mark the session when useSession is false', () async {
      fakeLocalAuth.canCheckBiometrics = true;
      fakeLocalAuth.deviceSupported = true;
      fakeLocalAuth.authenticateResult = true;

      final result = await SecureStorageService.authenticate(
        reason: 'test',
        useSession: false,
      );

      expect(result, isTrue);
      expect(AuthenticationSessionService.instance.isSessionValid, isFalse);
    });

    test(
      'returns false when the platform throws during authenticate',
      () async {
        fakeLocalAuth.canCheckBiometrics = true;
        fakeLocalAuth.deviceSupported = true;
        fakeLocalAuth.authenticateError = Exception('boom');

        final result = await SecureStorageService.authenticate(reason: 'test');

        expect(result, isFalse);
      },
    );
  });

  group('credential storage', () {
    setUp(() {
      // These tests exercise the storage read/write paths directly and are
      // not concerned with the biometric gate.
      AuthenticationSessionService.instance.markAuthenticated();
    });

    test(
      'storeCredentials then getCredentials round-trips the values',
      () async {
        final stored = await SecureStorageService.storeCredentials(
          serverId: 'server-1',
          username: 'alice',
          password: 'hunter2',
        );
        expect(stored, isTrue);

        final credentials = await SecureStorageService.getCredentials(
          serverId: 'server-1',
        );

        expect(credentials, isNotNull);
        expect(credentials!.username, 'alice');
        expect(credentials.password, 'hunter2');
      },
    );

    test('getCredentials returns null when nothing is stored', () async {
      final credentials = await SecureStorageService.getCredentials(
        serverId: 'missing-server',
      );

      expect(credentials, isNull);
    });

    test('hasCredentials reflects whether both fields are present', () async {
      expect(await SecureStorageService.hasCredentials('server-2'), isFalse);

      await SecureStorageService.storeCredentials(
        serverId: 'server-2',
        username: 'bob',
        password: 'secret',
      );

      expect(await SecureStorageService.hasCredentials('server-2'), isTrue);
    });

    test('deleteCredentials removes stored credentials', () async {
      await SecureStorageService.storeCredentials(
        serverId: 'server-3',
        username: 'carol',
        password: 'pw',
      );
      expect(await SecureStorageService.hasCredentials('server-3'), isTrue);

      final deleted = await SecureStorageService.deleteCredentials(
        serverId: 'server-3',
      );

      expect(deleted, isTrue);
      expect(await SecureStorageService.hasCredentials('server-3'), isFalse);
    });

    test('deleteAllCredentials clears every stored key', () async {
      await SecureStorageService.storeCredentials(
        serverId: 'server-4',
        username: 'dave',
        password: 'pw',
      );

      final deleted = await SecureStorageService.deleteAllCredentials();

      expect(deleted, isTrue);
      expect(storageData, isEmpty);
    });

    test(
      'migrateCredentials stores without requiring authentication',
      () async {
        AuthenticationSessionService.instance.invalidateSession();
        fakeLocalAuth.canCheckBiometrics = false;
        fakeLocalAuth.deviceSupported = false;

        final migrated = await SecureStorageService.migrateCredentials(
          serverId: 'server-5',
          username: 'erin',
          password: 'pw',
        );

        expect(migrated, isTrue);
        final credentials = await SecureStorageService.getCredentials(
          serverId: 'server-5',
          requireAuthentication: false,
        );
        expect(credentials?.username, 'erin');
      },
    );

    test(
      'storeCredentials fails when authentication fails and is required',
      () async {
        AuthenticationSessionService.instance.invalidateSession();
        fakeLocalAuth.canCheckBiometrics = true;
        fakeLocalAuth.deviceSupported = true;
        fakeLocalAuth.authenticateResult = false;

        final stored = await SecureStorageService.storeCredentials(
          serverId: 'server-6',
          username: 'frank',
          password: 'pw',
        );

        expect(stored, isFalse);
        expect(await SecureStorageService.hasCredentials('server-6'), isFalse);
      },
    );

    test('getCredentials returns null when authentication fails and is '
        'required', () async {
      await SecureStorageService.storeCredentials(
        serverId: 'server-7',
        username: 'grace',
        password: 'pw',
      );

      AuthenticationSessionService.instance.invalidateSession();
      fakeLocalAuth.canCheckBiometrics = true;
      fakeLocalAuth.deviceSupported = true;
      fakeLocalAuth.authenticateResult = false;

      final credentials = await SecureStorageService.getCredentials(
        serverId: 'server-7',
      );

      expect(credentials, isNull);
    });

    test('deleteCredentials returns false when authentication fails and is '
        'required', () async {
      AuthenticationSessionService.instance.invalidateSession();
      fakeLocalAuth.canCheckBiometrics = true;
      fakeLocalAuth.deviceSupported = true;
      fakeLocalAuth.authenticateResult = false;

      final deleted = await SecureStorageService.deleteCredentials(
        serverId: 'server-8',
      );

      expect(deleted, isFalse);
    });

    test('deleteAllCredentials returns false when authentication fails and '
        'is required', () async {
      AuthenticationSessionService.instance.invalidateSession();
      fakeLocalAuth.canCheckBiometrics = true;
      fakeLocalAuth.deviceSupported = true;
      fakeLocalAuth.authenticateResult = false;

      final deleted = await SecureStorageService.deleteAllCredentials();

      expect(deleted, isFalse);
    });
  });

  group('server config storage', () {
    setUp(() {
      AuthenticationSessionService.instance.markAuthenticated();
    });

    const config = KeychainServerConfig(
      id: 'srv-1',
      name: 'My NAS',
      host: 'nas.local',
      port: 443,
      useHttps: true,
      allowUntrustedCertificates: false,
      username: 'admin',
      password: 'p@ss',
    );

    test('storeServerConfig then getServerConfig round-trips', () async {
      final stored = await SecureStorageService.storeServerConfig(
        config: config,
      );
      expect(stored, isTrue);

      final fetched = await SecureStorageService.getServerConfig(
        serverId: 'srv-1',
      );

      expect(fetched, isNotNull);
      expect(fetched!.id, config.id);
      expect(fetched.name, config.name);
      expect(fetched.host, config.host);
      expect(fetched.username, config.username);
      expect(fetched.password, config.password);
    });

    test('storeServerConfig also updates the server list', () async {
      await SecureStorageService.storeServerConfig(config: config);

      final list = await SecureStorageService.getServerList();

      expect(list, contains('srv-1'));
    });

    test(
      'storeServerConfig does not duplicate an existing server id',
      () async {
        await SecureStorageService.storeServerConfig(config: config);
        await SecureStorageService.storeServerConfig(config: config);

        final list = await SecureStorageService.getServerList();

        expect(list.where((id) => id == 'srv-1').length, 1);
      },
    );

    test('hasServerConfig reflects presence of a config', () async {
      expect(await SecureStorageService.hasServerConfig('srv-1'), isFalse);

      await SecureStorageService.storeServerConfig(config: config);

      expect(await SecureStorageService.hasServerConfig('srv-1'), isTrue);
    });

    test(
      'deleteServerConfig removes the config and the server-list entry',
      () async {
        await SecureStorageService.storeServerConfig(config: config);

        final deleted = await SecureStorageService.deleteServerConfig(
          serverId: 'srv-1',
        );

        expect(deleted, isTrue);
        expect(await SecureStorageService.hasServerConfig('srv-1'), isFalse);
        expect(
          await SecureStorageService.getServerList(),
          isNot(contains('srv-1')),
        );
      },
    );

    test('getServerConfig returns null when nothing is stored', () async {
      final fetched = await SecureStorageService.getServerConfig(
        serverId: 'does-not-exist',
      );

      expect(fetched, isNull);
    });
  });

  group('getServerList', () {
    test('returns an empty list when nothing has been stored', () async {
      final list = await SecureStorageService.getServerList();

      expect(list, isEmpty);
    });

    test('returns an empty list when the stored JSON is malformed', () async {
      storageData['server_list'] = 'not valid json';

      final list = await SecureStorageService.getServerList();

      expect(list, isEmpty);
    });
  });

  group('debugListStoredKeys', () {
    test('completes without throwing', () async {
      await expectLater(SecureStorageService.debugListStoredKeys(), completes);
    });
  });
}
