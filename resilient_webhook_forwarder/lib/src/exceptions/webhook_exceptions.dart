/// Base error for webhook dispatcher domain exceptions.
sealed class WebhookException implements Exception {
  final String message;
  final String? cause;
  WebhookException(this.message, [this.cause]);
}

/// Raised when the delivery fails after all retry attempts are exhausted.
final class WebhookDeliveryFailedException extends WebhookException {
  final String deliveryId;
  final int attempts;
  WebhookDeliveryFailedException({
    required this.deliveryId,
    required this.attempts,
    required String reason,
  }) : super('Webhook delivery failed for $deliveryId after $attempts attempt(s)', reason);
}

/// Raised when the inbound webhook payload is invalid.
final class InvalidWebhookPayloadException extends WebhookException {
  InvalidWebhookPayloadException(super.message);
}

/// Raised when a duplicate event is received.
final class DuplicateWebhookException extends WebhookException {
  final String deliveryId;
  DuplicateWebhookException({required this.deliveryId})
      : super('Duplicate webhook detected for delivery ID $deliveryId');
}
