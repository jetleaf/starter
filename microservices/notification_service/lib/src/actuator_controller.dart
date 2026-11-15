/// Notification-service actuator endpoints — health, liveness, readiness.
library;

import 'package:jetleaf_web/jetleaf_web.dart';

import 'notification_health.dart';

@RestController('/actuator')
class NotificationActuatorController {
  NotificationActuatorController(this._indicator);

  final NotificationStoreHealthIndicator _indicator;

  @GetMapping(path: '/health')
  Future<Map<String, Object?>> health() async {
    final result = await _indicator.check();
    return {
      'status': result.status,
      'service': 'notification',
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
