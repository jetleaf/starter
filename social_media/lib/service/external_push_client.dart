/// Outbound push-notification gateway with declarative retry + recovery.
///
/// The `@Retryable` method is intercepted at runtime by Jetleaf's AOP proxy
/// (`$$JLInterfaced$$ExternalPushClient`) — the pod injected everywhere is the
/// proxy, and the proxy routes invocations through the method-interceptor
/// pipeline where `AnnotationAwareRetryFactory` (registered as
/// `jetleaf.retry.retryFactory` by `RetryAutoConfiguration`) applies the
/// retry policy from the annotation. `@Recover` provides the fallback when
/// retries are exhausted.
library;

import 'dart:math';

import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_retry/jetleaf_retry.dart';

final class PushDeliveryReceipt {
  const PushDeliveryReceipt({required this.delivered, required this.detail});

  final bool delivered;
  final String detail;

  Map<String, dynamic> toJson() => {'delivered': delivered, 'detail': detail};
}

final class PushTransportException implements Exception {
  const PushTransportException(this.message);
  final String message;

  @override
  String toString() => 'PushTransportException: $message';
}

@Service()
class ExternalPushClient {
  ExternalPushClient();

  static final Log _logger = LogFactory.getLog(ExternalPushClient);

  final Random _random = Random(42);

  /// Total delivery attempts since boot (one per `@Retryable` invocation
  /// including retries — i.e. 3 here when the gateway keeps faulting).
  int dispatchCount = 0;

  /// Delivers a push to the device represented by [deviceToken].
  ///
  /// Faults ~60% of the time with a transient transport error; the
  /// annotation-driven retry pipeline re-invokes this method through the
  /// execution policy declared below. Verified end-to-end — each call from
  /// [PushNotificationEventListener] may fan out to multiple attempts.
  @Retryable(
    maxAttempts: 3,
    backoff: Backoff(delay: 25, multiplier: 1.0),
    retryFor: [ClassType<PushTransportException>()],
  )
  Future<PushDeliveryReceipt> send(String deviceToken, String title, String body) async {
    dispatchCount++;
    final roll = _random.nextDouble();
    _logger.info('PUSH-ATTEMPT #$dispatchCount roll=${roll.toStringAsFixed(4)} token=$deviceToken');
    if (roll < 0.6) {
      throw PushTransportException('simulated transient transport failure (roll=$roll)');
    }
    return PushDeliveryReceipt(
      delivered: true,
      detail: 'push accepted by gateway for token=$deviceToken',
    );
  }

  /// Recover callback invoked when all retry attempts are exhausted.
  /// Same return type as the retryable method; exception is first argument,
  /// followed by the original method parameters.
  @Recover()
  Future<PushDeliveryReceipt> recoverSend(PushTransportException exception, String deviceToken, String title, String body) async {
    return PushDeliveryReceipt(
      delivered: false,
      detail: 'push dropped after 3 attempts for token=$deviceToken (${exception.message})',
    );
  }
}
