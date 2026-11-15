import 'cart_item.dart';

/// Represents a customer's active shopping cart session.
final class Cart {
  final List<CartItem> items;

  Cart({List<CartItem>? items}) : items = items ?? [];

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  int get totalItemCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  Map<String, dynamic> toJson() => {
    'items': items.map((i) => i.toJson()).toList(),
    'totalItemCount': totalItemCount,
    'subtotal': subtotal,
  };
}
