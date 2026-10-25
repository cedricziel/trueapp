import 'dart:async';
import 'dart:io';

import 'package:flutter_otel/flutter_otel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:truehub/models/connection_error.dart';
import 'package:truehub/services/error_diagnostics.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  group('errorTypeOf', () {
    test('classifies a timeout', () {
      expect(errorTypeOf(TimeoutException('x')), 'timeout');
    });

    test('classifies socket failures by their OS message', () {
      expect(
        errorTypeOf(
          const SocketException(
            'Connection failed',
            osError: OSError('Connection refused', 61),
          ),
        ),
        'connection_refused',
      );
      expect(
        errorTypeOf(
          const SocketException(
            'Failed host lookup: nas.local',
            osError: OSError('nodename nor servname provided', 8),
          ),
        ),
        'dns',
      );
      expect(
        errorTypeOf(
          const SocketException(
            'Connection failed',
            osError: OSError('Network is unreachable', 101),
          ),
        ),
        'network_unreachable',
      );
      expect(errorTypeOf(const SocketException('boom')), 'socket_error');
    });

    test('classifies TLS failures', () {
      expect(errorTypeOf(const HandshakeException('bad cert')), 'tls');
    });

    test('looks through a WebSocketChannelException to its inner cause', () {
      expect(
        errorTypeOf(
          WebSocketChannelException.from(
            const SocketException(
              'x',
              osError: OSError('Connection refused', 111),
            ),
          ),
        ),
        'connection_refused',
      );
    });

    test('classifies a failed websocket upgrade', () {
      expect(
        errorTypeOf(
          const WebSocketException(
            "Connection to 'http://nas:80/api/current' was not upgraded to "
            'websocket',
          ),
        ),
        'websocket_upgrade_failed',
      );
    });

    test(
      'maps auth and permission rejections from the ConnectionError type',
      () {
        expect(
          errorTypeOf(
            ConnectionException(ConnectionError.invalidCredentials()),
          ),
          'auth_rejected',
        );
        expect(
          errorTypeOf(
            ConnectionException(ConnectionError.authenticationFailed()),
          ),
          'auth_rejected',
        );
        expect(
          errorTypeOf(ConnectionException(ConnectionError.permissionDenied())),
          'permission_denied',
        );
      },
    );

    test('looks through a ConnectionException to its cause', () {
      expect(
        errorTypeOf(
          ConnectionException(
            ConnectionError.connectionTimeout(cause: TimeoutException('x')),
          ),
        ),
        'timeout',
      );
    });

    test('classifies a JSON-RPC error from the middleware', () {
      expect(
        errorTypeOf(RpcException(-32000, 'Method call error')),
        'rpc_error',
      );
    });

    test('falls back to the runtime type', () {
      expect(errorTypeOf(StateError('x')), 'StateError');
      expect(
        errorTypeOf(ConnectionException(ConnectionError.unknown())),
        'unknown',
      );
    });
  });

  group('describeError', () {
    test('includes the cause behind a ConnectionException', () {
      final error = ConnectionException(
        ConnectionError.networkUnreachable(
          cause: const SocketException('refused'),
        ),
      );

      expect(
        describeError(error),
        'Server not reachable: SocketException: refused',
      );
    });

    test('falls back to technical details, then to the message', () {
      expect(
        describeError(
          ConnectionException(ConnectionError.serverError(details: 'EINVAL')),
        ),
        'Server error occurred: EINVAL',
      );
      expect(
        describeError(ConnectionException(ConnectionError.serverError())),
        'Server error occurred',
      );
    });

    test('passes other errors through', () {
      expect(describeError(StateError('x')), 'Bad state: x');
    });
  });

  group('rootCauseOf', () {
    test('unwraps a ConnectionException that carries a cause', () {
      const cause = SocketException('x');
      final error = ConnectionException(
        ConnectionError.networkUnreachable(cause: cause),
      );
      expect(rootCauseOf(error), same(cause));
    });

    test('keeps everything else as is', () {
      final plain = StateError('x');
      expect(rootCauseOf(plain), same(plain));
      final bare = ConnectionException(ConnectionError.serverError());
      expect(rootCauseOf(bare), same(bare));
    });
  });

  group('endpointAttributes', () {
    test('reports host and port only', () {
      expect(
        endpointAttributes('https://admin:secret@nas.local:8443/ui?key=abc'),
        {'server.address': 'nas.local', 'server.port': 8443},
      );
    });

    test('derives the default port from the scheme', () {
      expect(endpointAttributes('http://10.0.0.5'), {
        'server.address': '10.0.0.5',
        'server.port': 80,
      });
      expect(endpointAttributes('https://nas.example.com')['server.port'], 443);
    });

    test('is empty for a missing or unparsable url', () {
      expect(endpointAttributes(null), isEmpty);
      expect(endpointAttributes('::not a url'), isEmpty);
    });
  });

  group('DiagnosticLogger.errorWithCause', () {
    test('puts the cause in the body and the classification in attributes', () {
      final logger = _RecordingLogger();

      logger.errorWithCause(
        'Subscription error',
        ConnectionException(
          ConnectionError.networkUnreachable(
            cause: const SocketException(
              'Connection failed',
              osError: OSError('Connection refused', 61),
            ),
          ),
        ),
        attributes: {'server.id': 's1'},
      );

      final record = logger.records.single;
      expect(record.body, contains('Subscription error: Server not reachable'));
      expect(record.body, contains('SocketException'));
      expect(record.attributes['error.type'], 'connection_refused');
      expect(record.attributes['exception.type'], 'SocketException');
      expect(record.attributes['server.id'], 's1');
    });
  });
}

class _RecordingLogger extends Logger {
  final List<LogRecord> records = [];

  @override
  void emit(LogRecord record) => records.add(record);
}
