/// Notification-service REST API.
library;

import 'package:jetleaf_web/jetleaf_web.dart';

import 'exception.dart';
import 'notification.dart';
import 'notification_store.dart';

@RestController('/notifications')
class NotificationController {
  NotificationController(this._notifications);

  final NotificationStore _notifications;

  /// `POST /notifications` — create a notification.
  @PostMapping()
  Future<ResponseBody<Map<String, dynamic>>> create(
    @RequestBody() Map<String, dynamic> body,
  ) async {
    final customerId = (body['customerId'] as String?)?.trim();
    final title = (body['title'] as String?)?.trim();
    if (customerId == null || customerId.isEmpty) {
      throw const InvalidNotificationException('customerId must not be blank');
    }
    if (title == null || title.isEmpty) {
      throw const InvalidNotificationException('title must not be blank');
    }
    final bodyText = (body['body'] as String?)?.trim() ?? '';
    final kind = AppNotification.kindFromString(body['kind'] as String?);

    final notification = AppNotification(
      id: 'ntf_${DateTime.now().toUtc().millisecondsSinceEpoch}_${_notifications.count}',
      customerId: customerId,
      title: title,
      body: bodyText,
      kind: kind,
      createdAt: DateTime.now().toUtc(),
    );
    await _notifications.save(notification);
    return ResponseBody.of(HttpStatus.CREATED, notification.toJson());
  }

  /// `GET /notifications?customerId=cus_ada&limit=20`
  @GetMapping()
  Future<Map<String, dynamic>> list(
    @RequestParam(value: 'customerId') String customerId,
    @RequestParam(value: 'limit', required: false, defaultValue: '20') int limit,
  ) async {
    final items = _notifications.findByCustomer(customerId, limit: limit.clamp(1, 100));
    return {
      'customerId': customerId,
      'count': items.length,
      'unread': await _notifications.unreadCount(customerId),
      'notifications': [for (final n in items) n.toJson()],
    };
  }

  /// `GET /notifications/unread-count?customerId=cus_ada`
  @GetMapping(path: '/unread-count')
  Future<Map<String, dynamic>> unreadCount(
    @RequestParam(value: 'customerId') String customerId,
  ) async =>
      {'customerId': customerId, 'unread': await _notifications.unreadCount(customerId)};

  /// `POST /notifications/mark-all-read?customerId=cus_ada`
  @PostMapping(path: '/mark-all-read')
  Future<Map<String, dynamic>> markAllRead(
    @RequestParam(value: 'customerId') String customerId,
  ) async {
    final marked = await _notifications.markAllRead(customerId);
    return {'customerId': customerId, 'markedRead': marked};
  }
}
