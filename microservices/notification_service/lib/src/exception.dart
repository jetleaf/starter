/// Domain exceptions for the notification service.
library;

sealed class NotificationServiceException implements Exception {
  const NotificationServiceException(this.message);

  final String message;
  String get code;
  int get status;
}

final class InvalidNotificationException extends NotificationServiceException {
  const InvalidNotificationException(super.message);
  @override
  String get code => 'invalid_notification';
  @override
  int get status => 422;
}

final class NotificationNotFoundException extends NotificationServiceException {
  const NotificationNotFoundException(this.id) : super('Notification not found: $id');

  final String id;
  @override
  String get code => 'notification_not_found';
  @override
  int get status => 404;
}
