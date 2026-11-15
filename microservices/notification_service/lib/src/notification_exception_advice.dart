/// Notification-service exception advice.
library;

import 'package:jetleaf_web/jetleaf_web.dart';

import 'exception.dart';

@RestControllerAdvice()
class NotificationServiceExceptionAdvice {
  @ExceptionHandler(InvalidNotificationException)
  ResponseBody<Map<String, dynamic>> invalid(InvalidNotificationException ex) => ResponseBody.of(
        HttpStatus.UNPROCESSABLE_ENTITY,
        _problem('invalid_notification', ex.message, 'Check customerId and title.', 422),
      );

  @ExceptionHandler(NotificationNotFoundException)
  ResponseBody<Map<String, dynamic>> notFound(NotificationNotFoundException ex) => ResponseBody.of(
        HttpStatus.NOT_FOUND,
        _problem('notification_not_found', ex.message, 'The notification may not exist.', 404),
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
