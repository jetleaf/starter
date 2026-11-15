/// Base exception for all e-commerce domain errors.
abstract class EcommerceException implements Exception {
  final String message;
  final int statusCode;

  const EcommerceException(this.message, {this.statusCode = 400});

  @override
  String toString() => message;
}

/// Thrown when a product is requested by an ID that does not exist.
final class ProductNotFoundException extends EcommerceException {
  final String productId;

  ProductNotFoundException(this.productId)
      : super('Product not found with ID: $productId', statusCode: 404);
}

/// Thrown when an order is requested by an ID that does not exist.
final class OrderNotFoundException extends EcommerceException {
  final String orderId;

  OrderNotFoundException(this.orderId)
      : super('Order not found with ID: $orderId', statusCode: 404);
}

/// Thrown when an order or cart addition requests more items than available in stock.
final class InsufficientStockException extends EcommerceException {
  final String productId;
  final int requested;
  final int available;

  InsufficientStockException({
    required this.productId,
    required this.requested,
    required this.available,
  }) : super(
          'Insufficient stock for product $productId: requested $requested, available $available',
          statusCode: 409,
        );
}

/// Thrown when checkout is attempted on an empty shopping cart.
final class EmptyCartException extends EcommerceException {
  EmptyCartException()
      : super('Cannot checkout an empty shopping cart', statusCode: 400);
}

/// Thrown when request payload fails validation constraints.
final class RequestValidationException extends EcommerceException {
  final List<String> errors;

  RequestValidationException(this.errors)
      : super('Validation failed: ${errors.join(', ')}', statusCode: 422);
}
