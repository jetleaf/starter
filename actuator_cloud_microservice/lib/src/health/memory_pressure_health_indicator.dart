import 'dart:async';
import 'dart:io';

import 'package:jetleaf/jetleaf.dart';
import 'package:actuator_cloud_microservice/src/health/health_indicator_service.dart';
import 'package:actuator_cloud_microservice/src/health/indicator_result.dart';

/// Reports a `DOWN` status when the process RSS exceeds the configured cap.
@Service()
class MemoryPressureHealthIndicator implements HealthIndicatorService {
  /// Fails liveness when the process RSS exceeds this many MB.
  final double maxRssMb;

  MemoryPressureHealthIndicator({this.maxRssMb = 1800.0});

  @override
  String get name => 'memory';

  @override
  Future<IndicatorResult> check() async {
    final stopwatch = Stopwatch()..start();
    final rssBytes = ProcessInfo.currentRss;
    final rssMb = rssBytes / (1024 * 1024);
    stopwatch.stop();

    final status = rssMb > maxRssMb ? 'DOWN' : 'UP';
    return IndicatorResult(
      status: status,
      duration: stopwatch.elapsed,
      details: {
        'current_rss_mb': rssMb,
        'max_rss_mb': maxRssMb,
      },
    );
  }
}
