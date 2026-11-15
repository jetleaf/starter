import 'dart:convert';

import 'package:jetleaf_web/jetleaf_web.dart';

import '../services/ingestion_service.dart';

/// Telemetry ingestion and introspection API.
@RestController('/api/v1/telemetry')
class TelemetryController {
  final IngestionService _ingestion;

  TelemetryController(this._ingestion);

  /// Ingests a batch of telemetry events.
  /// Body: `{"events": [{"deviceId": "edge-1", "metric": "temperature", "value": 21.5}]}`
  @PostMapping(path: '/ingest')
  ResponseBody<Map<String, Object?>> ingest(@RequestBody() Map<String, dynamic> body) {
    final rawEvents = (body['events'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final accepted = _ingestion.ingestBatch(rawEvents);
    return ResponseBody.of(HttpStatus.CREATED, {
      'accepted': accepted,
      'totalIngested': _ingestion.totalIngested,
    });
  }

  /// Rolling per-device aggregates and ingest throughput.
  @GetMapping(path: '/summary')
  Map<String, Object?> summary() => _ingestion.summary();

  /// Throughput snapshot (events in the trailing minute).
  @GetMapping(path: '/rate')
  Map<String, Object?> rate() => {
        'recentEventsPerMinute': _ingestion.recentEvents,
        'eventsPerSecond': _ingestion.eventsPerSecond,
        'totalIngested': _ingestion.totalIngested,
      };

  /// Streams the current summary as newline-delimited JSON chunks.
  /// Writes directly to the response body — true chunked streaming,
  /// not a buffered payload.
  @GetMapping(path: '/stream', produces: [MediaType('text', 'event-stream')])
  Future<void> stream(ServerHttpResponse response) async {
    response.setStatus(HttpStatus.OK);
    response.getHeaders().setContentType(const MediaType('text', 'event-stream'));

    final out = response.getBody();
    Future<void> writeChunk(Map<String, Object?> payload) async {
      final line = 'data: ${jsonEncode(payload)}\n\n';
      await out.writeString(line);
      await out.flush();
    }

    final devices = _ingestion.summary();
    // chunk 1: totals
    await writeChunk({'type': 'totals', ...devices});
    // chunk 2: one chunk per device
    final byDevice = (devices['devices'] as Map?) ?? const {};
    for (final entry in byDevice.entries) {
      await writeChunk({'type': 'device', 'deviceId': entry.key, 'metrics': entry.value});
    }
    // chunk 3: end marker
    await writeChunk({'type': 'end', 'devices': byDevice.length});

    // A committed response is never auto-closed by the void return-value
    // handler, so the handler closes the body itself — that flush is what
    // releases the terminal chunked-transfer marker to the client.
    await out.close();
  }
}
