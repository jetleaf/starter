import 'package:jetleaf/jetleaf.dart';
import 'package:event_driven_order_hub/src/events/orders_event.dart';

/// Audit listener that records order-placement events to an in-memory log.
@Service()
class AuditLogListener {
  static final Log _logger = LogFactory.getLog(AuditLogListener);
  final List<String> entries = [];

  @EventListener()
  void onOrderPlaced(OrderPlacedEvent event) {
    final entry = '[AUDIT] order=${event.orderId} customer=${event.customerId} total=\$${event.total.toStringAsFixed(2)}';
    entries.add(entry);
    _logger.info(entry);
  }

  @EventListener()
  void onOrderProcessed(OrderProcessedEvent event) {
    final entry = '[AUDIT] order=${event.orderId} processed';
    entries.add(entry);
    _logger.info(entry);
  }

  @EventListener()
  void onOrderNotified(OrderNotifiedEvent event) {
    final entry = '[AUDIT] order=${event.orderId} notified customer=${event.customerId}';
    entries.add(entry);
    _logger.info(entry);
  }

  List<String> getRecentEntries() => List.unmodifiable(entries);
}
