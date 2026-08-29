import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/connection_error.dart';

void main() {
  group('ConnectionError direct construction', () {
    test('applies default isRetryable and allows null technicalDetails', () {
      const error = ConnectionError(
        type: ConnectionErrorType.unknown,
        message: 'Something went wrong',
      );
      expect(error.isRetryable, isTrue);
      expect(error.technicalDetails, isNull);
    });

    test('honors explicit fields', () {
      const error = ConnectionError(
        type: ConnectionErrorType.serverError,
        message: 'msg',
        technicalDetails: 'details',
        isRetryable: false,
      );
      expect(error.type, equals(ConnectionErrorType.serverError));
      expect(error.message, equals('msg'));
      expect(error.technicalDetails, equals('details'));
      expect(error.isRetryable, isFalse);
    });
  });

  group('ConnectionError named factories', () {
    test('networkUnreachable sets type, message and is retryable', () {
      final error = ConnectionError.networkUnreachable(details: 'timeout');
      expect(error.type, equals(ConnectionErrorType.networkUnreachable));
      expect(error.message, equals('Server not reachable'));
      expect(error.technicalDetails, equals('timeout'));
      expect(error.isRetryable, isTrue);
    });

    test('connectionTimeout sets type, message and is retryable', () {
      final error = ConnectionError.connectionTimeout();
      expect(error.type, equals(ConnectionErrorType.connectionTimeout));
      expect(error.message, equals('Connection timed out'));
      expect(error.technicalDetails, isNull);
      expect(error.isRetryable, isTrue);
    });

    test('authenticationFailed sets type, message and is not retryable', () {
      final error = ConnectionError.authenticationFailed(details: 'bad creds');
      expect(error.type, equals(ConnectionErrorType.authenticationFailed));
      expect(error.message, equals('Authentication failed'));
      expect(error.technicalDetails, equals('bad creds'));
      expect(error.isRetryable, isFalse);
    });

    test('invalidCredentials sets type, message and is not retryable', () {
      final error = ConnectionError.invalidCredentials();
      expect(error.type, equals(ConnectionErrorType.invalidCredentials));
      expect(error.message, equals('Invalid username or password'));
      expect(error.isRetryable, isFalse);
    });

    test('serverError sets type, message and is retryable', () {
      final error = ConnectionError.serverError();
      expect(error.type, equals(ConnectionErrorType.serverError));
      expect(error.message, equals('Server error occurred'));
      expect(error.isRetryable, isTrue);
    });

    test('permissionDenied sets type, message and is not retryable', () {
      final error = ConnectionError.permissionDenied();
      expect(error.type, equals(ConnectionErrorType.permissionDenied));
      expect(error.message, equals('Permission denied'));
      expect(error.isRetryable, isFalse);
    });

    test('unknown sets type, message and is retryable', () {
      final error = ConnectionError.unknown(details: 'mystery');
      expect(error.type, equals(ConnectionErrorType.unknown));
      expect(error.message, equals('An unexpected error occurred'));
      expect(error.technicalDetails, equals('mystery'));
      expect(error.isRetryable, isTrue);
    });
  });

  group('ConnectionError.userFriendlyMessage', () {
    test('returns a distinct, non-empty message for every error type', () {
      final messages = <String>{};
      for (final type in ConnectionErrorType.values) {
        final error = ConnectionError(type: type, message: 'x');
        expect(error.userFriendlyMessage, isNotEmpty);
        messages.add(error.userFriendlyMessage);
      }
      expect(messages.length, equals(ConnectionErrorType.values.length));
    });
  });

  group('ConnectionError.shortMessage', () {
    test('returns a distinct, non-empty message for every error type', () {
      final messages = <String>{};
      for (final type in ConnectionErrorType.values) {
        final error = ConnectionError(type: type, message: 'x');
        expect(error.shortMessage, isNotEmpty);
        messages.add(error.shortMessage);
      }
      expect(messages.length, equals(ConnectionErrorType.values.length));
    });

    test('maps each type to its expected short message', () {
      expect(
        const ConnectionError(
          type: ConnectionErrorType.networkUnreachable,
          message: 'x',
        ).shortMessage,
        equals('Server not reachable'),
      );
      expect(
        const ConnectionError(
          type: ConnectionErrorType.connectionTimeout,
          message: 'x',
        ).shortMessage,
        equals('Connection timed out'),
      );
      expect(
        const ConnectionError(
          type: ConnectionErrorType.authenticationFailed,
          message: 'x',
        ).shortMessage,
        equals('Authentication failed'),
      );
      expect(
        const ConnectionError(
          type: ConnectionErrorType.invalidCredentials,
          message: 'x',
        ).shortMessage,
        equals('Invalid credentials'),
      );
      expect(
        const ConnectionError(
          type: ConnectionErrorType.serverError,
          message: 'x',
        ).shortMessage,
        equals('Server error'),
      );
      expect(
        const ConnectionError(
          type: ConnectionErrorType.permissionDenied,
          message: 'x',
        ).shortMessage,
        equals('Permission denied'),
      );
      expect(
        const ConnectionError(
          type: ConnectionErrorType.unknown,
          message: 'x',
        ).shortMessage,
        equals('Connection error'),
      );
    });
  });

  group('ConnectionException', () {
    test('toString delegates to the wrapped error message', () {
      const error = ConnectionError(
        type: ConnectionErrorType.serverError,
        message: 'Server error occurred',
      );
      const exception = ConnectionException(error);

      expect(exception.error, equals(error));
      expect(exception.toString(), equals('Server error occurred'));
    });

    test('is an Exception', () {
      const exception = ConnectionException(
        ConnectionError(type: ConnectionErrorType.unknown, message: 'x'),
      );
      expect(exception, isA<Exception>());
    });
  });
}
