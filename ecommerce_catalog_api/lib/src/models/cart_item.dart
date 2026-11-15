/// Represents an individual product line in a user's shopping cart.
final class CartItem {
  final String productId;
  final String productName;
  final double unitPrice;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  double get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'totalPrice': totalPrice,
  };
}
