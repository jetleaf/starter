import 'package:test/test.dart';

import 'package:high_throughput_telemetry/src/services/ingestion_service.dart';

void main() {
  group('IngestionService', () {
    late IngestionService service;

    setUp(() => service = IngestionService());

    test('ingestBatch accepts well-formed events', () {
      final accepted = service.ingestBatch([
        {'deviceId': 'edge-1', 'metric': 'temperature', 'value': 21.5},
        {'deviceId': 'edge-1', 'metric': 'temperature', 'value': 22.0},
        {'deviceId': 'edge-2', 'metric': 'humidity', 'value': 45.0},
      ]);
      expect(accepted, 3);
      expect(service.totalIngested, 3);
    });

    test('ingestBatch skips malformed events', () {
      final accepted = service.ingestBatch([
        {'deviceId': '', 'metric': 'temperature', 'value': 1.0},
        {'deviceId': 'edge-1', 'metric': '', 'value': 2.0},
        {'deviceId': 'edge-1', 'metric': 'temperature', 'value': 3.0},
      ]);
      expect(accepted, 1);
    });

    test('aggregates compute count/sum/min/max/avg per device and metric', () {
      service.ingestBatch([
        {'deviceId': 'edge-1', 'metric': 'temperature', 'value': 10.0},
        {'deviceId': 'edge-1', 'metric': 'temperature', 'value': 20.0},
        {'deviceId': 'edge-1', 'metric': 'temperature', 'value': 30.0},
      ]);

      final summary = service.summary();
      final device = (summary['devices'] as Map)['edge-1'] as Map;
      final temp = device['temperature'] as Map;
      expect(temp['count'], 3);
      expect(temp['min'], 10.0);
      expect(temp['max'], 30.0);
      expect(temp['avg'], 20.0);
      expect(temp['last'], 30.0);
    });

    test('recentEvents tracks the trailing window', () {
      service.ingestBatch([
        {'deviceId': 'edge-1', 'metric': 'temperature', 'value': 1.0},
        {'deviceId': 'edge-1', 'metric': 'temperature', 'value': 2.0},
      ]);
      expect(service.recentEvents, 2);
      expect(service.eventsPerSecond, closeTo(2 / 60, 0.0001));
    });
  });
}
