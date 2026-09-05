enum ConnectionErrorType {
  networkUnreachable,
  connectionTimeout,
  authenticationFailed,
  invalidCredentials,
  serverError,
  permissionDenied,
  invalidResponse,
  unknown,
}

class ConnectionError {
  final ConnectionErrorType type;
  final String message;
  final String? technicalDetails;
  final bool isRetryable;

  const ConnectionError({
    required this.type,
    required this.message,
    this.technicalDetails,
    this.isRetryable = true,
  });

  factory ConnectionError.networkUnreachable({String? details}) {
    return ConnectionError(
      type: ConnectionErrorType.networkUnreachable,
      message: 'Server not reachable',
      technicalDetails: details,
      isRetryable: true,
    );
  }

  factory ConnectionError.connectionTimeout({String? details}) {
    return ConnectionError(
      type: ConnectionErrorType.connectionTimeout,
      message: 'Connection timed out',
      technicalDetails: details,
      isRetryable: true,
    );
  }

  factory ConnectionError.authenticationFailed({String? details}) {
    return ConnectionError(
      type: ConnectionErrorType.authenticationFailed,
      message: 'Authentication failed',
      technicalDetails: details,
      isRetryable: false,
    );
  }

  factory ConnectionError.invalidCredentials({String? details}) {
    return ConnectionError(
      type: ConnectionErrorType.invalidCredentials,
      message: 'Invalid username or password',
      technicalDetails: details,
      isRetryable: false,
    );
  }

  factory ConnectionError.serverError({String? details}) {
    return ConnectionError(
      type: ConnectionErrorType.serverError,
      message: 'Server error occurred',
      technicalDetails: details,
      isRetryable: true,
    );
  }

  factory ConnectionError.permissionDenied({String? details}) {
    return ConnectionError(
      type: ConnectionErrorType.permissionDenied,
      message: 'Permission denied',
      technicalDetails: details,
      isRetryable: false,
    );
  }

  /// The server answered, but with data this app could not read - a
  /// response-shape mismatch between TrueNAS versions, or a parsing bug on
  /// our side. Distinct from [ConnectionError.unknown] so it never shows up
  /// as a generic "Connection error" that hides the actual cause.
  factory ConnectionError.invalidResponse({String? details}) {
    return ConnectionError(
      type: ConnectionErrorType.invalidResponse,
      message: 'Unexpected response from server',
      technicalDetails: details,
      isRetryable: true,
    );
  }

  factory ConnectionError.unknown({String? details}) {
    return ConnectionError(
      type: ConnectionErrorType.unknown,
      message: 'An unexpected error occurred',
      technicalDetails: details,
      isRetryable: true,
    );
  }

  String get userFriendlyMessage {
    switch (type) {
      case ConnectionErrorType.networkUnreachable:
        return 'Cannot reach the server. Please check:\n'
            '• Server IP address or hostname\n'
            '• Network connection\n'
            '• Server is powered on';
      case ConnectionErrorType.connectionTimeout:
        return 'Connection timed out. Please check:\n'
            '• Server is responding\n'
            '• Network connectivity\n'
            '• Firewall settings';
      case ConnectionErrorType.authenticationFailed:
        return 'Could not authenticate with the server. Please check:\n'
            '• Username and password\n'
            '• User account is active\n'
            '• User has necessary permissions';
      case ConnectionErrorType.invalidCredentials:
        return 'Username or password is incorrect. Please:\n'
            '• Check your credentials\n'
            '• Ensure caps lock is off\n'
            '• Verify account is not locked';
      case ConnectionErrorType.serverError:
        return 'The server encountered an error. Please:\n'
            '• Try again in a moment\n'
            '• Check server logs\n'
            '• Contact your administrator';
      case ConnectionErrorType.permissionDenied:
        return 'Access denied. Please check:\n'
            '• User account permissions\n'
            '• Account is active\n'
            '• Required roles are assigned';
      case ConnectionErrorType.invalidResponse:
        return 'The server sent data this app could not read. Please:\n'
            '• Update TrueNAS Manager to the latest version\n'
            '• Check the TrueNAS version is supported\n'
            '• Report the issue with the technical details';
      case ConnectionErrorType.unknown:
        return 'An unexpected error occurred. Please:\n'
            '• Try again\n'
            '• Check server status\n'
            '• Contact support if issue persists';
    }
  }

  String get shortMessage {
    switch (type) {
      case ConnectionErrorType.networkUnreachable:
        return 'Server not reachable';
      case ConnectionErrorType.connectionTimeout:
        return 'Connection timed out';
      case ConnectionErrorType.authenticationFailed:
        return 'Authentication failed';
      case ConnectionErrorType.invalidCredentials:
        return 'Invalid credentials';
      case ConnectionErrorType.serverError:
        return 'Server error';
      case ConnectionErrorType.permissionDenied:
        return 'Permission denied';
      case ConnectionErrorType.invalidResponse:
        return 'Unexpected server response';
      case ConnectionErrorType.unknown:
        return 'Connection error';
    }
  }
}

class ConnectionException implements Exception {
  final ConnectionError error;

  const ConnectionException(this.error);

  @override
  String toString() => error.message;
}
