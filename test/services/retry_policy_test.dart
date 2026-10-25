import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/services/retry_policy.dart';

/// Always returns the same fraction, so jitter is predictable.
class _FixedRandom implements Random {
  _FixedRandom(this.value);
  final double value;

  @override
  double nextDouble() => value;

  @override
  bool nextBool() => value >= 0.5;

  @override
  int nextInt(int max) => (value * max).floor();
}

void main() {
  group('RetryPolicy.delayBeforeRetry', () {
    test('doubles each retry from the base delay', () {
      final policy = RetryPolicy(jitter: 0, random: _FixedRandom(0.5));

      expect(policy.delayBeforeRetry(1), const Duration(seconds: 1));
      expect(policy.delayBeforeRetry(2), const Duration(seconds: 2));
      expect(policy.delayBeforeRetry(3), const Duration(seconds: 4));
    });

    test('never exceeds the cap, jitter included', () {
      final policy = RetryPolicy(
        maxDelay: const Duration(seconds: 3),
        random: _FixedRandom(1),
      );

      expect(policy.delayBeforeRetry(5), const Duration(seconds: 3));
    });

    test('spreads the delay by the jitter fraction in both directions', () {
      expect(
        RetryPolicy(jitter: 0.25, random: _FixedRandom(0)).delayBeforeRetry(1),
        const Duration(milliseconds: 750),
      );
      expect(
        RetryPolicy(jitter: 0.25, random: _FixedRandom(1)).delayBeforeRetry(1),
        const Duration(milliseconds: 1250),
      );
    });
  });

  group('retryWithBackoff', () {
    late List<Duration> waits;
    late RetryPolicy policy;

    Future<void> recordWait(Duration d) async => waits.add(d);

    setUp(() {
      waits = [];
      policy = RetryPolicy(jitter: 0, random: _FixedRandom(0.5));
    });

    test('returns without waiting when the first attempt succeeds', () async {
      var attempts = 0;

      await retryWithBackoff<void>(
        () async => attempts++,
        policy: policy,
        isRetryable: (_) => true,
        wait: recordWait,
      );

      expect(attempts, 1);
      expect(waits, isEmpty);
    });

    test('retries a retryable failure with growing delays until it '
        'succeeds', () async {
      var attempts = 0;

      final result = await retryWithBackoff<String>(
        () async {
          if (++attempts < 3) throw StateError('flaky');
          return 'ok';
        },
        policy: policy,
        isRetryable: (_) => true,
        wait: recordWait,
      );

      expect(result, 'ok');
      expect(attempts, 3);
      expect(waits, [const Duration(seconds: 1), const Duration(seconds: 2)]);
    });

    test('gives up after maxAttempts and rethrows the last error', () async {
      var attempts = 0;

      await expectLater(
        retryWithBackoff<void>(
          () async => throw StateError('attempt ${++attempts}'),
          policy: policy,
          isRetryable: (_) => true,
          wait: recordWait,
        ),
        throwsA(
          isA<StateError>().having((e) => e.message, 'message', 'attempt 3'),
        ),
      );

      expect(attempts, policy.maxAttempts);
      expect(waits, hasLength(policy.maxAttempts - 1));
    });

    test('does not retry a non-retryable failure', () async {
      var attempts = 0;

      await expectLater(
        retryWithBackoff<void>(
          () async {
            attempts++;
            throw StateError('bad credentials');
          },
          policy: policy,
          isRetryable: (_) => false,
          wait: recordWait,
        ),
        throwsStateError,
      );

      expect(attempts, 1);
      expect(waits, isEmpty);
    });

    test('reports each retry to onRetry', () async {
      final seen = <int>[];

      await expectLater(
        retryWithBackoff<void>(
          () async => throw StateError('x'),
          policy: policy,
          isRetryable: (_) => true,
          wait: recordWait,
          onRetry: (attempt, delay, error) => seen.add(attempt),
        ),
        throwsStateError,
      );

      expect(seen, [1, 2]);
    });
  });
}
