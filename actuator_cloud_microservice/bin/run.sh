#!/bin/sh
# Run the actuator-cloud-microservice starter.
set -e
echo 'Starting actuator-cloud-microservice on :8080 ...'
echo 'Endpoints: /actuator/health | /actuator/health/liveness | /actuator/health/readiness | /actuator/metrics | /actuator/info'
dart run lib/main.dart
