import 'dart:async';

import 'package:jetleaf/jetleaf.dart';
import 'package:actuator_cloud_microservice/src/health/health_indicator_service.dart';
import 'package:actuator_cloud_microservice/src/health/indicator_result.dart';

/// Simulates a database connectivity probe (typical business dependency).
@Service()
class DatabaseHealthIndicator implements HealthIndicatorService {
  /// In a real service, inject the data source and run a trivial query
  /// like `SELECT 1`. This starter uses a counter to demonstrate
  /// intermittent failures and keeps a stable `UP` default.
  int _successfulPings = 0;

  @override
  String get name => 'database';

  @override
  Future<IndicatorResult> check() async {
    final stopwatch = Stopwatch()..start();
    await Future<void>.delayed(const Duration(milliseconds: 3));
    _successfulPings++;
    stopwatch.stop();

    return IndicatorResult(
      status: 'UP',
      duration: stopwatch.elapsed,
      details: {
        'successful_pings': _successfulPings,
        'dialect': 'in-memory',
      },
    );
  }
}
