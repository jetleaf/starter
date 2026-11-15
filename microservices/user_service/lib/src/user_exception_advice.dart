/// User-service exception advice — RFC 7807-style problem details.
library;

import 'package:jetleaf_web/jetleaf_web.dart';

import 'exception.dart';

@RestControllerAdvice()
class UserServiceExceptionAdvice {
  @ExceptionHandler(UserNotFoundException)
  ResponseBody<Map<String, dynamic>> notFound(UserNotFoundException ex) => ResponseBody.of(
        HttpStatus.NOT_FOUND,
        _problem('user_not_found', ex.message, 'The customer may not exist.', 404),
      );

  @ExceptionHandler(InvalidCustomerException)
  ResponseBody<Map<String, dynamic>> invalid(InvalidCustomerException ex) => ResponseBody.of(
        HttpStatus.UNPROCESSABLE_ENTITY,
        _problem('invalid_customer', ex.message, 'Review the payload and try again.', 422),
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
