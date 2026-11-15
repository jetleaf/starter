import 'package:actuator_cloud_microservice/src/health/database_health_indicator.dart';
import 'package:actuator_cloud_microservice/src/health/health_service.dart';
import 'package:actuator_cloud_microservice/src/health/memory_pressure_health_indicator.dart';
import 'package:test/test.dart';

void main() {
  group('HealthService', () {
    test('aggregates results from provided indicators', () async {
      final db = DatabaseHealthIndicator();
      final memory = MemoryPressureHealthIndicator();

      final service = HealthService(db, memory);
      final report = await service.aggregate();

      expect(report['status'], 'UP');
      expect(report['readiness'], 'UP');
      final indicators = report['indicators'] as Map<String, Object?>;
      expect(indicators.keys, containsAll(['database', 'memory']));
    });

    test('reports memory indicator details', () async {
      final db = DatabaseHealthIndicator();
      final memory = MemoryPressureHealthIndicator();

      final service = HealthService(db, memory);
      final report = await service.aggregate();

      final memoryReport = (report['indicators'] as Map<String, Object?>)['memory'] as Map<String, Object?>;
      expect(memoryReport['status'], 'UP');
      expect((memoryReport['details'] as Map).keys, containsAll(['current_rss_mb', 'max_rss_mb']));
    });
  });
}
