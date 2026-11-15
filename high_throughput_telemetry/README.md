# 📡 High-Throughput Telemetry

A telemetry ingestion microservice showing how Jetleaf handles high-frequency
sensor/event payloads with rolling aggregates, live rates and chunked streaming.

## What it does

- `POST /api/v1/telemetry/ingest` — batch-ingest `{ "events": [...] }`;
  malformed events are skipped, well-formed ones fold into rolling per-device
  aggregates
- `GET /api/v1/telemetry/summary` — totals + per-device `{ count, min, max, avg, last, lastSeen }`
- `GET /api/v1/telemetry/rate` — trailing one-minute window rate (events/s) and total ingested
- `GET /api/v1/telemetry/stream` — **chunked NDJSON stream** (`text/event-stream`);
  writes per-chunk to the socket with an explicit `flush()` per chunk, closing
  with a terminal `0\r\n\r\n` marked by the handler

## Layout

```
lib/
  main.dart                              # @JetleafApplicationStarter entrypoint
  src/telemetry/models.dart              # TelemetryEvent + MetricAggregate (pure)
  src/services/ingestion_service.dart    # thread-safe rolling aggregation + sliding window
  src/controllers/telemetry_controller.dart
bin/
test/services/ingestion_service_test.dart
```

## JSON shapes

**Ingest**
```bash
curl -X POST -H 'Content-Type: application/json' \
  -d '{"events":[
    {"deviceId":"edge-1","metric":"temperature","value":21.5},
    {"deviceId":"edge-2","metric":"humidity","value":48.0}
  ]}' \
  http://localhost:8080/api/v1/telemetry/ingest
# => { "accepted": 2, "total_ingested": 2 }
```

**Stream**
```bash
curl -N http://localhost:8080/api/v1/telemetry/stream
# data: {"type":"totals", "totalIngested":2, ...}
# data: {"type":"device","deviceId":"edge-1","metrics":{"temperature":{...}}}
# data: {"type":"device","deviceId":"edge-2","metrics":{"humidity":{...}}}
# data: {"type":"end","devices":2}
```

## Notes on streaming in Jetleaf

- A handler that writes directly to `ServerHttpResponse` and flushes per chunk
  is the supported pattern for incremental responses.
- Once a response is **committed** (first flush), the framework's void
  return-value handler does not auto-close the body — the handler owns
  closing (`await out.close()`) so the terminal chunked-transfer marker is
  released to the client.
- Use `curl -N` (or an EventSource client) to consume the stream.

## Tests

```bash
dart test
```
