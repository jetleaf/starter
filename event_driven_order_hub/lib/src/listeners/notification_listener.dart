import 'package:jetleaf/jetleaf.dart';
import 'package:event_driven_order_hub/src/events/orders_event.dart';

/// Simulated email-notification listener.
@Service()
class NotificationListener {
  static final Log _logger = LogFactory.getLog(NotificationListener);
  final List<String> sent = [];

  @EventListener()
  void onOrderPlaced(OrderPlacedEvent event) {
    final message = '[EMAIL] Your order ${event.orderId} has been confirmed.';
    sent.add(message);
    _logger.info(message);
  }

  @EventListener()
  void onOrderProcessed(OrderProcessedEvent event) {
    final message = '[EMAIL] Your order ${event.orderId} has shipped.';
    sent.add(message);
    _logger.info(message);
  }

  @EventListener()
  void onOrderNotified(OrderNotifiedEvent event) {
    final message = '[EMAIL] Your order ${event.orderId} receipt sent to ${event.customerId}';
    sent.add(message);
    _logger.info(message);
  }

  List<String> getSent() => List.unmodifiable(sent);
}
