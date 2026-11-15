import 'package:jetleaf/jetleaf.dart';

import '../dto/create_product_dto.dart';
import '../exceptions/ecommerce_exceptions.dart';
import '../models/product.dart';

/// Business service managing product catalog items, queries, and stock levels.
@Service()
class ProductService {
  final Map<String, Product> _products = {};
  int _idCounter = 1;

  ProductService() {
    _seedCatalog();
  }

  void _seedCatalog() {
    final seedItems = [
      Product(
        id: 'prod-1',
        name: 'Jetleaf Pro Mechanical Keyboard',
        description: 'Tenkeyless RGB mechanical keyboard with custom switches.',
        price: 129.99,
        stockQuantity: 25,
        category: 'Peripherals',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Product(
        id: 'prod-2',
        name: 'Ultra-Wide 34-inch Monitor',
        description: 'Curved 4K USB-C development monitor for productivity.',
        price: 499.50,
        stockQuantity: 10,
        category: 'Monitors',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Product(
        id: 'prod-3',
        name: 'Full-Stack Dart Developer Hoodie',
        description: 'Premium heavyweight cotton hoodie with emerald Jetleaf logo.',
        price: 65.00,
        stockQuantity: 50,
        category: 'Apparel',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Product(
        id: 'prod-4',
        name: 'Ergonomic Desk Mat',
        description: 'Micro-textured waterproof mousepad with non-slip rubber base.',
        price: 29.99,
        stockQuantity: 0, // Out of stock to test stock validation
        category: 'Peripherals',
        createdAt: DateTime.now(),
      ),
    ];

    for (final item in seedItems) {
      _products[item.id] = item;
    }
  }

  List<Product> getAll({String? category, String? search}) {
    var result = _products.values.toList();

    if (category != null && category.isNotEmpty) {
      result = result
          .where((p) => p.category.toLowerCase() == category.toLowerCase())
          .toList();
    }

    if (search != null && search.isNotEmpty) {
      final query = search.toLowerCase();
      result = result
          .where((p) =>
              p.name.toLowerCase().contains(query) ||
              p.description.toLowerCase().contains(query))
          .toList();
    }

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  Product getById(String id) {
    final product = _products[id];
    if (product == null) {
      throw ProductNotFoundException(id);
    }
    return product;
  }

  Product create(CreateProductDto dto) {
    final newId = 'prod-${++_idCounter}';
    final product = Product(
      id: newId,
      name: dto.name,
      description: dto.description,
      price: dto.price,
      stockQuantity: dto.stockQuantity,
      category: dto.category,
      createdAt: DateTime.now(),
    );

    _products[newId] = product;
    return product;
  }

  void reserveStock(String id, int quantity) {
    final product = getById(id);
    if (product.stockQuantity < quantity) {
      throw InsufficientStockException(
        productId: id,
        requested: quantity,
        available: product.stockQuantity,
      );
    }
    product.stockQuantity -= quantity;
  }

  void delete(String id) {
    if (!_products.containsKey(id)) {
      throw ProductNotFoundException(id);
    }
    _products.remove(id);
  }
}
