import 'package:jetleaf/jetleaf.dart';

import '../dto/add_to_cart_dto.dart';
import '../models/cart.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

/// Business service managing shopping carts and item quantities.
@Service()
class CartService {
  final Map<String, Cart> _carts = {};

  Cart getCart(String cartId) {
    return _carts.putIfAbsent(cartId, () => Cart());
  }

  Cart addItem(String cartId, AddToCartDto dto, Product product) {
    final cart = getCart(cartId);
    final existingIndex =
        cart.items.indexWhere((item) => item.productId == product.id);

    if (existingIndex >= 0) {
      cart.items[existingIndex].quantity += dto.quantity;
    } else {
      cart.items.add(CartItem(
        productId: product.id,
        productName: product.name,
        unitPrice: product.price,
        quantity: dto.quantity,
      ));
    }

    return cart;
  }

  Cart removeItem(String cartId, String productId) {
    final cart = getCart(cartId);
    cart.items.removeWhere((item) => item.productId == productId);
    return cart;
  }

  void clearCart(String cartId) {
    final cart = _carts[cartId];
    if (cart != null) {
      cart.items.clear();
    }
  }
}
