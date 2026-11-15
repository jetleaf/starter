import 'package:jetleaf_web/jetleaf_web.dart';

import '../exceptions/order_exceptions.dart';

/// Centralized REST exception advice translating domain exceptions to HTTP responses.
@RestControllerAdvice()
class OrderAdvice {
  @ExceptionHandler(OrderNotFoundException)
  ResponseBody<Map<String, dynamic>> handleNotFound(OrderNotFoundException ex) {
    return ResponseBody.of(HttpStatus.NOT_FOUND, {
      'error': 'Order Not Found',
      'message': ex.message,
      'orderId': ex.orderId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @ExceptionHandler(OrderValidationException)
  ResponseBody<Map<String, dynamic>> handleValidation(OrderValidationException ex) {
    return ResponseBody.of(HttpStatus.BAD_REQUEST, {
      'error': 'Invalid Order',
      'message': ex.message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
