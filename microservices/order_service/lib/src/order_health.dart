/// Order-store health indicator — reports order store state.
library;

import 'package:jetleaf/jetleaf.dart';
import 'package:microservices_common/microservices_common.dart';

import 'order_store.dart';

@Service()
class OrderStoreHealthIndicator {
  OrderStoreHealthIndicator(this._orders);

  final OrderStore _orders;

  String get name => 'order-store';

  Future<IndicatorResult> check() async {
    final stopwatch = Stopwatch()..start();
    final count = _orders.count;
    stopwatch.stop();
    return IndicatorResult(
      status: 'UP',
      duration: stopwatch.elapsed,
      details: {'orders': count, 'backend': 'in-memory'},
    );
  }
}
