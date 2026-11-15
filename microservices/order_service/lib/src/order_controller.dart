/// Order-service REST API.
library;

import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

import 'exception.dart';
import 'order.dart';
import 'order_events.dart';
import 'order_store.dart';
import 'order_user_client.dart';

@RestController('/orders')
class OrderController {
  OrderController(this._orders, this._users, this._events);

  final OrderStore _orders;
  final OrderUserClient _users;
  final ApplicationContext _events;

  /// `GET /orders` — full listing.
  @GetMapping()
  Map<String, dynamic> listOrders() => {
        'count': _orders.count,
        'orders': [for (final o in _orders.findAll()) o.toJson()],
      };

  /// `GET /orders/{id}` — one order or 404.
  @GetMapping(path: '/{id}')
  Map<String, dynamic> getOrder(@PathVariable(value: 'id') String id) {
    final order = _orders.findById(id);
    if (order == null) {
      throw OrderNotFoundException(id);
    }
    return order.toJson();
  }

  /// `POST /orders` — validate the customer with user-service, place the
  /// order and publish [OrderPlacedEvent] so the notification listener relays
  /// a confirmation message.
  @PostMapping()
  Future<ResponseBody<Map<String, dynamic>>> createOrder(
    @RequestBody() Map<String, dynamic> body,
  ) async {
    final customerId = (body['customerId'] as String?)?.trim();
    if (customerId == null || customerId.isEmpty) {
      throw const InvalidOrderException('customerId must not be blank');
    }
    final items = ((body['items'] as List<dynamic>?) ?? const [])
        .map((i) => OrderItem.fromJson((i as Map).cast<String, dynamic>()))
        .toList();
    if (items.isEmpty) {
      throw const InvalidOrderException('orders must contain at least one item');
    }
    for (final item in items) {
      if (item.quantity <= 0 || item.unitPriceCents <= 0 || item.sku.trim().isEmpty) {
        throw const InvalidOrderException('items need sku, positive quantity and positive price');
      }
    }

    final customer = await _users.findCustomer(customerId);
    if (customer == null) {
      throw InvalidOrderException('customer "$customerId" does not exist');
    }

    final order = PurchaseOrder(
      id: 'ord_${DateTime.now().toUtc().millisecondsSinceEpoch}',
      customerId: customerId,
      items: items,
      status: OrderStatus.confirmed,
      createdAt: DateTime.now().toUtc(),
      customerHandle: customer.handle,
      customerTier: customer.tier,
    );
    await _orders.save(order);
    await _events.publishEvent(OrderPlacedEvent(order));
    return ResponseBody.of(HttpStatus.CREATED, order.toJson());
  }
}
