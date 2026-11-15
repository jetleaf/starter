import 'package:jetleaf/jetleaf.dart';
import 'package:actuator_cloud_microservice/src/health/database_health_indicator.dart';
import 'package:actuator_cloud_microservice/src/health/health_service.dart';
import 'package:actuator_cloud_microservice/src/health/memory_pressure_health_indicator.dart';

/// Registers the full set of health indicators and the [HealthService] facade.
@Configuration()
class HealthConfiguration {
  @Pod()
  HealthService healthService(
    DatabaseHealthIndicator db,
    MemoryPressureHealthIndicator memory,
  ) {
    return HealthService(db, memory);
  }
}
