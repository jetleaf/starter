/// Base for domain-specific order hub exceptions.
sealed class OrderHubException implements Exception {
  final String message;
  OrderHubException(this.message);

  @override
  String toString() => message;
}

/// Thrown when an order id cannot be resolved.
final class OrderNotFoundException extends OrderHubException {
  final String orderId;
  OrderNotFoundException(this.orderId) : super('Order not found: $orderId');
}

/// Thrown when an order cannot be placed because of invalid input.
final class OrderValidationException extends OrderHubException {
  OrderValidationException(super.message);
}
