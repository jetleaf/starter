import 'package:actuator_cloud_microservice/src/health/indicator_result.dart';

/// Contract for a pluggable health indicator.
abstract interface class HealthIndicatorService {
  String get name;
  Future<IndicatorResult> check();
}
