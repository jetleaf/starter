/// In-memory customer store with deterministic seed data.
library;

import 'package:jetleaf/jetleaf.dart';

import 'customer.dart';

@Repository()
class UserStore {
  UserStore() {
    _customers['cus_ada'] = Customer(
      id: 'cus_ada',
      handle: 'ada',
      displayName: 'Ada Okoye',
      email: 'ada@example.dev',
      tier: CustomerTier.gold,
    );
    _customers['cus_chidi'] = Customer(
      id: 'cus_chidi',
      handle: 'chidi',
      displayName: 'Chidi Nwosu',
      email: 'chidi@example.dev',
      tier: CustomerTier.standard,
    );
  }

  final Map<String, Customer> _customers = {};

  Customer? findById(String id) => _customers[id];

  List<Customer> findAll() => List.unmodifiable(_customers.values);

  Future<Customer> save(Customer customer) async {
    _customers[customer.id] = customer;
    return customer;
  }

  int get count => _customers.length;
}
