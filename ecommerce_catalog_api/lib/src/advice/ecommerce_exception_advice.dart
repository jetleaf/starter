import 'package:jetleaf_web/jetleaf_web.dart';

import '../exceptions/ecommerce_exceptions.dart';

/// Centralized REST exception advice translating domain exceptions to HTTP problem details.
@RestControllerAdvice()
class EcommerceExceptionAdvice {
  @ExceptionHandler(ProductNotFoundException)
  ResponseBody<Map<String, dynamic>> handleProductNotFound(
    ProductNotFoundException ex,
  ) {
    return ResponseBody.of(HttpStatus.NOT_FOUND, {
      'error': 'Product Not Found',
      'message': ex.message,
      'productId': ex.productId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @ExceptionHandler(OrderNotFoundException)
  ResponseBody<Map<String, dynamic>> handleOrderNotFound(
    OrderNotFoundException ex,
  ) {
    return ResponseBody.of(HttpStatus.NOT_FOUND, {
      'error': 'Order Not Found',
      'message': ex.message,
      'orderId': ex.orderId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @ExceptionHandler(InsufficientStockException)
  ResponseBody<Map<String, dynamic>> handleInsufficientStock(
    InsufficientStockException ex,
  ) {
    return ResponseBody.of(HttpStatus.CONFLICT, {
      'error': 'Insufficient Stock',
      'message': ex.message,
      'productId': ex.productId,
      'requested': ex.requested,
      'available': ex.available,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @ExceptionHandler(EmptyCartException)
  ResponseBody<Map<String, dynamic>> handleEmptyCart(
    EmptyCartException ex,
  ) {
    return ResponseBody.of(HttpStatus.BAD_REQUEST, {
      'error': 'Empty Cart',
      'message': ex.message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @ExceptionHandler(RequestValidationException)
  ResponseBody<Map<String, dynamic>> handleValidation(
    RequestValidationException ex,
  ) {
    return ResponseBody.of(HttpStatus.UNPROCESSABLE_ENTITY, {
      'error': 'Validation Failed',
      'message': ex.message,
      'violations': ex.errors,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @ExceptionHandler(Exception)
  ResponseBody<Map<String, dynamic>> handleGeneral(
    Exception ex,
  ) {
    return ResponseBody.of(HttpStatus.INTERNAL_SERVER_ERROR, {
      'error': 'Internal Server Error',
      'message': ex.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
