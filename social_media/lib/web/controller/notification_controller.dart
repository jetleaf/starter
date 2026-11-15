/// Notification inbox API.
library;

import 'package:jetleaf_web/jetleaf_web.dart';

import '../../service/notification_service.dart';
import '../../service/user_service.dart';

@RestController('/api/notifications')
class NotificationController {
  NotificationController(this._notifications, this._users);

  final NotificationService _notifications;
  final UserService _users;

  /// Paged inbox (optionally unread only).
  @GetMapping()
  Future<Map<String, dynamic>> inbox(
    @RequestAttribute(value: 'actorHandle') String actor,
    @RequestParam(value: 'unread', required: false, defaultValue: 'false') bool unreadOnly,
    @RequestParam(value: 'offset', required: false, defaultValue: '0') int offset,
    @RequestParam(value: 'limit', required: false, defaultValue: '20') int limit,
  ) async {
    final viewer = await _users.requireActiveByHandle(actor);
    if (unreadOnly) {
      final unread = await _notifications.unread(viewer.id, limit: limit.clamp(1, 100));
      return {
        'notifications': [for (final n in unread) n.toJson()],
        'unread': unread.length,
      };
    }
    final recent = await _notifications.recent(viewer.id,
        offset: offset.clamp(0, 10000), limit: limit.clamp(1, 100));
    return {
      'notifications': [for (final n in recent) n.toJson()],
      'unread': await _notifications.unreadCount(viewer.id),
    };
  }

  @GetMapping(path: '/unread-count')
  Future<Map<String, dynamic>> unreadCount(@RequestAttribute(value: 'actorHandle') String actor) async {
    final viewer = await _users.requireActiveByHandle(actor);
    return {'unread': await _notifications.unreadCount(viewer.id)};
  }

  @PostMapping(path: '/mark-all-read')
  Future<Map<String, dynamic>> markAllRead(@RequestAttribute(value: 'actorHandle') String actor) async {
    final viewer = await _users.requireActiveByHandle(actor);
    final marked = await _notifications.markAllRead(viewer.id);
    return {'markedRead': marked};
  }
}
