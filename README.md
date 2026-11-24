# Jetleaf Starter Projects

A collection of twelve runnable, production-style backend examples built with **Jetleaf 2.1**.
Each project is a standalone Dart application (or a small pub workspace) that demonstrates a
different slice of the framework — from a single REST endpoint to a four-service microservice
fleet.

Use them as:

- **Templates** — copy one as the starting point for a real service.
- **Reference material** — see how a specific Jetleaf feature is wired in a realistic app.
- **Smoke tests** — exercise the framework end to end after a Jetleaf upgrade.

> **Further reading**
> - [Projects.md](./Projects.md) — the full catalog, detailed feature descriptions, and API notes.
> - [JETLEAF_FINDINGS.md](./JETLEAF_FINDINGS.md) — framework defects and the verification backlog discovered while building these starters.

---

## Requirements

| Tool | Version |
| :--- | :--- |
| Dart SDK | `^3.9.0` (see each `pubspec.yaml`) |
| `jetleaf_tools` (`jl` CLI) | installed globally, or use the repo-local `jetleaf_tools/bin/jl.dart` |
| Optional | `curl` / `jq` for the sample requests below |

Most web examples listen on `http://localhost:8080` (Jetleaf binds IPv6 by default, so
`http://[::1]:8080` also works). The microservices workspace uses `8080` for the gateway and
`8081`–`8083` for the services.

---

## Quick start

```bash
cd starter/<project>

# 1. Fetch packages from pub.dev.
dart pub get

# 2. Generate the AOT registry (required for a full web boot).
jl build

# 3. Warm the VM and run the entrypoint.
jl dev                       # leave this running in one shell
jl run lib/main.dart         # in a second shell
```

For projects whose entrypoint is in `bin/`, pass that file instead, for example
`jl run bin/social_media.dart`. Several projects also ship a `bin/run.sh` shortcut. For a plain
`dart run <entry>` without `jl`, the entry must pass `registerGeneratedArtifacts` to
`JetleafApplication.run(...)`; otherwise Jetleaf falls back to a non-web context and no port is
bound. See [Troubleshooting](#troubleshooting).

---

## Dependency model

Every starter declares published Jetleaf versions in `pubspec.yaml` (for example
`jetleaf: ^2.1.0`, `jetleaf_web: ^2.1.0`) with **no committed `dependency_overrides`**. They
therefore resolve from pub.dev and work from a fresh clone.

If you are developing against unpublished changes in a sibling `jetleaf/` checkout, add
overrides locally (they are intentionally not committed):

```yaml
dependency_overrides:
  jetleaf:
    path: ../../jetleaf
  jetleaf_core:
    path: ../../jetleaf/libraries/jetleaf_core
  jetleaf_web:
    path: ../../jetleaf/packages/jetleaf_web
  # ...add only the packages your project needs
```

Then re-run `dart pub get` in that project. Some per-project READMEs still show commands using
the repo-local `dart run ../../jetleaf/libraries/jetleaf_tools/bin/jl.dart` — substitute your
installed `jl` when using published packages.

The `microservices/` directory is a pub workspace (`common`, `gateway`, `user_service`,
`order_service`, `notification_service`). Its members share dependencies; run `dart pub get`
from the workspace root.

---

## Project catalog

| # | Project | What it demonstrates | Entry point |
|:--:|:---|:---|:---|
| 1 | [`ecommerce_catalog_api`](./ecommerce_catalog_api) | REST catalog/cart/checkout API, deep validation, RFC 7807 error advice | `lib/main.dart` |
| 2 | [`resilient_webhook_forwarder`](./resilient_webhook_forwarder) | `@Retryable` backoff, `@Recover` dead-letter fallback, idempotency | `lib/main.dart` |
| 3 | [`actuator_cloud_microservice`](./actuator_cloud_microservice) | `/actuator/*` health, metrics, info, Kubernetes probes, graceful shutdown | `lib/main.dart` |
| 4 | [`multienv_saas_config`](./multienv_saas_config) | Cascading profile YAML, typed property binding, profile-gated pods | `lib/main.dart` |
| 5 | [`event_driven_order_hub`](./event_driven_order_hub) | `ApplicationEventPublisher`, `@EventListener`, decoupled audit/notify/metrics | `lib/main.dart` |
| 6 | [`batch_etl_cron_cli`](./batch_etl_cron_cli) | Headless `ApplicationType.NONE`, `CommandLineRunner`, cron ETL jobs | `bin/batch_etl_cron_cli.dart` |
| 7 | [`server_rendered_portal`](./server_rendered_portal) | JTL server-side rendering, layouts/includes, forms, static assets | `lib/main.dart` |
| 8 | [`fullstack_flutter_sync`](./fullstack_flutter_sync) | Dart monorepo: `backend`, `shared` DTOs, `flutter_app` client | `backend/lib/main.dart` |
| 9 | [`advanced_ioc_lifecycle`](./advanced_ioc_lifecycle) | Singleton/prototype scopes, `@Lazy`, `@Primary`, `@Qualifier`, `@Order`, lifecycle hooks | `lib/main.dart` |
| 10 | [`high_throughput_telemetry`](./high_throughput_telemetry) | `jetson` parsing, chunked streaming, throughput/memory telemetry | `lib/main.dart` |
| 11 | [`social_media`](./social_media) | Full platform: timeline ranking, events, AOP proxies, SSR, uploads, rate limiting, actuator | `lib/main.dart` / `bin/social_media.dart` |
| 12 | [`microservices`](./microservices) | Pub workspace: gateway + four services, retry, BFF aggregation, cluster health | `bin/<service>.dart` per member |

Each directory has its own `README.md` with exact commands, endpoints, and sample payloads.
Start with **1** for the basics, **11** for the broadest framework tour, or **12** for a
multi-process architecture.

---

## Framework packages exercised

| Package | Role |
| :--- | :--- |
| `jetleaf` | Bootstrap, application lifecycle, profiles, environment cascade, shutdown |
| `jetleaf_core` | IoC container, typed pods, configuration, constructor injection, events |
| `jetleaf_tools` | `jl dev` / `jl run` / `jl build` / `jl proxy`, warm VM, AOT generation |
| `jetleaf_web` | Declarative MVC, controllers, routing, parameter resolvers, `ResponseEntity` |
| `jetson` | JSON serialization and schema mapping |
| `jtl` | Server-side HTML templating |
| `jetleaf_validation` | Constraint validation (`@Valid`, `@NotNull`, `@Size`, `@Email`, …) |
| `jetleaf_retry` | `@Retryable`, backoff, circuit breakers, `@Recover` |
| `jetleaf_scheduling` | `@Scheduled` cron / fixed-rate jobs |
| `jetleaf_actuator` | Health, metrics, info, liveness/readiness endpoints |
| `jetleaf_resource` | Caching and resource abstraction |

`jetleaf_data` and `jetleaf_security` are also published, but not yet used by these starters.

---

## Running the microservices workspace

`jl` is per-project-root; it does not discover pub workspace members automatically. Start one
warm VM manager per member, then run each service:

```bash
cd starter/microservices
dart pub get

# In separate shells, one per member:
(cd common                && jl dev) &
(cd user_service          && jl dev) &
(cd order_service         && jl dev) &
(cd notification_service  && jl dev) &
(cd gateway               && jl dev) &

# Then start the processes:
(cd user_service          && jl run bin/user_service.dart) &
(cd order_service         && jl run bin/order_service.dart) &
(cd notification_service  && jl run bin/notification_service.dart) &
(cd gateway               && jl run bin/gateway.dart)

curl -s http://localhost:8080/api/health/cluster | jq
```

See [`microservices/README.md`](./microservices/README.md) for the failure drills (for example,
kill the notification service and confirm the order is still accepted with degraded health).

---

## Common commands

```bash
# Validate / generate
dart analyze                       # generated _jetleaf/ code is analyzed too
jl build                           # AOT registry, caches, tree-shaking, proxies
jl build --test                    # test registry
jl proxy                           # proxy generation only

# Run with profiles
jl run lib/main.dart -- --jetleaf.profiles.active=dev
dart run lib/main.dart --jetleaf.profiles.active=prod

# Stop the warm VM manager for the current project
jl stop
```

JVM-style `--jetleaf.profiles.active=<profile>` works with `jl run`; when invoking `dart run`
directly, pass the flag without the `--` separator. Profile YAML files cascade
(`application.yaml` → `application-<profile>.yaml`).

---

## Troubleshooting

| Symptom | Cause / fix |
| :--- | :--- |
| App prints "Started …" but no port is bound | Plain `dart run` without the AOT registrar fell back to a non-web context. Use `jl build` + `jl dev` + `jl run`, or pass `registerGeneratedArtifacts` in the entrypoint. |
| `jl dev` exits 254 / analyzer version errors (`BlockEnumBody isn't a type`) | Stale `pubspec.lock` pinned an old analyzer. Re-run `dart pub get` in the affected project. |
| `@Retryable` / `@Cacheable` / `@RateLimit` appear inert | They are implemented through generated proxies. Run `jl build` (or `jl proxy`), keep `lib/_jetleaf/proxies/**` in analysis, and use them on pod-managed classes with `Future`/`void` members. Plain helpers must use the programmatic `RetryExecutor`. |
| JSON keys missing from responses | `jetson` intentionally drops empty lists/maps/nulls and emits `snake_case`; input maps are passed through as sent. Decode defensively. |
| `@ComponentScan(basePackages: …)` does not isolate a service | Scan scope is not honored by route registration or AOT emission in 2.1. Use separate packages (as `microservices/` does). |
| `@ConfigurationProperty` field stays at its default | Binding uses exact dot-case keys (`maxRequests`, not `max-requests`). |
| Cron job never starts | `@Scheduled` has no `initialDelay`; cron is 6-field (`sec min hour dom mon dow`). |
| Migrating from a local framework checkout | Add `dependency_overrides` temporarily, then `dart pub get`; do not commit them. |

Open framework-level items are tracked in [JETLEAF_FINDINGS.md](./JETLEAF_FINDINGS.md);
API-truthful notes are in [Projects.md](./Projects.md).

---

## Adding a starter

1. Create a directory with `pubspec.yaml`, `README.md`, an entrypoint (`lib/main.dart` or
   `bin/<name>.dart`), and `resources/application.yaml` if configuration is needed.
2. Declare published Jetleaf version constraints — no `dependency_overrides`.
3. Keep generated `lib/_jetleaf/` artifacts out of git (`jl build` reproduces them).
4. Add the project to the catalog table above and to `Projects.md`.
5. Verify with `dart pub get`, `dart analyze`, `jl build`, and a real HTTP request.
