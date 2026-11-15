/// Domain events published by the order service.
library;

import 'package:jetleaf/jetleaf.dart';

import 'order.dart';

final class OrderPlacedEvent extends ApplicationEvent {
  OrderPlacedEvent(this.order) : super(Object(), DateTime.now());

  final PurchaseOrder order;

  @override
  String getPackageName() => 'order_service';
}
