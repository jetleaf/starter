/// Gateway actuator endpoints — gateway liveness, not cluster health.
library;

import 'package:jetleaf_web/jetleaf_web.dart';

import 'gateway_health.dart';

@RestController('/actuator')
class GatewayActuatorController {
  GatewayActuatorController(this._indicator);

  final GatewayHealthIndicator _indicator;

  @GetMapping(path: '/health')
  Future<Map<String, Object?>> health() async {
    final result = await _indicator.check();
    return {
      'status': result.status,
      'service': 'gateway',
      'indicators': {_indicator.name: result.toJson()},
    };
  }

  @GetMapping(path: '/liveness')
  Map<String, Object?> liveness() => {'status': 'UP'};

  @GetMapping(path: '/readiness')
  Future<Map<String, Object?>> readiness() async {
    final result = await _indicator.check();
    return {'status': result.status};
  }
}
