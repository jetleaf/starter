/// Notification aggregate for the notification service.
library;

enum NotificationKind { orderConfirmed, orderShipped, orderCancelled, system }

class AppNotification {
  AppNotification({
    required this.id,
    required this.customerId,
    required this.title,
    required this.body,
    required this.kind,
    required this.createdAt,
    this.read = false,
  });

  final String id;
  final String customerId;
  final String title;
  final String body;
  final NotificationKind kind;
  final DateTime createdAt;
  bool read;

  static NotificationKind kindFromString(String? raw) {
    return switch (raw?.toLowerCase()) {
      'order_shipped' => NotificationKind.orderShipped,
      'order_cancelled' => NotificationKind.orderCancelled,
      'order_confirmed' => NotificationKind.orderConfirmed,
      _ => NotificationKind.system,
    };
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'title': title,
        'body': body,
        'kind': kind.name,
        'read': read,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };
}
