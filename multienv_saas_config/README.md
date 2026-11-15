# 🏢 Multienv SaaS Config

A Jetleaf starter showcasing **hierarchical, profile-driven configuration** for a
multi-tenant SaaS backend — without forking the codebase per environment.

## Features

* **Cascading YAML** — `application.yaml` is the base; `application-{dev,staging,prod}.yaml`
  override only what differs. The active profile merges on top at startup.
* **Type-safe binding** — `@ConfigurationProperty(prefix: …)` classes bind
  `app.*`, `app.rate-limit.*` and `app.features.*` into typed Dart objects.
* **Scalar injection** — `BrandingService` shows `@Value('#{app.name}')` /
  `@Value('#{app.region}')` field injection.
* **Profile-selected pods** — `DiagnosticsProvider` has `dev` / `staging` / `prod`
  implementations selected purely by `@Profile([…])` (plus a `@Profile(['default'])`
  fallback), so the exact same binary behaves correctly in every environment.
* **Active profile switching at runtime** — pass `--jetleaf.profiles.active=dev`
  (or set `jetleaf.profiles.active`) and restart.

## Layout

```
resources/
  application.yaml            # base (shared) config
  application-dev.yaml        # dev overrides (port 8081, debug, generous limits)
  application-staging.yaml    # staging overrides (300 req/min)
  application-prod.yaml       # prod overrides (eu-central-1, 50 req/min)
lib/
  main.dart                          # @JetleafApplicationStarter entrypoint
  src/config/saas_properties.dart    # @ConfigurationProperty classes
  src/services/branding_service.dart # @Value injection demo
  src/services/quota_service.dart    # pure quota budget logic
  src/diagnostics/                   # @Profile-specific pods + fallback
  src/controllers/config_controller.dart
```

## Run

```bash
cd starter/multienv_saas_config
jl build

# default profile
dart run lib/main.dart
# dev profile (serves on :8081)
dart run lib/main.dart --jetleaf.profiles.active=dev
# staging / prod
dart run lib/main.dart --jetleaf.profiles.active=staging
dart run lib/main.dart --jetleaf.profiles.active=prod
```

## Try it

```bash
curl -s http://localhost:8080/api/v1/config/status | jq
curl -s "http://localhost:8080/api/v1/config/tenants/acme/quota?used=40" | jq
```

With the default profile: `"max_requests": 100`. With `--jetleaf.profiles.active=prod`:
`"max_requests": 50` and `"region": "eu-central-1"` — same artifact, config-driven behavior.

## Configuration keys

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `app.name` | String | `Acme SaaS` | Tenant-facing product name |
| `app.region` | String | `us-east-1` | Deployment region |
| `app.rate-limit.maxRequests` | int | `100` | Per-minute tenant request budget |
| `app.features.auditLog` | bool | `true` | Emit audit log entries |
| `app.features.betaDashboard` | bool | `false` | Enable the beta dashboard |

> **Binding rule**: Jetleaf binds fields by exact name — `app.rate-limit.maxRequests`
> maps to field `maxRequests` under prefix `app.rate-limit`. Use exact field names
> (camelCase) after the prefix; no relaxed kebab→camel transforms are applied.

## Profiles

| Profile | Port | Rate limit | Diagnostics provider |
|---------|------|-----------|----------------------|
| default | 8080 | 100 | `DefaultDiagnosticsProvider` |
| dev | 8081 | 100000 | `DevDiagnosticsProvider` |
| staging | 8080 | 300 | `StagingDiagnosticsProvider` |
| prod | 8080 | 50 | `ProdDiagnosticsProvider` |

## Tests

```bash
dart test
```
