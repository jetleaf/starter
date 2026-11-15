import 'package:ecommerce_catalog_api/src/dto/add_to_cart_dto.dart';
import 'package:ecommerce_catalog_api/src/dto/checkout_dto.dart';
import 'package:ecommerce_catalog_api/src/exceptions/ecommerce_exceptions.dart';
import 'package:ecommerce_catalog_api/src/models/customer_order.dart';
import 'package:ecommerce_catalog_api/src/services/cart_service.dart';
import 'package:ecommerce_catalog_api/src/services/product_service.dart';
import 'package:ecommerce_catalog_api/src/services/order_service.dart';
import 'package:test/test.dart';

void main() {
  late ProductService productService;
  late CartService cartService;
  late OrderService orderService;

  setUp(() {
    productService = ProductService();
    cartService = CartService();
    orderService = OrderService(productService, cartService);
  });

  group('OrderService', () {
    test('throws EmptyCartException when checking out empty cart', () {
      final dto = CheckoutDto(
        customerEmail: 'customer@example.com',
        shippingAddress: '123 Tech Street, Silicon Valley, CA',
      );

      expect(
        () => orderService.checkout('empty-cart', dto),
        throwsA(isA<EmptyCartException>()),
      );
    });

    test('completes checkout, decrements stock, and clears cart', () {
      const cartId = 'test-cart-1';
      final product = productService.getById('prod-1');
      final initialStock = product.stockQuantity;

      // 1. Add item to cart
      cartService.addItem(
        cartId,
        AddToCartDto(productId: 'prod-1', quantity: 2),
        product,
      );

      expect(cartService.getCart(cartId).items.length, equals(1));

      // 2. Perform checkout
      final order = orderService.checkout(
        cartId,
        CheckoutDto(
          customerEmail: 'alex@example.com',
          shippingAddress: '456 Dart Lane, Flutter City, FC 90210',
        ),
      );

      // Verify order creation
      expect(order.id, startsWith('ORD-'));
      expect(order.customerEmail, equals('alex@example.com'));
      expect(order.status, equals(OrderStatus.confirmed));
      expect(order.totalAmount, equals(product.price * 2));

      // Verify stock was decremented
      expect(product.stockQuantity, equals(initialStock - 2));

      // Verify cart was cleared
      expect(cartService.getCart(cartId).items, isEmpty);
    });

    test('throws InsufficientStockException and halts checkout when stock is low', () {
      const cartId = 'test-cart-2';
      final outOfStockProduct = productService.getById('prod-4'); // 0 stock

      cartService.addItem(
        cartId,
        AddToCartDto(productId: 'prod-4', quantity: 1),
        outOfStockProduct,
      );

      expect(
        () => orderService.checkout(
          cartId,
          CheckoutDto(
            customerEmail: 'test@example.com',
            shippingAddress: '789 Code Way, Developer Town',
          ),
        ),
        throwsA(isA<InsufficientStockException>()),
      );
    });
  });
}
