import 'dart:async';

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_retry/jetleaf_retry.dart';
import 'package:jetleaf_core/lang.dart';
import 'package:test/test.dart';

class _NetworkCall implements RetryCallback<String> {
  @override
  @override
  void setApplicationEventBus(ApplicationEventBus? applicationEventBus) {}

  int attempts = 0;
  final int failUntilAttempt;

  _NetworkCall({this.failUntilAttempt = 3});

  @override
  FutureOr<String> execute(RetryContext context) {
    attempts++;
    if (attempts < failUntilAttempt) {
      throw TimeoutException('transient network timeout on attempt $attempts');
    }
    return 'delivered-after-$attempts-attempts';
  }
}

class _Fallback implements RecoveryCallback<String> {
  @override
  FutureOr<String> recover(RetryContext context) {
    return 'queued-for-replay';
  }
}

void main() {
  group('RetryExecutor', () {
    test('retries until successful with fixed backoff', () async {
      final backoff = FixedBackoffPolicy();
      backoff.backoff(const Backoff(delay: 5));

      final retryPolicy = SimpleRetryPolicy()
        ..retryable(const Retryable(
            maxAttempts: 5,
            backoff: Backoff(delay: 5, multiplier: 1.0),
            retryFor: [ClassType<TimeoutException>()],
          ));
      final executor = DefaultRetryExecutor()
        ..withRetryPolicy(retryPolicy)
        ..withBackoffPolicy(backoff)
        ..withStatistics(InMemoryStatistics());

      final call = _NetworkCall(failUntilAttempt: 3);
      final result = await executor.execute<String>(
        call,
        _Fallback(),
        SimpleRetryContext(),
      );

      expect(result, 'delivered-after-3-attempts');
      expect(call.attempts, 3);
    });

    test('routes to fallback when all retries are exhausted', () async {
      final backoff = FixedBackoffPolicy();
      backoff.backoff(const Backoff(delay: 1));

      final retryPolicy = SimpleRetryPolicy()
        ..retryable(const Retryable(
            maxAttempts: 5,
            backoff: Backoff(delay: 5, multiplier: 1.0),
            retryFor: [ClassType<TimeoutException>()],
          ));
      final executor = DefaultRetryExecutor()
        ..withRetryPolicy(retryPolicy)
        ..withBackoffPolicy(backoff)
        ..withStatistics(InMemoryStatistics());

      final call = _NetworkCall(failUntilAttempt: 99);
      final result = await executor.execute<String>(
        call,
        _Fallback(),
        SimpleRetryContext(),
      );

      expect(result, 'queued-for-replay');
    });

    test('tracks statistics across retries', () async {
      final stats = InMemoryStatistics();
      final backoff = FixedBackoffPolicy();
      backoff.backoff(const Backoff(delay: 1));

      final retryPolicy = SimpleRetryPolicy()
        ..retryable(const Retryable(
            maxAttempts: 5,
            backoff: Backoff(delay: 5, multiplier: 1.0),
            retryFor: [ClassType<TimeoutException>()],
          ));
      final executor = DefaultRetryExecutor()
        ..withRetryPolicy(retryPolicy)
        ..withBackoffPolicy(backoff)
        ..withStatistics(stats);

      final call = _NetworkCall(failUntilAttempt: 2);
      final result = await executor.execute<String>(
        call,
        _Fallback(),
        SimpleRetryContext(),
      );

      expect(result, 'delivered-after-2-attempts');
      expect(stats.getStartedCount(), greaterThanOrEqualTo(1));
      expect(stats.getSuccessCount(), greaterThanOrEqualTo(1));
    });
  });
}
