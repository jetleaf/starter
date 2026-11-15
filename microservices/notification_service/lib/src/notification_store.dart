/// In-memory notification store — one seeded notification for `cus_ada`.
library;

import 'package:jetleaf/jetleaf.dart';

import 'notification.dart';

@Repository()
class NotificationStore {
  NotificationStore() {
    _notifications['ntf_seed_ada_0001'] = AppNotification(
      id: 'ntf_seed_ada_0001',
      customerId: 'cus_ada',
      title: 'Welcome to Jetleaf',
      body: 'This is a seeded notification from notification-service.',
      kind: NotificationKind.system,
      createdAt: DateTime.now().toUtc().subtract(const Duration(days: 2)),
    );
  }

  final Map<String, AppNotification> _notifications = {};

  AppNotification? findById(String id) => _notifications[id];

  List<AppNotification> findByCustomer(String customerId, {int limit = 50}) {
    final matched = _notifications.values
        .where((n) => n.customerId == customerId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matched.take(limit).toList(growable: false);
  }

  Future<AppNotification> save(AppNotification notification) async {
    _notifications[notification.id] = notification;
    return notification;
  }

  Future<int> unreadCount(String customerId) async {
    return _notifications.values
        .where((n) => n.customerId == customerId && !n.read)
        .length;
  }

  Future<int> markAllRead(String customerId) async {
    var count = 0;
    for (final n in _notifications.values) {
      if (n.customerId == customerId && !n.read) {
        n.read = true;
        count++;
      }
    }
    return count;
  }

  int get count => _notifications.length;
}
