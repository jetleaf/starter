# Jetleaf Starter Projects Catalog

This directory contains real-world, runnable starter projects built entirely with the current **Jetleaf 2.1** framework and its ecosystem packages.

Unlike integration test suites, these projects are production-style architectural templates that developers and enterprise teams can clone, explore, and use as starting points for their own backend applications.

All projects resolve Jetleaf from **pub.dev** using version constraints in their `pubspec.yaml` files (for example `jetleaf: ^2.1.0`). No `dependency_overrides` are committed, so every project builds from a fresh clone.

To develop against unpublished framework changes, add local `path:` overrides temporarily (do not commit them), then re-run `dart pub get`. See [README.md](./README.md#dependency-model) for an example.

---

> **Known defects & behavior notes**: see [JETLEAF_FINDINGS.md](./JETLEAF_FINDINGS.md) — A1–A6 are the open backlog discovered building the two new projects; Part B lists what this cycle already fixed.

## 📦 Jetleaf Monorepo Packages Used

All projects in this workspace run on the current built packages:
* **`jetleaf`**: Application bootstrap, lifecycle management, profiles, environment cascading, graceful shutdown.
* **`jetleaf_core`**: Inversion of Control (IoC), typed scoped Pods, `@Configuration`, constructor dependency injection, `@EventListener`.
* **`jetleaf_tools`**: Developer CLI (`jl dev`, `jl run`, `jl test`), `JetleafVM` isolate pre-warming, sub-100ms hot reload.
* **`jetleaf_scheduling`**: Declarative cron/fixed-rate scheduling (`@Scheduled`, `@EnableScheduling`).
* **`jetleaf_actuator`**: Production monitoring and telemetry (`/actuator/health`, `/actuator/metrics`, `/actuator/info`).
* **`jetleaf_web`**: Declarative Web MVC, `@RestController`, `@RequestMapping`, `@GetMapping`, `@PostMapping`, parameter resolvers, `ResponseEntity`.
* **`jetleaf_retry`**: Declarative retries, `@Retryable`, exponential backoff policies, circuit breakers, `@Recover` handlers.
* **`jetleaf_validation`**: Hibernate-style constraint validation (`@Valid`, `@NotNull`, `@Size`, `@Email`, `@Min`, `@Max`).
* **`jetson`**: Ultra-fast JSON serialization, deserialization, and schema mappings.
* **`jtl`**: Jetleaf Template Language for server-side HTML rendering.

---

## 🚀 Projects Overview

| # | Project Directory | Focus Area | Packages Showcased |
|:---:|:---|:---|:---|
| **1** | [`ecommerce_catalog_api`](./ecommerce_catalog_api) | REST API & Deep Request Validation | `jetleaf`, `jetleaf_web`, `jetleaf_validation` |
| **2** | `resilient_webhook_forwarder` | Fault-Tolerant Webhooks & Retries | `jetleaf`, `jetleaf_web`, `jetleaf_retry` |
| **3** | `actuator_cloud_microservice` | Cloud-Native Metrics & K8s Probes | `jetleaf`, `jetleaf_web`, `jetleaf_actuator` |
| **4** | `multienv_saas_config` | Hierarchical Profiles & Typed Config | `jetleaf`, `jetleaf_web` |
| **5** | `event_driven_order_hub` | Decoupled Application Events & Listeners | `jetleaf`, `jetleaf_web` |
| **6** | `batch_etl_cron_cli` | Headless Batch Processing & Cron Jobs | `jetleaf` (`ApplicationType.NONE`) |
| **7** | `server_rendered_portal` | Server-Side Rendering (SSR) with JTL | `jetleaf`, `jetleaf_web` (includes `jtl`) |
| **8** | `fullstack_flutter_sync` | Full-Stack Dart Monorepo (Flutter + API) | `jetleaf`, `jetleaf_web`, `jetleaf_validation` |
| **9** | `advanced_ioc_lifecycle` | Advanced Scopes, Qualifiers & Hooks | `jetleaf`, `jetleaf_web` |
| **10** | `high_throughput_telemetry` | Fast JSON Parsing & Stream Chunking | `jetleaf`, `jetleaf_web`, `jetleaf_actuator` |
| **11** | `social_media` | Full Social Media Platform — full-stack framework tour | `jetleaf`, `jetleaf_web`, `jetleaf_validation`, `jetleaf_retry`, `jetleaf_scheduling`, `jetleaf_actuator`, `jetson`, `jtl` |
| **12** | `microservices` | Microservices Reference — gateway + 4 standalone services (workspace) | `jetleaf`, `jetleaf_web`, `jetleaf_retry`, `jetson` |

---

## Detailed Project Descriptions

### 1. `ecommerce_catalog_api`
* **Real-Life Use Case**: E-Commerce product catalog, shopping cart, and order placement REST service.
* **Key Features**:
  * `@RestController` routing with path parameters, query parameters, and JSON request bodies.
  * Multi-field payload validation using `jetleaf_validation` (`@Valid`, `@NotNull`, `@Size(min: 2)`, `@Email`, `@Min(1)`).
  * Constructor-injected services (`@Service`, `@Pod`).
  * Custom `@RestControllerAdvice` mapping domain exceptions (`ProductNotFoundException`, `InsufficientStockException`) to RFC 7807 problem details.

### 2. `resilient_webhook_forwarder`
* **Real-Life Use Case**: High-reliability webhook dispatcher forwarding payment or event notifications to third-party endpoints.
* **Key Features**:
  * Declarative `@Retryable` policies with exponential backoff on network failures.
  * `@Recover` fallback logic saving un-deliverable payloads to a dead-letter log.
  * In-memory idempotency cache preventing duplicate event delivery.

### 3. `actuator_cloud_microservice`
* **Real-Life Use Case**: Dockerized, Kubernetes-ready microservice demonstrating production observability and zero-downtime rollouts.
* **Key Features**:
  * Health inspection via `/actuator/health`, metrics via `/actuator/metrics`, and system info via `/actuator/info`.
  * Custom `HealthIndicator` pods (e.g. database ping, memory pressure monitor).
  * Kubernetes liveness and readiness endpoints (`/actuator/health/liveness`, `/actuator/health/readiness`).
  * Graceful shutdown signal handling (`SIGTERM`/`SIGINT`).

### 4. `multienv_saas_config`
* **Real-Life Use Case**: Multi-tenant SaaS backend demonstrating clean configuration across development, staging, and production.
* **Key Features**:
  * Cascading configuration files (`application.yaml`, `application-dev.yaml`, `application-prod.yaml`).
  * Type-safe property binding (`@ConfigurationProperties`, `@Value('${app.rate-limit.max-requests}')`).
  * Conditional pod activation via active profiles (`@Profile('dev')` vs `@Profile('prod')`).

### 5. `event_driven_order_hub`
* **Real-Life Use Case**: Order checkout pipeline where domain events decouple business logic from notifications, inventory, and analytics.
* **Key Features**:
  * Decoupled domain event dispatching via `ApplicationEventPublisher`.
  * Asynchronous event handling via `@EventListener`.
  * Separate listeners for audit logging, email delivery, and metrics without circular dependencies.

### 6. `batch_etl_cron_cli`
* **Real-Life Use Case**: Headless command-line ETL processor that imports records, validates data, and exports summaries on a schedule.
* **Key Features**:
  * Headless execution profile (`ApplicationType.NONE`) with zero HTTP server overhead.
  * `CommandLineRunner` entrypoint with CLI flag parsing.
  * `@Scheduled` periodic cron tasks for recurring data processing.

### 7. `server_rendered_portal`
* **Real-Life Use Case**: SEO-optimized developer portal, documentation browser, and dynamic web application.
* **Key Features**:
  * Server-Side Rendering (SSR) with the Jetleaf Template Language (`jtl`).
  * Template layout inheritance, partial includes, loops, and conditional blocks.
  * Form submission handling with server-side validation error rendering and static asset serving.

### 8. `fullstack_flutter_sync`
* **Real-Life Use Case**: Full-stack Dart architecture connecting a Flutter frontend to a Jetleaf backend.
* **Key Features**:
  * Shared Dart data models and DTOs in a shared package, eliminating serialization drift.
  * Unified type contracts between client and server.
  * CORS headers and web client compatibility.

### 9. `advanced_ioc_lifecycle`
* **Real-Life Use Case**: Reference architecture exploring the full depth of Jetleaf's IoC container.
* **Key Features**:
  * Singleton vs Prototype pod scopes.
  * Lazy initialization (`@Lazy`) vs eager pod startup.
  * Conflict resolution using `@Primary` and `@Qualifier`.
  * Priority execution chains using `@Order`.
  * Lifecycle callbacks: `@PostConstruct` and `@PreDestroy`.

### 10. `high_throughput_telemetry`
* **Real-Life Use Case**: Ingestion microservice receiving high-frequency sensor/telemetry payloads and streaming summaries.
* **Key Features**:
  * Ultra-fast JSON deserialization with `jetson`.
  * Chunked HTTP streaming responses.
  * Real-time isolate memory and throughput tracking using `jetleaf_actuator`.
### 11. `social_media`
* **Real-Life Use Case**: A production-style social media platform ("SocialPulse") that exercises the **entire Jetleaf 2.1 API surface** — built both to ship and to surface framework defects.
* **Key Features**:
  * REST API with RFC 7807 `application/problem+json` errors via `@RestControllerAdvice` (`@ExceptionHandler`).
  * Follower-driven timelines with an engagement-decay ranker; hashtags, mentions, reports → auto-suspension pipeline.
  * Domain events (`PostLikedEvent`, `CommentAddedEvent`…) with ordered `@EventListener` pods (notifications → moderation → analytics → audit).
  * `@Scheduled`/`@Cron` maintenance jobs, `@ConfigurationProperty` typed binding, `@Value` scalars, `@Primary`/`@Qualifier`/`@Lazy`/`@Scope('prototype')`, factory-method `@Pod` config with `@Conditional`, custom stereotypes.
  * SSR portal (JTL templates + layout composition), multipart avatar upload with magic-byte sniffing, NDJSON streaming export, in-memory token-bucket rate limiting filter, `OncePerRequestFilter` security filter (X-User identity + admin key).
  * Actuator-style endpoints (`/actuator/health|liveness|readiness|metrics|info`), `FeedStoreHealthIndicator` pattern, `@Monitor` performance tracking (dev profile).
  * Multi-profile config (`dev` seeds a demo workspace via `ApplicationRunner`; `prod` guard).
* **Run**: `jl dev` then `jl run lib/main.dart -- --jetleaf.profiles.active=dev` (port `8080`). See `README.md`.
* **Heads-up**: the app doubles as a defect hunt — it drives the full pipeline end-to-end (AOT registry generation, `ServerWebApplicationContext` web boot, `@Value` binding on factory parameters, argument type conversion). Several framework bugs were found & fixed along the way (see "Known notes").
* **AOP/AOT proxies are now verified end-to-end** — `ExternalPushClient` uses annotation-driven `@Retryable`/`@Recover`: the pod is substituted by a generated `$$JLInterfaced$$ExternalPushClient` proxy at post-processing time and every call routes through the interceptor dispatcher (attempts 1→2 retried through the proxy; on full exhaustion `@Recover` returned the drop-receipt and the listener logged it — verified via `jl dev` + HTTP traffic against `/api/posts/{id}/comments`).

### 12. `microservices`
* **Real-Life Use Case**: Reference for building microservice systems with Jetleaf 2.1 — four standalone apps in one Dart workspace + a gateway.
* **Key Features**:
  * Workspace with members `common` (shared HTTP client w/ programmatic retry + health primitives), `user_service`, `order_service`, `notification_service`, `gateway` — each with its own `@JetleafApplicationStarter`, `@ComponentScan` scope and port (`8081/8082/8083`, gateway `8080`).
  * API gateway: `/api/*` reverse proxy with retry + 503 envelope, BFF aggregate (`/api/aggregate/orders/{id}`) with degraded-mode fallback when downstream services fail, and `/api/health/cluster` fan-out probe.
  * Order flow validates customers over HTTP and publishes `OrderPlacedEvent` in-process; a listener relays the confirmation to the notification service (fire-and-forget with retry).
  * Static service discovery via `services.*.base-url` properties with profile cascade (`application-prod.yaml` disables notification delivery).
* **Run**: one `jl dev` per member, then `jl run bin/<service>.dart` for each (see `README.md`); verified end-to-end including the "notification-service down → order still accepted, cluster health degraded" drill.
* **Honest limits**: no config server, no registry/discovery client, no distributed tracing, no request/session pod scopes (as of 2.1.0). The programmatic `RetryExecutor` is still the right tool inside `ServiceHttpClient` (it is a plain call-site helper, not a pod, so annotation-driven interception never reaches it) — annotation-level `@Retryable` on pod-managed classes is verified working (see SocialPulse above).

---

## 🧭 Known notes on Jetleaf 2.1.0 (as shipped in this tree)

* `@Retryable`/`@Recover` are **not** inert anymore — `jl build` / `jl dev` emit `$$JLInterfaced$$` proxies for stereotype-annotated pods (root package only), the AOT registry registers them, and `DefaultMethodInterceptor` substitutes the proxy at post-processing. Verified end-to-end. Caveats: only members returning `Future`/`void` are interceptable; plain non-pod helpers get no interception (use the programmatic `RetryExecutor`); emitted code is auto-suppressed for lint.
* `@Cacheable`/`@RateLimit` work the same way — interception reaches them through pod proxies, not through classes that never get proxied.
* `@Scheduled` has no `initialDelay`; cron is 6-field (`sec min hour dom mon dow`).
* `@ConfigurationProperty` binds **exact** dot-case keys (`maxRequests`, not `max-requests`/kebab-case).
* `jetson` **strips empty lists/maps/nulls** from JSON output (tested, intentional) — clients must tolerate missing keys; response field names are serialized as `snake_case` while `@RequestBody Map bodies` are read as-sent.
* AOT registry (`jl build` → `lib/_jetleaf/`) is required for the web server to boot; plain `dart run` without the registrar runs a context with no HTTP server. With `bin/<app>.dart` passing `registerGeneratedArtifacts`, plain `dart run` works too.
* No request/session pod scope (`ScopeType` is SINGLETON/PROTOTYPE only); no `jetleaf_security` yet (bearer validation is userland).
* Plain `dart analyze` ignores generated code only if excluded — all starters exclude `**/_jetleaf*/**` (or `lib/_jetleaf*/**`) via `analysis_options.yaml`. Generated `_jetleaf/proxies/` **must** be included in analysis — they are valid Dart and analyzing them catches generator bugs; SocialPulse is at 0 issues including proxies.
* **Starter `pubspec.lock` drift breaks `jl dev` after analyzer migrations.** The starter workspaces (`social_media`, `microservices`, **and 9 other starters** — see `grep -l '"10.2.0"' */pubspec.lock`) pinned `analyzer 10.2.0` transitively before the analyzer-14 migration. The warm VM then compiles `jetleaf_tools` (which requires `analyzer ^14.7.0`) against 10.2.0 and dies with diagnostics like `BlockEnumBody isn't a type` / `No named parameter with the name 'inner'` — the manager reports only `vm exited 254`. Fix: re-run `dart pub get` in each affected starter workspace to re-resolve against current path deps.
* `jetleaf_tools`' generated entry stub (`jl dev`) used to import a non-existent deep path (`jetleaf_tools/src/runtime/scanner/...`) — every warm VM crashed at startup; it now uses the public `jetleaf_tools` API.
* AOT build tree-shaking previously pruned **every** proxy class (reachability ran on the pre-proxy file set) — fixed: the post-proxy re-scan feeds reachability. Proxy classes sharing one source file used to clobber each other's generated proxy file (41 emitted → 31 effective, classes like `HealthService` silently lost) — fixed: proxy file names now carry the class name. All AOT writers escape Dart string literals (`$$JLInterfaced$$` identifiers previously broke parsers).
* `LogFactory` `_isWarnEnabled`/`_isFatalEnabled`/`_isTraceEnabled` defaulted to **false**, silently suppressing WARN/FATAL/TRACE — WARN now defaults to on (consistent with DEBUG/INFO/ERROR).
