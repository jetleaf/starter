import 'dart:async';

import 'package:jetleaf/jetleaf.dart';

import '../events/orders_event.dart';

/// In-memory order store used by the checkout pipeline.
///
/// Publishes [OrderPlacedEvent], [OrderProcessedEvent] and [OrderNotifiedEvent]
/// through the injected [ApplicationContext] so listeners (audit log,
/// notification dispatch) remain fully decoupled from the pipeline.
@Service()
class OrderService {
  static final Log _logger = LogFactory.getLog(OrderService);

  final ApplicationContext _applicationContext;

  final List<Map<String, Object?>> _orders = [];
  int _counter = 0;

  static const _seed = [
    {
      'id': 'order-001',
      'customerId': 'cus-ada',
      'total': 245.50,
      'items': ['Premium Mechanical Keyboard', 'Ergonomic Desk Mat'],
      'status': 'PROCESSED',
      'createdAt': '2026-11-08T10:00:00Z',
    },
    {
      'id': 'order-002',
      'customerId': 'cus-grace',
      'total': 899.00,
      'items': ['Ultra-Wide 34-inch Monitor'],
      'status': 'PROCESSING',
      'createdAt': '2026-11-12T14:30:00Z',
    },
  ];

  OrderService(this._applicationContext) {
    for (final seed in _seed) {
      _orders.add(Map.of(seed));
    }
    _counter = _orders.length;
  }

  List<Map<String, Object?>> listOrders() => List.unmodifiable(_orders);

  Map<String, Object?>? findById(String id) {
    for (final order in _orders) {
      if (order['id'] == id) return Map.of(order);
    }
    return null;
  }

  Future<Map<String, Object?>> placeOrder({
    required String customerId,
    required double total,
    required List<String> items,
  }) async {
    _counter++;
    final order = {
      'id': 'order-${_counter.toString().padLeft(3, '0')}',
      'customerId': customerId,
      'total': total,
      'items': items,
      'status': 'PROCESSING',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    _orders.add(order);
    _logger.info('Order placed: ${order['id']}');

    // Fan out to any registered @EventListener pods.
    await _applicationContext.publishEvent(OrderPlacedEvent(
      orderId: order['id']! as String,
      customerId: customerId,
      total: total,
    ));

    return order;
  }

  Future<Map<String, Object?>?> processOrder(String orderId) async {
    final index = _orders.indexWhere((o) => o['id'] == orderId);
    if (index == -1) return null;

    _orders[index] = {
      ..._orders[index],
      'status': 'PROCESSED',
    };
    _logger.info('Order processed: $orderId');

    await _applicationContext.publishEvent(OrderProcessedEvent(orderId: orderId));
    return Map.of(_orders[index]);
  }

  Future<Map<String, Object?>?> notifyOrder(String orderId) async {
    final index = _orders.indexWhere((o) => o['id'] == orderId);
    if (index == -1) return null;

    _orders[index] = {
      ..._orders[index],
      'notifiedAt': DateTime.now().toUtc().toIso8601String(),
    };
    final customerId = _orders[index]['customerId']! as String;
    _logger.info('Order notified: $orderId');

    await _applicationContext.publishEvent(OrderNotifiedEvent(orderId: orderId, customerId: customerId));
    return Map.of(_orders[index]);
  }
}
