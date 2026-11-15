import 'package:ecommerce_catalog_api/src/dto/create_product_dto.dart';
import 'package:ecommerce_catalog_api/src/exceptions/ecommerce_exceptions.dart';
import 'package:ecommerce_catalog_api/src/services/product_service.dart';
import 'package:test/test.dart';

void main() {
  late ProductService productService;

  setUp(() {
    productService = ProductService();
  });

  group('ProductService', () {
    test('initializes with seed products', () {
      final products = productService.getAll();
      expect(products, isNotEmpty);
      expect(products.length, greaterThanOrEqualTo(4));
    });

    test('filters products by category', () {
      final peripherals = productService.getAll(category: 'Peripherals');
      expect(peripherals.every((p) => p.category == 'Peripherals'), isTrue);
    });

    test('searches products by query string', () {
      final results = productService.getAll(search: 'keyboard');
      expect(results.length, equals(1));
      expect(results.first.name, contains('Keyboard'));
    });

    test('creates a new product successfully', () {
      final dto = CreateProductDto(
        name: 'Wireless Mouse',
        description: 'Ultra-low latency wireless gaming mouse.',
        price: 79.99,
        stockQuantity: 15,
        category: 'Peripherals',
      );

      final created = productService.create(dto);
      expect(created.id, startsWith('prod-'));
      expect(created.name, equals('Wireless Mouse'));

      final retrieved = productService.getById(created.id);
      expect(retrieved.name, equals('Wireless Mouse'));
    });

    test('throws ProductNotFoundException when ID is invalid', () {
      expect(
        () => productService.getById('non-existent-id'),
        throwsA(isA<ProductNotFoundException>()),
      );
    });

    test('reserves stock successfully when available', () {
      final product = productService.getById('prod-1');
      final originalStock = product.stockQuantity;

      productService.reserveStock('prod-1', 2);
      expect(product.stockQuantity, equals(originalStock - 2));
    });

    test('throws InsufficientStockException when stock is insufficient', () {
      // prod-4 was seeded with 0 stock
      expect(
        () => productService.reserveStock('prod-4', 1),
        throwsA(isA<InsufficientStockException>()),
      );
    });
  });
}
