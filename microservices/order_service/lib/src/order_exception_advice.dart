/// Order-service exception advice — RFC 7807-style problem details.
library;

import 'package:jetleaf_web/jetleaf_web.dart' hide ServiceUnavailableException;
import 'package:microservices_common/microservices_common.dart';

import 'exception.dart';

@RestControllerAdvice()
class OrderServiceExceptionAdvice {
  @ExceptionHandler(OrderNotFoundException)
  ResponseBody<Map<String, dynamic>> notFound(OrderNotFoundException ex) => ResponseBody.of(
        HttpStatus.NOT_FOUND,
        _problem('order_not_found', ex.message, 'Check the id or list GET /orders.', 404),
      );

  @ExceptionHandler(InvalidOrderException)
  ResponseBody<Map<String, dynamic>> invalid(InvalidOrderException ex) => ResponseBody.of(
        HttpStatus.UNPROCESSABLE_ENTITY,
        _problem('invalid_order', ex.message, 'See /orders contract.', 422),
      );

  @ExceptionHandler(ServiceUnavailableException)
  ResponseBody<Map<String, dynamic>> downstream(ServiceUnavailableException ex) => ResponseBody.of(
        HttpStatus.SERVICE_UNAVAILABLE,
        _problem('downstream_unavailable', ex.toString(), 'Retry the order in a moment.', 503),
      );

  @ExceptionHandler(Exception)
  ResponseBody<Map<String, dynamic>> other(Exception ex) => ResponseBody.of(
        HttpStatus.INTERNAL_SERVER_ERROR,
        _problem('internal_error', ex.toString(), 'Unexpected error.', 500),
      );

  Map<String, dynamic> _problem(String code, String title, String detail, int status) => {
        'type': 'https://docs.jetleaf.dev/problems/$code',
        'title': title,
        'status': status,
        'detail': detail,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };
}
