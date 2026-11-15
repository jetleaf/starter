import 'dart:async';

import 'package:jetleaf/jetleaf.dart';
import 'package:actuator_cloud_microservice/src/health/database_health_indicator.dart';
import 'package:actuator_cloud_microservice/src/health/health_indicator_service.dart';
import 'package:actuator_cloud_microservice/src/health/memory_pressure_health_indicator.dart';
import 'package:actuator_cloud_microservice/src/health/indicator_result.dart';

/// Aggregates the results from a list of [HealthIndicatorService]s.
/// Constructed by the container via the [HealthConfiguration] pod factory.
class HealthService {
  static final Log _logger = LogFactory.getLog(HealthService);

  final DatabaseHealthIndicator _db;
  final MemoryPressureHealthIndicator _memory;
  bool readinessUp = true;

  HealthService(this._db, this._memory);

  /// Runs all registered indicators and returns a combined result.
  Future<Map<String, Object?>> aggregate() async {
    final indicators = <String, HealthIndicatorService>{
      'database': _db,
      'memory': _memory,
    };

    final results = <String, IndicatorResult>{};
    await Future.wait(
      indicators.entries.map((entry) async {
        try {
          results[entry.key] = await entry.value.check();
        } catch (error, st) {
          _logger.error('Health indicator ${entry.key} failed: $error', error: error, stacktrace: st);
          results[entry.key] = IndicatorResult(
            status: 'DOWN',
            duration: Duration.zero,
            details: {'error': error.toString()},
          );
        }
      }),
    );

    final allUp = results.values.every((r) => r.isUp);
    return {
      'status': allUp && readinessUp ? 'UP' : 'DOWN',
      'readiness': readinessUp ? 'UP' : 'DOWN',
      'indicators': results.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  /// Forces readiness off and back on for testing.
  void setReadiness(bool value) => readinessUp = value;
}
