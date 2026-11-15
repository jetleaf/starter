/// Domain exceptions for the user service.
library;

sealed class UserServiceException implements Exception {
  const UserServiceException(this.message);

  final String message;
  String get code;
  int get status;
}

final class UserNotFoundException extends UserServiceException {
  const UserNotFoundException(this.id) : super('User not found: $id');

  final String id;
  @override
  String get code => 'user_not_found';
  @override
  int get status => 404;
}

final class InvalidCustomerException extends UserServiceException {
  const InvalidCustomerException(super.message);
  @override
  String get code => 'invalid_customer';
  @override
  int get status => 422;
}
