/// Gateway health indicator — reports gateway liveness to ops.
library;

import 'package:jetleaf/jetleaf.dart';
import 'package:microservices_common/microservices_common.dart';

@Service()
class GatewayHealthIndicator {
  String get name => 'gateway';

  Future<IndicatorResult> check() async {
    final stopwatch = Stopwatch()..start();
    stopwatch.stop();
    return IndicatorResult(
      status: 'UP',
      duration: stopwatch.elapsed,
      details: const {'component': 'gateway'},
    );
  }
}
