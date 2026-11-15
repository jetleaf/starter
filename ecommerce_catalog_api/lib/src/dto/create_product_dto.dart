import 'package:jetleaf_validation/jetleaf_validation.dart';

/// Request payload for creating or registering a new product.
final class CreateProductDto {
  @NotBlank(message: 'Product name must not be blank')
  @Size(min: 3, max: 100, message: 'Product name must be between 3 and 100 characters')
  final String name;

  @NotBlank(message: 'Description must not be blank')
  final String description;

  @Positive(message: 'Price must be greater than zero')
  final double price;

  @Min(0, message: 'Stock quantity cannot be negative')
  final int stockQuantity;

  @NotBlank(message: 'Category must not be blank')
  final String category;

  CreateProductDto({
    required this.name,
    required this.description,
    required this.price,
    required this.stockQuantity,
    required this.category,
  });

  factory CreateProductDto.fromJson(Map<String, dynamic> json) => CreateProductDto(
    name: (json['name'] as String?)?.trim() ?? '',
    description: (json['description'] as String?)?.trim() ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    stockQuantity: (json['stockQuantity'] as int?) ?? 0,
    category: (json['category'] as String?)?.trim() ?? 'General',
  );
}
