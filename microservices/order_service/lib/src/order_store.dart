/// In-memory order store with one seeded order for `cus_ada`.
library;

import 'package:jetleaf/jetleaf.dart';

import 'order.dart';

@Repository()
class OrderStore {
  OrderStore() {
    _orders['ord_seed_ada_0001'] = PurchaseOrder(
      id: 'ord_seed_ada_0001',
      customerId: 'cus_ada',
      items: [
        OrderItem(sku: 'JET-HOODIE-EMERALD', quantity: 1, unitPriceCents: 6500),
        OrderItem(sku: 'JET-MUG-AOT', quantity: 2, unitPriceCents: 1800),
      ],
      status: OrderStatus.confirmed,
      createdAt: DateTime.now().toUtc().subtract(const Duration(days: 6)),
      customerHandle: 'ada',
      customerTier: 'gold',
    );
  }

  final Map<String, PurchaseOrder> _orders = {};

  PurchaseOrder? findById(String id) => _orders[id];

  List<PurchaseOrder> findAll() => List.unmodifiable(_orders.values);

  Future<PurchaseOrder> save(PurchaseOrder order) async {
    _orders[order.id] = order;
    return order;
  }

  int get count => _orders.length;
}
