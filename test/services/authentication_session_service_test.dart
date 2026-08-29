import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/services/authentication_session_service.dart';

void main() {
  // AuthenticationSessionService is a process-wide singleton (static
  // `instance` getter), so every test explicitly resets its state via
  // invalidateSession()/dispose() rather than relying on a fresh instance.
  final service = AuthenticationSessionService.instance;

  setUp(() {
    service.invalidateSession();
  });

  tearDown(() {
    service.invalidateSession();
  });

  group('AuthenticationSessionService', () {
    test('instance returns the same singleton across accesses', () {
      expect(
        AuthenticationSessionService.instance,
        same(AuthenticationSessionService.instance),
      );
    });

    test('isSessionValid is false before any authentication', () {
      expect(service.isSessionValid, isFalse);
    });

    test('markAuthenticated makes the session valid', () {
      service.markAuthenticated();

      expect(service.isSessionValid, isTrue);
    });

    test('invalidateSession makes a previously valid session invalid', () {
      service.markAuthenticated();
      expect(service.isSessionValid, isTrue);

      service.invalidateSession();

      expect(service.isSessionValid, isFalse);
    });

    test(
      'invalidateSession is safe to call when nothing was authenticated',
      () {
        expect(() => service.invalidateSession(), returnsNormally);
        expect(service.isSessionValid, isFalse);
      },
    );

    test('extendSession keeps an authenticated session valid', () {
      service.markAuthenticated();

      service.extendSession();

      expect(service.isSessionValid, isTrue);
    });

    test('extendSession is a no-op when not authenticated', () {
      expect(service.isSessionValid, isFalse);

      service.extendSession();

      expect(service.isSessionValid, isFalse);
    });

    test('markAuthenticated can be called repeatedly and stays valid', () {
      service.markAuthenticated();
      service.markAuthenticated();
      service.markAuthenticated();

      expect(service.isSessionValid, isTrue);
    });

    test('remainingSessionTime is null when session is invalid', () {
      expect(service.remainingSessionTime, isNull);
    });

    test('remainingSessionTime is close to the full session duration '
        'right after authenticating', () {
      service.markAuthenticated();

      final remaining = service.remainingSessionTime;

      expect(remaining, isNotNull);
      expect(
        remaining!.inSeconds,
        closeTo(AuthenticationSessionService.sessionDuration.inSeconds, 5),
      );
    });

    test('remainingSessionTime is null after invalidating', () {
      service.markAuthenticated();
      service.invalidateSession();

      expect(service.remainingSessionTime, isNull);
    });

    test('sessionDuration defaults to 30 minutes', () {
      expect(
        AuthenticationSessionService.sessionDuration,
        const Duration(minutes: 30),
      );
    });

    test('dispose cancels the pending timer without throwing', () {
      service.markAuthenticated();

      expect(() => service.dispose(), returnsNormally);
    });

    test('dispose is safe to call when no session is active', () {
      expect(() => service.dispose(), returnsNormally);
    });

    test('markAuthenticated after dispose re-establishes a valid session', () {
      service.markAuthenticated();
      service.dispose();

      // dispose() cancels the timer but does not clear the
      // authenticated flag/timestamp, so the session is still valid
      // until it is explicitly invalidated or naturally expires.
      expect(service.isSessionValid, isTrue);

      service.markAuthenticated();

      expect(service.isSessionValid, isTrue);
    });
  });
}
