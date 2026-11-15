import 'package:jetleaf/jetleaf.dart';

import '../dto/checkout_dto.dart';
import '../exceptions/ecommerce_exceptions.dart';
import '../models/cart_item.dart';
import '../models/customer_order.dart';
import 'cart_service.dart';
import 'product_service.dart';

/// Business service coordinating checkout, inventory decrement, and order tracking.
@Service()
class OrderService {
  final ProductService _productService;
  final CartService _cartService;
  final Map<String, CustomerOrder> _orders = {};
  int _orderCounter = 1000;

  // Constructor dependency injection of collaborator pods
  OrderService(this._productService, this._cartService);

  CustomerOrder checkout(String cartId, CheckoutDto dto) {
    final cart = _cartService.getCart(cartId);

    if (cart.items.isEmpty) {
      throw EmptyCartException();
    }

    // 1. Verify and reserve stock for all items atomically
    for (final item in cart.items) {
      _productService.reserveStock(item.productId, item.quantity);
    }

    // 2. Create the finalized order
    final orderId = 'ORD-${++_orderCounter}';
    final order = CustomerOrder(
      id: orderId,
      customerEmail: dto.customerEmail,
      shippingAddress: dto.shippingAddress,
      items: List<CartItem>.from(cart.items),
      totalAmount: cart.subtotal,
      status: OrderStatus.confirmed,
      createdAt: DateTime.now(),
    );

    _orders[orderId] = order;

    // 3. Clear the user's cart after successful placement
    _cartService.clearCart(cartId);

    return order;
  }

  CustomerOrder getById(String id) {
    final order = _orders[id];
    if (order == null) {
      throw OrderNotFoundException(id);
    }
    return order;
  }

  List<CustomerOrder> getAll() {
    final list = _orders.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}
