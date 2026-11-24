# 🌡️ Actuator Cloud Microservice

A production-ready microservice starter with **Jetleaf Actuator**-friendly endpoints:

- `/actuator/health` — aggregate status of all registered health indicators (database, memory pressure)
- `/actuator/health/liveness` — Kubernetes liveness probe
- `/actuator/health/readiness` — Kubernetes readiness probe (signals traffic disable when DOWN)
- `/actuator/metrics` — RSS memory, Dart version, OS info
- `/actuator/info` — service metadata (name, version, description)

## Layout

```
lib/
  main.dart                     # @JetleafApplicationStarter entrypoint
  src/
    controllers/                # ActuatorController (/actuator/*)
    health/
      health_indicator_service.dart   # Contract abstraction
      database_health_indicator.dart  # Simulated SQL connectivity probe (pinged on every check)
      memory_pressure_health_indicator.dart  # Process-level RSS limit (default 1.8 GB)
      health_service.dart             # Aggregates all indicator pods
      indicator_result.dart           # Result record
bin/
  run.sh                        # Convenience launcher
resources/
  application.yaml
test/
  services/health_service_test.dart
```

## Running

```bash
cd starter/actuator_cloud_microservice
jl build
dart run lib/main.dart
```

## Probing

```bash
curl -s http://localhost:8080/actuator/health       | jq
curl -s http://localhost:8080/actuator/metrics      | jq
curl -s http://localhost:8080/actuator/info         | jq
curl -s http://localhost:8080/actuator/health/liveness  | jq
curl -s http://localhost:8080/actuator/health/readiness | jq
```

## Adding your own health indicator

1. Implement `HealthIndicatorService`:
   ```dart
   @Service()
   class RedisHealthIndicator implements HealthIndicatorService {
     @override
     String get name => 'redis';
     @override
     Future<IndicatorResult> check() async { /* ping redis */ }
   }
   ```
2. Done — `HealthService` discovers and aggregates all `@Service` pods
   implementing `HealthIndicatorService` automatically via list injection.
