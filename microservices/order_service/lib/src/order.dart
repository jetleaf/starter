/// Order aggregate for the order service.
library;

enum OrderStatus { pending, confirmed, cancelled }

class OrderItem {
  OrderItem({required this.sku, required this.quantity, required this.unitPriceCents});

  final String sku;
  final int quantity;
  final int unitPriceCents;

  int get totalCents => quantity * unitPriceCents;

  Map<String, dynamic> toJson() => {
        'sku': sku,
        'quantity': quantity,
        'unitPriceCents': unitPriceCents,
        'totalCents': totalCents,
      };

  static OrderItem fromJson(Map<String, dynamic> json) => OrderItem(
        sku: json['sku'] as String,
        quantity: (json['quantity'] as num).toInt(),
        unitPriceCents: (json['unitPriceCents'] as num).toInt(),
      );
}

class PurchaseOrder {
  PurchaseOrder({
    required this.id,
    required this.customerId,
    required this.items,
    required this.status,
    required this.createdAt,
    this.customerHandle,
    this.customerTier,
  });

  final String id;
  final String customerId;
  final List<OrderItem> items;
  OrderStatus status;
  final DateTime createdAt;

  /// Populated from the user service at write time when reachable.
  String? customerHandle;
  String? customerTier;

  int get totalCents => items.fold(0, (sum, item) => sum + item.totalCents);

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        if (customerHandle != null) 'customerHandle': customerHandle,
        if (customerTier != null) 'customerTier': customerTier,
        'items': [for (final i in items) i.toJson()],
        'totalCents': totalCents,
        'status': status.name,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  static PurchaseOrder fromJson(Map<String, dynamic> json) => PurchaseOrder(
        id: json['id'] as String,
        customerId: json['customerId'] as String,
        items: ((json['items'] as List<dynamic>?) ?? const [])
            .map((i) => OrderItem.fromJson((i as Map).cast<String, dynamic>()))
            .toList(),
        status: OrderStatus.values.byName((json['status'] as String?) ?? 'pending'),
        createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
        customerHandle: json['customerHandle'] as String?,
        customerTier: json['customerTier'] as String?,
      );
}
