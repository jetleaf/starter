# Jetleaf Microservices Reference

Four standalone Jetleaf apps that compose into a small e-commerce domain:

| Service | Purpose | Port |
|---|---|---|
| `gateway` | Public edge — proxies `/api/*` to the three backend services, aggregates order detail (BFF) and reports cluster health | `8080` |
| `user-service` | Customer directory (`/users`) | `8081` |
| `order-service` | Orders (`/orders`) — validates customers against user-service, publishes order events to notification-service | `8082` |
| `notification-service` | Notification inbox (`/notifications`) | `8083` |

Each service is a **separate Jetleaf application** with its own `@JetleafApplicationStarter`, its own port, and its own component-scan scope. There is no shared mutable state between them — they only communicate over HTTP exactly the way services would across a network boundary.

```text
                ┌────────────────────────────┐
                │          gateway             │   http://localhost:8080
                │  /api/*                    │
                │  /api/aggregate/orders/{id} │
                │  /api/health/cluster        │
                └──────┬──────┬───────────────┘
                       │      │
              ┌────────▼──┐ ┌─▼──────────┐ ┌──────────────────┐
              │user-service│ │order-service│ │notification-service│
              │   /users   │ │   /orders   │ │   /notifications   │
              └───────────┘ └─┬───────┬──┘ └──────────────────┘
                              │       │
                              │   (HTTP, retries 3× with backoff)
                              ▼       ▼
                        user-service  notification-service
```

### What this demonstrates

* **Multiple Jetleaf apps in one repository** — four independently booting processes, all compiled from one `pubspec.yaml` via workspace membership.
* **API gateway** — path-based reverse proxy with per-call retry and a 503 envelope on exhaustion, plus a BFF-style aggregation endpoint and a fan-out cluster-health probe.
* **Cross-service calls with retry** — order-service calls user-service before accepting an order, and notification-service after. Both use the programmatic `RetryExecutor` because `ServiceHttpClient` is a plain helper constructed at call sites, not a pod — Jetleaf's AOP annotation interception only substitutes pod-managed classes. (Annotation-level `@Retryable`/`@Recover` on pod-managed classes is verified working end-to-end — see `starter/social_media`.)
* **Domain events across the boundary** — order placement publishes `OrderPlacedEvent` in-process; a listener then relays a confirmation to notification-service over HTTP. Cross-service delivery is fire-and-forget with explicit retry, not the in-process event bus.
* **Per-service health/readiness/liveness** — every service exposes `/actuator/health`, `/actuator/liveness`, `/actuator/readiness`.
* **Configuration** — `application.yaml` holds `services.<name>.base-url` for discovery between services; profile cascades (`application-prod.yaml`) toggle notification delivery.

### What Jetleaf cannot do today (honest limits)

* **No service discovery/registration** — service addresses are static config (`services.*.base-url`); nothing auto-discovers or load-balances.
* **No config server** — configuration is per-process YAML + env vars; there is no central config service or runtime refresh.
* **No distributed tracing / metrics correlation** — no `traceparent` propagation or span export; correlation ids must be added by the app (see `RequestLoggingFilter` pattern in the social project).
* **No synchronous service mesh** — inter-service calls are plain HTTP with retries; there is no circuit-breaker dashboard, sidecar, or mTLS integration out of the box.
* **Annotation-level `@Retryable` only works on pod-managed classes** — `jl build` / `jl dev` emit `$$JLInterfaced$$` proxy classes for stereotype-annotated pods and the runtime substitutes them at post-processing time (verified end-to-end: a `@Retryable(maxAttempts: 3)` method on a `@Service` retried through the AOP pipeline and its `@Recover` fallback ran — see `starter/social_media/lib/service/external_push_client.dart`). Plain helper classes like `ServiceHttpClient` are not pod-managed, so annotation interception does not reach them; they must use the programmatic `RetryExecutor`.
* **Actuator endpoints are userland code** — `/actuator/health` here is a plain controller reusing the health-indicator pattern, not framework-provided.

### Run it

One Jetleaf workspace, so one command warms all four members per project directory — each member is its own `jl dev` manager:

```bash
cd common                && dart run ../../../jetleaf/libraries/jetleaf_tools/bin/jl.dart dev &
cd ../user_service       && dart run ../../../jetleaf/libraries/jetleaf_tools/bin/jl.dart dev &
cd ../order_service      && dart run ../../../jetleaf/libraries/jetleaf_tools/bin/jl.dart dev &
cd ../notification_service && dart run ../../../jetleaf/libraries/jetleaf_tools/bin/jl.dart dev &
cd ../gateway            && dart run ../../../jetleaf/libraries/jetleaf_tools/bin/jl.dart dev &

# once each manager prints "active ... pid=<pid>", trigger boot:
cd ../user_service       && dart run ../../../jetleaf/libraries/jetleaf_tools/bin/jl.dart run bin/user_service.dart
cd ../order_service      && dart run ../../../jetleaf/libraries/jetleaf_tools/bin/jl.dart run bin/order_service.dart
cd ../notification_service && dart run ../../../jetleaf/libraries/jetleaf_tools/bin/jl.dart run bin/notification_service.dart
cd ../gateway            && dart run ../../../jetleaf/libraries/jetleaf_tools/bin/jl.dart run bin/gateway.dart
```

**Note**: there is no `jl dev` manager rooted at the workspace root — each member app must be discovered from its own project directory. Plain `dart run bin/<service>.dart` does work (the entry passes `registerGeneratedArtifacts`) but takes minutes to scan on the JIT path; use `jl dev` + `jl run` for normal development.

### Exercise the API

```bash
# through the gateway
curl -s -X POST http://localhost:8080/api/users \
  -H 'content-type: application/json' \
  -d '{"handle":"ada2","displayName":"Ada Two"}'

curl -s -X POST http://localhost:8080/api/orders \
  -H 'content-type: application/json' \
  -d '{"customerId":"cus_ada","items":[{"sku":"JET-MUG-AOT","quantity":1,"unitPriceCents":1800}]}'

curl -s http://localhost:8080/api/aggregate/orders/ord_seed_ada_0001
curl -s http://localhost:8080/api/health/cluster
```

Direct service ports (all bind `localhost`/`[::1]`): `8081` (users), `8082` (orders), `8083` (notifications).

### Failure drills

* **Kill notification-service** (`jl stop`, or Ctrl-C its `jl run`) → order placement still succeeds; the confirmation is dropped and logged as a warning by the retry path.
* **Kill user-service** → the order endpoint rejects the order with `422 invalid_order` (customer unverifiable) — the gateway's customer-facing calls also return `503 service_unavailable`.

## Project layout

```text
bin/           entry points (one per service + gateway)
lib/
  gateway/     the API gateway (proxy routes, BFF aggregate, cluster health)
  user_service/
  order_service/
  notification_service/
  shared/      health primitives shared by all four services
resources/     application.yaml + profile overrides
```
