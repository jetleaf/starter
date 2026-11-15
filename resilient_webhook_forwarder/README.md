# 🔁 Resilient Webhook Forwarder

A high-reliability webhook dispatcher built with **Jetleaf**. Designed to showcase:

- `@RestController` and `@PostMapping` with typed request/response bodies (`jetleaf_web`).
- Declarative retries with `@Retryable` + exponential backoff (`jetleaf_retry`).
- `@Recover` fallback routing to a dead-letter queue.
- In-memory idempotency tracking (TTL-bounded) to drop duplicate deliveries.
- `ApplicationEventPublisher` style configuration (`jetleaf`, `jetleaf_core`).
- Lightweight `@Service` pods wired by the Jetleaf IoC container.

## Layout

```
lib/
  main.dart                    # @JetleafApplicationStarter entrypoint
  src/
    controllers/               # REST endpoints (POST /dispatch, /dead-letters, /health)
    services/                  # WebhookDeliveryService (retry + recover), IdempotencyService, DeadLetterService
    models/, dto/              # WebhookEvent + WebhookDispatchDto
    advice/                    # @RestControllerAdvice for structured error mapping
    exceptions/                # Typed domain exceptions
bin/
  debug_run.dart               # Debug entrypoint (prints registered pods)
resources/
  application.yaml             # Jetleaf runtime configuration
test/
  services/                    # IdempotencyService, DeadLetterService, RetryExecutor tests
```

## Running

```bash
cd starter/resilient_webhook_forwarder
pub get
jl build
jl dev                 # in one shell
jl test                # in another
```

Or with plain Dart:

```bash
pub get
dart test
```

### Manual dispatch

```bash
curl -X POST http://localhost:8080/api/v1/webhooks/dispatch \
  -H 'Content-Type: application/json' \
  -d '{"deliveryId":"evt-001","targetUrl":"https://example.com/hook","eventType":"payment.received","body":{"amount":42.0}}'
```
