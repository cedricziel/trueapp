import 'dart:math';

/// Exponential backoff with jitter and a cap.
class RetryPolicy {
  RetryPolicy({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 4),
    this.jitter = 0.25,
    Random? random,
  }) : _random = random ?? Random();

  /// Total tries, the first one included.
  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;

  /// Fraction by which each delay may deviate up or down, so clients that
  /// lost their connection together do not all retry in lockstep.
  final double jitter;

  final Random _random;

  /// How long to wait before retry number [retry] (1 for the first retry).
  Duration delayBeforeRetry(int retry) {
    final exponential = baseDelay.inMicroseconds * pow(2, retry - 1);
    final spread = 1 + jitter * (2 * _random.nextDouble() - 1);
    final micros = min(
      exponential * spread,
      maxDelay.inMicroseconds.toDouble(),
    );
    return Duration(microseconds: micros.round());
  }
}

/// Runs [operation], retrying with [policy]'s backoff while it throws an
/// error [isRetryable] accepts. The last error is rethrown once the attempts
/// are used up. [wait] is injectable so tests need no real clock.
Future<T> retryWithBackoff<T>(
  Future<T> Function() operation, {
  required RetryPolicy policy,
  required bool Function(Object error) isRetryable,
  Future<void> Function(Duration delay)? wait,
  void Function(int retry, Duration delay, Object error)? onRetry,
}) async {
  for (var attempt = 1; ; attempt++) {
    try {
      return await operation();
    } catch (error) {
      if (attempt >= policy.maxAttempts || !isRetryable(error)) rethrow;
      final delay = policy.delayBeforeRetry(attempt);
      onRetry?.call(attempt, delay, error);
      await (wait == null ? Future<void>.delayed(delay) : wait(delay));
    }
  }
}
