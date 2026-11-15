/// Customer aggregate for the user service.
library;

enum CustomerTier { standard, gold, platinum }

class Customer {
  Customer({
    required this.id,
    required this.handle,
    required this.displayName,
    required this.email,
    this.tier = CustomerTier.standard,
  });

  final String id;
  final String handle;
  final String displayName;
  final String email;
  CustomerTier tier;

  Map<String, dynamic> toJson() => {
        'id': id,
        'handle': handle,
        'displayName': displayName,
        'email': email,
        'tier': tier.name,
      };

  static Customer fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as String,
        handle: json['handle'] as String,
        displayName: json['displayName'] as String,
        email: json['email'] as String,
        tier: CustomerTier.values.byName((json['tier'] as String?) ?? 'standard'),
      );
}
