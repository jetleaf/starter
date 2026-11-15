/// Notification fan-out, persistence and read-state.
library;

import 'package:jetleaf/jetleaf.dart';

import '../domain/notification.dart';
import '../repository/comment_like_follow_notification_repository.dart';
import '../util/ids.dart';
import 'notification_draft.dart';

@Service()
class NotificationService {
  NotificationService(this._notifications, this._clock, this._podFactory);

  final NotificationRepository _notifications;
  final SocialClock _clock;
  final PodFactory _podFactory;

  Future<AppNotification> notify({
    required String userId,
    required NotificationKind kind,
    required String message,
    String? actorHandle,
    String? postId,
  }) async {
    // Prototype lookup — a fresh draft every call (never the same instance twice).
    final draft = await _podFactory.getPod<NotificationDraft>('notificationDraft');
    final payload = draft
        .title('SocialPulse · ${kind.name}')
        .body(message)
        .recipient(userId)
        .build();

    return _notifications.save(AppNotification(
      id: Ids.prefixed('ntf'),
      userId: userId,
      kind: kind,
      message: payload['body'] as String? ?? message,
      actorHandle: actorHandle,
      postId: postId,
      createdAt: _clock.now(),
    ));
  }

  Future<List<AppNotification>> unread(String userId, {int limit = 50}) =>
      _notifications.findUnread(userId, limit: limit);

  Future<List<AppNotification>> recent(String userId, {int offset = 0, int limit = 20}) =>
      _notifications.findByUser(userId, page: PageRequestSlice(offset: offset, limit: limit));

  Future<int> unreadCount(String userId) => _notifications.unreadCount(userId);

  Future<int> markAllRead(String userId) => _notifications.markAllRead(userId);
}
