import 'dart:async';

import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_retry/jetleaf_retry.dart';

import '../models/webhook_event.dart';
import 'dead_letter_service.dart';
import 'idempotency_service.dart';

/// Result returned by the webhook dispatch pipeline.
final class DispatchResult {
  final String deliveryId;
  final bool delivered;
  final int attempts;
  final String? failureReason;

  const DispatchResult({
    required this.deliveryId,
    required this.delivered,
    required this.attempts,
    this.failureReason,
  });

  Map<String, dynamic> toJson() => {
        'deliveryId': deliveryId,
        'delivered': delivered,
        'attempts': attempts,
        if (failureReason != null) 'failureReason': failureReason,
      };
}

/// Delivers outgoing webhook events with declarative retries and fallback routing.
///
/// Deliberately keeps the "HTTP client" injectable so tests can emulate both
/// intermittent failures and permanent ones without network access.
@Service()
class WebhookDeliveryService {
  final IdempotencyService _idempotency;
  final DeadLetterService _deadLetter;
  int transientFailuresBeforeSuccess;
  bool permanentFailure;
  int sendAttempts;

  WebhookDeliveryService({
    IdempotencyService? idempotency,
    DeadLetterService? deadLetter,
    this.transientFailuresBeforeSuccess = 0,
    this.permanentFailure = false,
  })  : _idempotency = idempotency ?? IdempotencyService(),
        _deadLetter = deadLetter ?? DeadLetterService(),
        sendAttempts = 0;

  /// Dispatches [event] to its target with idempotent delivery and retries.
  @Retryable(
    maxAttempts: 3,
    backoff: Backoff(delay: 20, multiplier: 2.0, maxDelay: 200),
    label: 'webhookDelivery',
    retryFor: [Exception],
  )
  Future<DispatchResult> dispatch(WebhookEvent event) async {
    sendAttempts++;

    if (!_idempotency.claim(event.id)) {
      return DispatchResult(
        deliveryId: event.id,
        delivered: false,
        attempts: sendAttempts - 1,
        failureReason: 'Duplicate delivery ignored by idempotency cache',
      );
    }

    while (sendAttempts <= transientFailuresBeforeSuccess) {
      throw TimeoutException('Simulated transient failure on attempt $sendAttempts');
    }

    if (permanentFailure) {
      throw StateError('Permanent delivery failure simulated');
    }

    return DispatchResult(
      deliveryId: event.id,
      delivered: true,
      attempts: sendAttempts,
    );
  }

  /// Recovery handler — invoked when retries are exhausted.
  @Recover(label: 'webhookDelivery')
  Future<DispatchResult> recover(Exception error, WebhookEvent event) async {
    _deadLetter.recordFailure(event, error, sendAttempts);
    _idempotency.release(event.id);
    return DispatchResult(
      deliveryId: event.id,
      delivered: false,
      attempts: sendAttempts,
      failureReason: error.toString(),
    );
  }

  /// Number of recorded dead-letter entries.
  int get deadLetterCount => _deadLetter.size;

  /// Releases a delivery so a 3rd-party consumer can replay it manually.
  void releaseForReplay(String deliveryId) => _idempotency.release(deliveryId);

  /// Exposes the internal idempotency cache size for observability.
  int get idempotencySize => _idempotency.size;
}
