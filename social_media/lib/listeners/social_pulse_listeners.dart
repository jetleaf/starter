/// Event listeners — decoupled reactions to SocialPulse domain events.
library;

import 'package:jetleaf/jetleaf.dart';

import '../domain/notification.dart';
import '../events/social_pulse_events.dart';
import '../repository/user_repository.dart';
import '../service/analytics_service.dart';
import '../service/moderation_service.dart';
import '../service/notification_service.dart';
import '../service/external_push_client.dart';

/// Persists notifications — scheduled earliest among listeners.
@Order(10)
@Service()
class NotificationEventListener {
  NotificationEventListener(this._notifications, this._users);

  final NotificationService _notifications;
  final UserRepository _users;

  @EventListener()
  Future<void> onPostLiked(PostLikedEvent event) async {
    if (event.likerId == event.post.authorId) return; // no self-likes
    final liker = await _users.findById(event.likerId);
    final likerHandle = liker?.handle ?? 'someone';
    await _notifications.notify(
      userId: event.post.authorId,
      kind: NotificationKind.like,
      message: '@$likerHandle liked your post.',
      actorHandle: likerHandle,
      postId: event.post.id,
    );
  }

  @EventListener()
  Future<void> onCommentAdded(CommentAddedEvent event) async {
    if (event.comment.authorId == event.postAuthorId) return;
    await _notifications.notify(
      userId: event.postAuthorId,
      kind: NotificationKind.comment,
      message: '@${event.comment.authorHandle} commented on your post.',
      actorHandle: event.comment.authorHandle,
      postId: event.comment.postId,
    );
  }

  @EventListener()
  Future<void> onUserFollowed(UserFollowedEvent event) async {
    await _notifications.notify(
      userId: event.followee.id,
      kind: NotificationKind.follow,
      message: '@${event.follower.handle} started following you.',
      actorHandle: event.follower.handle,
    );
  }

  @EventListener()
  Future<void> onMentionDetected(MentionDetectedEvent event) async {
    final mentioned = await _users.findByHandle(event.mentionedHandle);
    if (mentioned == null || mentioned.isSuspended) return;
    await _notifications.notify(
      userId: mentioned.id,
      kind: NotificationKind.mention,
      message: 'You were mentioned in a post by @${event.post.authorHandle}.',
      actorHandle: event.post.authorHandle,
      postId: event.post.id,
    );
  }
}

/// Moderation triage on reports — after notifications.
@Order(20)
@Service()
class ModerationEventListener {
  ModerationEventListener(this._moderation);

  final ModerationService _moderation;

  @EventListener()
  Future<void> onPostReported(PostReportedEvent event) async {
    await _moderation.evaluatePost(event.postId);
  }
}

/// Anonymous analytics counters — after moderation triage.
@Order(30)
@Service()
class AnalyticsEventListener {
  AnalyticsEventListener(this._analytics);

  final AnalyticsService _analytics;

  @EventListener()
  void onPostCreated(PostCreatedEvent event) {
    _analytics.increment('socialpulse.posts.created');
    _analytics.track('post.created:${event.post.id}');
  }

  @EventListener()
  void onPostLiked(PostLikedEvent event) => _analytics.increment('socialpulse.likes.total');

  @EventListener()
  void onCommentAdded(CommentAddedEvent event) => _analytics.increment('socialpulse.comments.total');

  @EventListener()
  void onUserRegistered(UserRegisteredEvent event) =>
      _analytics.increment('socialpulse.users.registered');

  @EventListener()
  void onUserFollowed(UserFollowedEvent event) =>
      _analytics.increment('socialpulse.follows.total');

  @EventListener()
  void onPostDeleted(PostDeletedEvent event) =>
      _analytics.increment('socialpulse.posts.deleted');
}

/// Best-effort push notification fan-out — after analytics.
@Order(40)
@Service()
class PushNotificationEventListener {
  PushNotificationEventListener(this._push);

  static final Log _logger = LogFactory.getLog(PushNotificationEventListener);

  final ExternalPushClient _push;

  @EventListener()
  Future<void> onCommentAdded(CommentAddedEvent event) async {
    try {
      final receipt = await _push.send(
        'device:${event.postAuthorId}',
        'New comment',
        '@${event.comment.authorHandle} replied to your post',
      );
      if (!receipt.delivered) {
        _logger.warn('push dropped for ${event.postAuthorId}: ${receipt.detail}');
      } else {
        _logger.info('push delivered for ${event.postAuthorId}: ${receipt.detail}');
      }
    } catch (e, st) {
      _logger.error('push dispatch blew up for ${event.postAuthorId}', error: e, stacktrace: st);
    }
  }
}

/// Audit trail — runs last so earlier listeners can contribute.
@Order(90)
@Service()
class AuditEventListener {
  AuditEventListener();

  static final Log _logger = LogFactory.getLog(AuditEventListener);

  @EventListener()
  void onPostCreated(PostCreatedEvent event) =>
      _logger.info('AUDIT post.created id=${event.post.id} author=${event.post.authorId}');

  @EventListener()
  void onPostDeleted(PostDeletedEvent event) =>
      _logger.info('AUDIT post.deleted id=${event.postId} actor=${event.authorId}');

  @EventListener()
  void onPostReported(PostReportedEvent event) =>
      _logger.info('AUDIT post.reported id=${event.postId} reports=${event.reports}');
}
