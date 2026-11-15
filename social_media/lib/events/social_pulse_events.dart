/// Application events emitted by SocialPulse use-cases.
///
/// Listeners live in `listeners/` and react via `@EventListener` —
/// they decouple notification fan-out, analytics, moderation and audit
/// from the request path.
library;

import 'package:jetleaf/jetleaf.dart';

import '../domain/comment.dart';
import '../domain/post.dart';
import '../domain/user.dart';

final class PostCreatedEvent extends ApplicationEvent {
  PostCreatedEvent(this.post) : super(Object(), DateTime.now());

  final Post post;

  @override
  String getPackageName() => 'social_media';
}

final class PostDeletedEvent extends ApplicationEvent {
  PostDeletedEvent(this.postId, this.authorId) : super(Object());

  final String postId;
  final String authorId;

  @override
  String getPackageName() => 'social_media';
}

final class PostLikedEvent extends ApplicationEvent {
  PostLikedEvent(this.post, this.likerId) : super(Object(), DateTime.now());

  final Post post;
  final String likerId;

  @override
  String getPackageName() => 'social_media';
}

final class PostUnlikedEvent extends ApplicationEvent {
  PostUnlikedEvent(this.postId, this.likerId) : super(Object());

  final String postId;
  final String likerId;

  @override
  String getPackageName() => 'social_media';
}

final class PostReportedEvent extends ApplicationEvent {
  PostReportedEvent(this.postId, this.reporterId, this.reason, this.reports)
      : super(Object(), DateTime.now());

  final String postId;
  final String reporterId;
  final String reason;
  final int reports;

  @override
  String getPackageName() => 'social_media';
}

final class CommentAddedEvent extends ApplicationEvent {
  CommentAddedEvent(this.comment, this.postAuthorId) : super(Object(), DateTime.now());

  final Comment comment;
  final String postAuthorId;

  @override
  String getPackageName() => 'social_media';
}

final class UserRegisteredEvent extends ApplicationEvent {
  UserRegisteredEvent(this.user) : super(Object(), DateTime.now());

  final UserProfile user;

  @override
  String getPackageName() => 'social_media';
}

final class UserFollowedEvent extends ApplicationEvent {
  UserFollowedEvent(this.follower, this.followee) : super(Object(), DateTime.now());

  final UserProfile follower;
  final UserProfile followee;

  @override
  String getPackageName() => 'social_media';
}

final class MentionDetectedEvent extends ApplicationEvent {
  MentionDetectedEvent(this.post, this.mentionedHandle) : super(Object(), DateTime.now());

  final Post post;
  final String mentionedHandle;

  @override
  String getPackageName() => 'social_media';
}
