import 'cart_item.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
}

/// Represents a finalized customer order.
final class CustomerOrder {
  final String id;
  final String customerEmail;
  final String shippingAddress;
  final List<CartItem> items;
  final double totalAmount;
  OrderStatus status;
  final DateTime createdAt;

  CustomerOrder({
    required this.id,
    required this.customerEmail,
    required this.shippingAddress,
    required this.items,
    required this.totalAmount,
    this.status = OrderStatus.confirmed,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerEmail': customerEmail,
    'shippingAddress': shippingAddress,
    'items': items.map((item) => item.toJson()).toList(),
    'totalAmount': totalAmount,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
  };
}
