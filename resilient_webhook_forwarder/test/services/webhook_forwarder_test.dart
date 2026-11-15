import 'package:resilient_webhook_forwarder/src/services/dead_letter_service.dart';
import 'package:resilient_webhook_forwarder/src/services/idempotency_service.dart';
import 'package:resilient_webhook_forwarder/src/services/webhook_delivery_service.dart';
import 'package:resilient_webhook_forwarder/src/models/webhook_event.dart';
import 'package:test/test.dart';

void main() {
  group('IdempotencyService', () {
    test('claims first occurrence and rejects repeats', () {
      final service = IdempotencyService();
      expect(service.claim('evt-1'), isTrue);
      expect(service.claim('evt-1'), isFalse);
      expect(service.size, 1);
    });

    test('release allows re-claim', () {
      final service = IdempotencyService();
      expect(service.claim('evt-1'), isTrue);
      service.release('evt-1');
      expect(service.claim('evt-1'), isTrue);
    });

    test('isKnown reflects claim state', () {
      final service = IdempotencyService();
      expect(service.isKnown('evt-1'), isFalse);
      service.claim('evt-1');
      expect(service.isKnown('evt-1'), isTrue);
    });

    test('respects max entries capacity', () {
      final service = IdempotencyService(maxEntries: 3);
      for (var i = 0; i < 5; i++) {
        service.claim('evt-$i');
      }
      expect(service.size, lessThanOrEqualTo(3));
    });
  });

  group('DeadLetterService', () {
    test('records and drains dead-letter entries', () {
      final service = DeadLetterService();
      final event = WebhookEvent(
        id: 'evt-1',
        type: 'payment.received',
        targetUrl: 'https://payments.example.com/hook',
        payload: {'amount': 42.0},
      );

      expect(service.size, 0);
      service.recordFailure(event, Exception('500 upstream'), 3);
      expect(service.size, 1);

      final drained = service.drain();
      expect(drained, hasLength(1));
      expect(drained.first['deliveryId'], 'evt-1');
      expect(drained.first['attempts'], 3);
      expect(service.size, 0);
    });
  });

  group('WebhookDeliveryService', () {
    test('dispatches successfully and records send attempts', () async {
      final service = WebhookDeliveryService();
      final event = WebhookEvent(
        id: 'evt-100',
        type: 'user.created',
        targetUrl: 'https://users.example.com/hook',
        payload: {'name': 'Ada'},
      );

      final result = await service.dispatch(event);
      expect(result.delivered, isTrue);
      expect(result.deliveryId, 'evt-100');
      expect(result.attempts, greaterThanOrEqualTo(1));
      expect(service.sendAttempts, greaterThanOrEqualTo(1));
    });

    test('duplicate deliveries are rejected by idempotency cache', () async {
      final service = WebhookDeliveryService();
      final event = WebhookEvent(
        id: 'evt-200',
        type: 'user.updated',
        targetUrl: 'https://users.example.com/hook',
        payload: {'name': 'Grace'},
      );

      final first = await service.dispatch(event);
      expect(first.delivered, isTrue);

      final second = await service.dispatch(event);
      expect(second.delivered, isFalse);
      expect(second.failureReason, contains('Duplicate'));
    });

    test('permanent failure routes through recovery path', () async {
      final service = WebhookDeliveryService(permanentFailure: true);
      final event = WebhookEvent(
        id: 'evt-300',
        type: 'order.cancelled',
        targetUrl: 'https://orders.example.com/hook',
        payload: {'orderId': 42},
      );

      // Without the retry proxy (direct call), the exception propagates.
      await expectLater(service.dispatch(event), throwsA(isA<StateError>()));
    });
  });
}
