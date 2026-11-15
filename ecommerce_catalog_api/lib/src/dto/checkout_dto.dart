import 'package:jetleaf_validation/jetleaf_validation.dart';

/// Request payload for checking out an order.
final class CheckoutDto {
  @NotBlank(message: 'Customer email is required')
  @Email(message: 'Invalid email address format')
  final String customerEmail;

  @NotBlank(message: 'Shipping address is required')
  @Size(min: 5, max: 200, message: 'Shipping address must be between 5 and 200 characters')
  final String shippingAddress;

  CheckoutDto({
    required this.customerEmail,
    required this.shippingAddress,
  });

  factory CheckoutDto.fromJson(Map<String, dynamic> json) => CheckoutDto(
    customerEmail: (json['customerEmail'] as String?)?.trim() ?? '',
    shippingAddress: (json['shippingAddress'] as String?)?.trim() ?? '',
  );
}
