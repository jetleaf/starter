import 'dart:io';

import 'package:jetleaf_web/jetleaf_web.dart';

import '../health/health_service.dart';

/// REST controller exposing actuator health and info endpoints.
@RestController('/actuator')
class ActuatorController {
  final HealthService _health;

  ActuatorController(this._health);

  /// Aggregate status of all health indicators.
  @GetMapping(path: '/health')
  Future<Map<String, Object?>> health() async {
    final report = await _health.aggregate();
    return {
      'application': 'actuator-cloud-microservice',
      ...report,
    };
  }

  /// Liveness probe — Kubernetes liveness probe endpoint.
  @GetMapping(path: '/health/liveness')
  Future<Map<String, Object?>> liveness() => Future.value({
        'status': 'UP',
        'probe': 'liveness',
      });

  /// Readiness probe — Kubernetes readiness probe endpoint.
  @GetMapping(path: '/health/readiness')
  Future<Map<String, Object?>> readiness() async {
    final report = await _health.aggregate();
    final up = report['readiness'] == 'UP';
    return {
      'status': up ? 'UP' : 'DOWN',
      'probe': 'readiness',
      'indicators': report['indicators'],
    };
  }

  /// Metrics snapshot of the running process.
  @GetMapping(path: '/metrics')
  Map<String, Object?> metrics() => {
        'memory_rss_mb': _rssMb(),
        'dart_version': Platform.version,
        'os': Platform.operatingSystem,
      };

  /// Informational metadata about the service.
  @GetMapping(path: '/info')
  Map<String, Object?> info() => {
        'application': 'actuator-cloud-microservice',
        'version': '1.0.0',
        'description': 'Production-ready cloud service starter with actuator endpoints.',
        'jetleaf_version': '2.1.0',
      };

  double _rssMb() {
    try {
      return ProcessInfo.currentRss / (1024 * 1024);
    } catch (_) {
      return 0;
    }
  }
}
