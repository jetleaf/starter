# 🛒 Event-Driven Order Hub

A Jetleaf starter showing **decoupled, event-driven communication** between
an in-memory checkout pipeline and pluggable event listeners.

- `OrderService` publishes domain events to the application context:
  `OrderPlacedEvent` → `OrderProcessedEvent` → `OrderNotifiedEvent`.
- Two independent `@EventListener` pods react to those events:
  - **AuditLogListener** — appends entries to an in-memory audit trail.
  - **NotificationListener** — prints simulated customer emails.
- The REST API exposes the pipeline, the audit trail and the notification log.

## Layout

```
lib/
  main.dart                       # @JetleafApplicationStarter entrypoint
  src/
    controllers/order_controller.dart       # /api/v1/orders | /api/v1/audit | /api/v1/notifications
    services/order_service.dart             # Store + event publication
    events/orders_event.dart                # ApplicationEvent subclasses
    listeners/audit_log_listener.dart       # @EventListener → audit log
    listeners/notification_listener.dart    # @EventListener → notifications
    advice/order_advice.dart                # @RestControllerAdvice → 404 / 400 problem details
    exceptions/order_exceptions.dart
resources/application.yaml
test/services/order_service_test.dart
```

## API

| Method | Path                          | Description                                   |
|--------|-------------------------------|-----------------------------------------------|
| GET    | /api/v1/orders                | List all orders                                |
| GET    | /api/v1/orders/{id}           | Fetch order (404 via advice if missing)        |
| POST   | /api/v1/orders                | Place order (201) + publishes OrderPlacedEvent |
| POST   | /api/v1/orders/{id}/process   | Mark PROCESSED + publishes OrderProcessedEvent |
| POST   | /api/v1/orders/{id}/notify    | Stamp notifiedAt + publishes OrderNotifiedEvent|
| GET    | /api/v1/audit                 | Entries recorded by AuditLogListener           |
| GET    | /api/v1/notifications         | Messages recorded by NotificationListener      |

## Running

```bash
cd starter/event_driven_order_hub
jl build
dart run lib/main.dart
```

## Try it

```bash
curl -s -X POST -H 'Content-Type: application/json' \
  -d '{"customerId":"cus-ada","total":245.50,"items":["Jetleaf Pro Mechanical Keyboard"]}' \
  http://localhost:8080/api/v1/orders

curl -s -X POST http://localhost:8080/api/v1/orders/order-003/process
curl -s -X POST http://localhost:8080/api/v1/orders/order-003/notify
curl -s http://localhost:8080/api/v1/audit
curl -s http://localhost:8080/api/v1/notifications
```

## Event flow

```text
placeOrder() ── OrderPlacedEvent ──► AuditLogListener.onOrderPlaced
                                └──► NotificationListener.onOrderPlaced
processOrder() ─ OrderProcessedEvent ─► AuditLogListener.onOrderProcessed
                                  └──► NotificationListener.onOrderProcessed
notifyOrder() ── OrderNotifiedEvent ──► AuditLogListener.onOrderNotified
                                  └──► NotificationListener.onOrderNotified
```

Listeners never call the pipeline — everything is wired through the
application context's event bus, so either listener can be added or removed
without touching `OrderService`.
