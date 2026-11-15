import 'package:jetleaf_validation/jetleaf_validation.dart';

/// Request payload for adding a product line item to a cart.
final class AddToCartDto {
  @NotBlank(message: 'Product ID is required')
  final String productId;

  @Min(1, message: 'Quantity must be at least 1')
  final int quantity;

  AddToCartDto({
    required this.productId,
    required this.quantity,
  });

  factory AddToCartDto.fromJson(Map<String, dynamic> json) => AddToCartDto(
    productId: (json['productId'] as String?)?.trim() ?? '',
    quantity: (json['quantity'] as int?) ?? 1,
  );
}
