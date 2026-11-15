/// Domain exceptions for the order service.
library;

sealed class OrderServiceException implements Exception {
  const OrderServiceException(this.message);

  final String message;
  String get code;
  int get status;
}

final class OrderNotFoundException extends OrderServiceException {
  const OrderNotFoundException(this.id) : super('Order not found: $id');

  final String id;
  @override
  String get code => 'order_not_found';
  @override
  int get status => 404;
}

final class InvalidOrderException extends OrderServiceException {
  const InvalidOrderException(super.message);
  @override
  String get code => 'invalid_order';
  @override
  int get status => 422;
}
