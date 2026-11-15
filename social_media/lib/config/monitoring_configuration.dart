/// Dev-only performance monitoring wiring.
///
/// `@Monitor` on services (e.g. `PostService`) is only meaningful when a
/// `MonitoringService` pod exists — the package does not auto-register one.
/// This configuration does it for the dev profile so `@Monitor` is exercised
/// for real without adding per-pod overhead to production boots.
library;

import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_actuator/jetleaf_actuator.dart';

@Profile(['dev'])
@Configuration()
class MonitoringConfiguration {
  /// The default monitoring service — also implements [PodInstantiationProcessor],
  /// so pod creation timings flow into the performance reports.
  @Pod(value: 'jetleaf.monitor.monitoringService')
  MonitoringService monitoringService() => DefaultMonitoringService();
}
