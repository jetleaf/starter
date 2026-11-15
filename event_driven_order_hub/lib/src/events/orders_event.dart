import 'package:jetleaf/jetleaf.dart';

/// Published when an order is placed.
final class OrderPlacedEvent extends ApplicationEvent {
  final String orderId;
  final String customerId;
  final double total;

  OrderPlacedEvent({required this.orderId, required this.customerId, required this.total})
      : super(Object(), DateTime.now());

  DateTime get occurredAt => getTimestamp();

  @override
  String getPackageName() => 'event_driven_order_hub';
}

/// Published when the order pipeline finishes processing.
final class OrderProcessedEvent extends ApplicationEvent {
  final String orderId;

  OrderProcessedEvent({required this.orderId}) : super(Object());

  @override
  String getPackageName() => 'event_driven_order_hub';
}

/// Published when an order is notified to the customer.
final class OrderNotifiedEvent extends ApplicationEvent {
  final String orderId;
  final String customerId;

  OrderNotifiedEvent({required this.orderId, required this.customerId}) : super(Object());

  @override
  String getPackageName() => 'event_driven_order_hub';
}
