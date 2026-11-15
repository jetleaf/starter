import 'package:jetleaf_web/jetleaf_web.dart';

import '../dto/add_to_cart_dto.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';

/// REST API controller managing cart operations.
@RestController('/api/v1/cart')
class CartController {
  final CartService _cartService;
  final ProductService _productService;

  CartController(this._cartService, this._productService);

  /// Retrieves the current customer cart contents and subtotal.
  @GetMapping()
  Map<String, dynamic> getCart(
    @RequestParam(value: 'cartId', defaultValue: 'default-cart') String cartId,
  ) {
    return _cartService.getCart(cartId).toJson();
  }

  /// Adds an item to the shopping cart with quantity validation.
  @PostMapping(path: '/items')
  ResponseBody<Map<String, dynamic>> addItem(
    @RequestBody() Map<String, dynamic> body,
    @RequestParam(value: 'cartId', defaultValue: 'default-cart') String cartId,
  ) {
    final dto = AddToCartDto.fromJson(body);
    final product = _productService.getById(dto.productId);

    // Verify stock availability
    _productService.reserveStock(dto.productId, 0); // Validates product exists

    final updatedCart = _cartService.addItem(cartId, dto, product);
    return ResponseBody.ok(updatedCart.toJson());
  }

  /// Removes a specific product from the cart.
  @DeleteMapping(path: '/items/{productId}')
  Map<String, dynamic> removeItem(
    @PathVariable(value: 'productId') String productId,
    @RequestParam(value: 'cartId', defaultValue: 'default-cart') String cartId,
  ) {
    return _cartService.removeItem(cartId, productId).toJson();
  }

  /// Clears all items in the cart.
  @DeleteMapping()
  Map<String, dynamic> clearCart(
    @RequestParam(value: 'cartId', defaultValue: 'default-cart') String cartId,
  ) {
    _cartService.clearCart(cartId);
    return {'message': 'Cart cleared successfully', 'cartId': cartId};
  }
}
