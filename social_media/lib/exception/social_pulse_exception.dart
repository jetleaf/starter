/// Domain exception hierarchy for SocialPulse — mapped to RFC 7807 problem
/// details by the global `@RestControllerAdvice` in `web/advice/`.
library;

sealed class SocialPulseException implements Exception {
  const SocialPulseException(this.message, {this.detail});

  final String message;
  final String? detail;

  String get code;
  int get status;

  @override
  String toString() => '$code: $message';
}

final class UserNotFoundException extends SocialPulseException {
  const UserNotFoundException(this.handle)
      : super('User not found: $handle', detail: 'No SocialPulse account exists for handle "$handle".');

  final String handle;
  @override
  String get code => 'user_not_found';
  @override
  int get status => 404;
}

final class PostNotFoundException extends SocialPulseException {
  const PostNotFoundException(this.postId)
      : super('Post not found: $postId', detail: 'The post may have been deleted or never existed.');

  final String postId;
  @override
  String get code => 'post_not_found';
  @override
  int get status => 404;
}

final class CommentNotFoundException extends SocialPulseException {
  const CommentNotFoundException(this.commentId) : super('Comment not found: $commentId');

  final String commentId;
  @override
  String get code => 'comment_not_found';
  @override
  int get status => 404;
}

final class DuplicateHandleException extends SocialPulseException {
  const DuplicateHandleException(this.handle) : super('Handle already taken: $handle');

  final String handle;
  @override
  String get code => 'duplicate_handle';
  @override
  int get status => 409;
}

final class SuspendedAccountException extends SocialPulseException {
  const SuspendedAccountException(this.handle)
      : super('Account suspended: $handle', detail: 'This account is suspended and cannot perform writes.');

  final String handle;
  @override
  String get code => 'suspended_account';
  @override
  int get status => 403;
}

final class ForbiddenActionException extends SocialPulseException {
  const ForbiddenActionException(this.action) : super('Forbidden: $action');

  final String action;
  @override
  String get code => 'forbidden';
  @override
  int get status => 403;
}

final class RateLimitExceededException extends SocialPulseException {
  const RateLimitExceededException(this.retryAfterSeconds)
      : super('Rate limit exceeded', detail: 'Retry after $retryAfterSeconds second(s).');

  final int retryAfterSeconds;
  @override
  String get code => 'rate_limited';
  @override
  int get status => 429;
}

final class InvalidMediaException extends SocialPulseException {
  const InvalidMediaException(super.message);
  @override
  String get code => 'invalid_media';
  @override
  int get status => 422;
}

final class ExternalServiceException extends SocialPulseException {
  const ExternalServiceException(this.service, String cause)
      : super('Upstream service failed: $service', detail: cause);

  final String service;
  @override
  String get code => 'upstream_failure';
  @override
  int get status => 502;
}

final class ContentRejectedException extends SocialPulseException {
  const ContentRejectedException(String reason)
      : super('Content rejected by moderation', detail: reason);
  @override
  String get code => 'content_rejected';
  @override
  int get status => 422;
}
