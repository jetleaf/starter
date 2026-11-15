/// Represents an item in the e-commerce store catalog.
final class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  int stockQuantity;
  final String category;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stockQuantity,
    required this.category,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'stockQuantity': stockQuantity,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    name: json['name'] as String,
    description: (json['description'] as String?) ?? '',
    price: (json['price'] as num).toDouble(),
    stockQuantity: json['stockQuantity'] as int,
    category: (json['category'] as String?) ?? 'General',
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
  );
}
