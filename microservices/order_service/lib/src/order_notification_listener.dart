/// Reacts to [OrderPlacedEvent] by dispatching to the notification service.
library;

import 'package:jetleaf/jetleaf.dart';

import 'notification_client.dart';
import 'order_events.dart';

@Service()
class OrderNotificationListener {
  OrderNotificationListener(this._notifications);

  static final Log _logger = LogFactory.getLog(OrderNotificationListener);

  final NotificationClient _notifications;

  @EventListener()
  Future<void> onOrderPlaced(OrderPlacedEvent event) async {
    final order = event.order;
    final result = await _notifications.send(
      customerId: order.customerId,
      title: 'Order ${order.id} confirmed',
      body: 'Thanks! Your order totalling ${order.totalCents} cents is confirmed.',
      kind: 'order_confirmed',
    );
    if (!result.sent) {
      _logger.warn('notification for order ${order.id} not delivered: ${result.detail}');
    }
  }
}
