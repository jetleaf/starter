import 'package:jetleaf_web/jetleaf_web.dart';

import '../exceptions/order_exceptions.dart';
import '../listeners/audit_log_listener.dart';
import '../listeners/notification_listener.dart';
import '../services/order_service.dart';

/// REST API exposing the order pipeline and the event-driven audit trail.
@RestController('/api/v1')
class OrderController {
  final OrderService _orderService;
  final AuditLogListener _auditLog;
  final NotificationListener _notifications;

  OrderController(this._orderService, this._auditLog, this._notifications);

  /// Lists every order currently tracked.
  @GetMapping(path: '/orders')
  List<Map<String, Object?>> listOrders() => _orderService.listOrders();

  /// Fetches a single order by id.
  @GetMapping(path: '/orders/{id}')
  Map<String, Object?> getOrder(@PathVariable(value: 'id') String id) {
    final order = _orderService.findById(id);
    if (order == null) throw OrderNotFoundException(id);
    return order;
  }

  /// Places a new order and publishes [OrderPlacedEvent].
  @PostMapping(path: '/orders')
  Future<ResponseBody<Map<String, Object?>>> placeOrder(@RequestBody() Map<String, dynamic> body) async {
    final customerId = body['customerId'] as String?;
    final total = (body['total'] as num?)?.toDouble();
    final items = (body['items'] as List?)?.cast<String>();

    if (customerId == null || customerId.isEmpty) {
      throw OrderValidationException('Field "customerId" is required');
    }
    if (total == null || total <= 0) {
      throw OrderValidationException('Field "total" is required and must be positive');
    }
    if (items == null || items.isEmpty) {
      throw OrderValidationException('Field "items" is required and must be a non-empty list');
    }

    final order = await _orderService.placeOrder(customerId: customerId, total: total, items: items);
    return ResponseBody.of(HttpStatus.CREATED, order);
  }

  /// Marks an order as processed and publishes [OrderProcessedEvent].
  @PostMapping(path: '/orders/{id}/process')
  Future<ResponseBody<Map<String, Object?>>> processOrder(@PathVariable(value: 'id') String id) async {
    final order = await _orderService.processOrder(id);
    if (order == null) throw OrderNotFoundException(id);
    return ResponseBody.of(HttpStatus.OK, order);
  }

  /// Notifies the customer and publishes [OrderNotifiedEvent].
  @PostMapping(path: '/orders/{id}/notify')
  Future<ResponseBody<Map<String, Object?>>> notifyOrder(@PathVariable(value: 'id') String id) async {
    final order = await _orderService.notifyOrder(id);
    if (order == null) throw OrderNotFoundException(id);
    return ResponseBody.of(HttpStatus.OK, order);
  }

  /// Returns the audit log captured by the audit listener.
  @GetMapping(path: '/audit')
  Map<String, Object?> audit() => {'entries': _auditLog.getRecentEntries()};

  /// Returns the notification log captured by the notification listener.
  @GetMapping(path: '/notifications')
  Map<String, Object?> notifications() => {'sent': _notifications.getSent()};
}
