import 'dart:async';
import 'package:flutter/foundation.dart';

/// Manages authentication session state for the app
class AuthenticationSessionService {
  static AuthenticationSessionService? _instance;
  static AuthenticationSessionService get instance {
    _instance ??= AuthenticationSessionService._();
    return _instance!;
  }

  AuthenticationSessionService._();

  bool _isAuthenticated = false;
  DateTime? _authenticatedAt;
  Timer? _sessionTimer;

  // Session duration - default 30 minutes
  static const Duration sessionDuration = Duration(minutes: 30);

  /// Check if the current session is valid
  bool get isSessionValid {
    if (!_isAuthenticated || _authenticatedAt == null) {
      return false;
    }

    final now = DateTime.now();
    final elapsed = now.difference(_authenticatedAt!);

    if (elapsed > sessionDuration) {
      if (kDebugMode) {
        print(
          'AuthenticationSessionService: Session expired (elapsed: ${elapsed.inMinutes} minutes)',
        );
      }
      invalidateSession();
      return false;
    }

    return true;
  }

  /// Mark the session as authenticated
  void markAuthenticated() {
    _isAuthenticated = true;
    _authenticatedAt = DateTime.now();

    // Cancel any existing timer
    _sessionTimer?.cancel();

    // Set up a timer to invalidate the session after the duration
    _sessionTimer = Timer(sessionDuration, () {
      if (kDebugMode) {
        print('AuthenticationSessionService: Session expired due to timeout');
      }
      invalidateSession();
    });

    if (kDebugMode) {
      print(
        'AuthenticationSessionService: Session authenticated at $_authenticatedAt',
      );
    }
  }

  /// Extend the current session
  void extendSession() {
    if (_isAuthenticated) {
      markAuthenticated(); // This will reset the timer
      if (kDebugMode) {
        print('AuthenticationSessionService: Session extended');
      }
    }
  }

  /// Invalidate the current session
  void invalidateSession() {
    _isAuthenticated = false;
    _authenticatedAt = null;
    _sessionTimer?.cancel();
    _sessionTimer = null;

    if (kDebugMode) {
      print('AuthenticationSessionService: Session invalidated');
    }
  }

  /// Get remaining session time
  Duration? get remainingSessionTime {
    if (!isSessionValid || _authenticatedAt == null) {
      return null;
    }

    final elapsed = DateTime.now().difference(_authenticatedAt!);
    final remaining = sessionDuration - elapsed;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  void dispose() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }
}
