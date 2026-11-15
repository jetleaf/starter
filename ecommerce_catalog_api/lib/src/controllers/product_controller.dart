import 'package:jetleaf_web/jetleaf_web.dart';

import '../dto/create_product_dto.dart';
import '../services/product_service.dart';

/// REST API controller exposing product catalog operations.
@RestController('/api/v1/products')
class ProductController {
  final ProductService _productService;

  ProductController(this._productService);

  /// Lists all products with optional category and search query filters.
  @GetMapping()
  List<Map<String, dynamic>> listProducts(
    @RequestParam(value: 'category', required: false) String? category,
    @RequestParam(value: 'search', required: false) String? search,
  ) {
    final products = _productService.getAll(category: category, search: search);
    return products.map((p) => p.toJson()).toList();
  }

  /// Retrieves a specific product by unique ID.
  @GetMapping(path: '/{id}')
  Map<String, dynamic> getProduct(
    @PathVariable(value: 'id') String id,
  ) {
    return _productService.getById(id).toJson();
  }

  /// Creates and registers a new product in the store catalog.
  @PostMapping()
  ResponseBody<Map<String, dynamic>> createProduct(
    @RequestBody() Map<String, dynamic> body,
  ) {
    final dto = CreateProductDto.fromJson(body);
    final product = _productService.create(dto);
    return ResponseBody.of(HttpStatus.CREATED, product.toJson());
  }

  /// Removes a product from the catalog.
  @DeleteMapping(path: '/{id}')
  Map<String, dynamic> deleteProduct(
    @PathVariable(value: 'id') String id,
  ) {
    _productService.delete(id);
    return {'message': 'Product deleted successfully', 'id': id};
  }
}
