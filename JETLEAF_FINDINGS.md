# Jetleaf 2.1.0 — Findings & Fix Backlog

Findings from building the two starter projects (`starter/social_media`,
`starter/microservices`) against the Jetleaf tree as shipped. Each item is
independently actionable; priorities and risk notes are included.

**Slices**
- **Part A** — behavioral findings, **open**, need triage (this is the backlog). A3 was fixed this cycle — see Part B.
- **Part B** — framework defects found and **already fixed** (for reference, do not re-fix).
- **Part C** — related notes, already documented in `Projects.md` ("Known notes on Jetleaf 2.1.0").

**Projects affected:** `social_media`, `microservices` (and every other starter),
plus any downstream app built on Jetleaf 2.1.0 as-shipped.

---

## How to use this file

Work top-to-bottom or by priority. Each entry has: status, impact, exact
evidence, candidate fix locations, and open questions to resolve during the
fix discussion. Do not fix Part A items silently — several are "tested,
intentional" framework behavior, and changing them is a product decision.

---

# Part A — Open findings (the backlog)

## A1. jetson strips empty collections/nulls from serialized output

- **Status:** Open — product decision required (change vs document)
- **Severity:** High (affects every API response)
- **Type:** tested behavior, arguably intentional; violates expectations

**Behavior.** Every JSON body rendered by jetson passes through
`StringJsonGenerator.toString()`, which calls `_cleanJson()`. That parses the
produced JSON and recursively removes:
- empty maps `{}`
- empty lists `[]`
- null values

Fail-safe: on parse error the raw JSON string is returned unchanged, so
responses never break. It is *tested*: `packages/jetson/test/string_json_generator_test.dart` asserts writing a null yields `{}`.

**Evidence**
- Source: `jetson/lib/src/json/generator/string_json_generator.dart` — `toString()` → `_cleanJson()` → `_removeEmpty()` (documented as intentional).
- Live: `GET /api/notifications` → `{"unread": 0}` with no `notifications` key.

**Impact.**
- API clients cannot rely on presence of keys; `expect(keys).containsAll(...)` breaks; generated clients (OpenAPI-style) emit unusable optional schemas.
- Empty lists disappear (`[...]` key vanishes instead of `[]`), so UIs can't distinguish "nothing yet" from "stream ended".

**Candidate fixes / options**
1. **Document only** — consumers adopt "absent == empty" decoding rules; add contract tests on the wire shape. (Lowest risk, largest ergonomic cost.)
2. **Config flag** — e.g. `jetson.remove-empty: true|false` (default true to preserve behavior; apps opt out). (Best long-term product choice; requires serializer threading + docs.)
3. **Remove the strip entirely** — breaking change for existing consumers who depend on it; conflicts with the shipped test; not recommended without major version.

**Open questions.** Who owns this decision (framework vs starter doc)? Does any internal generator rely on the strip (e.g. `@Value`/AOT parsers emitting empty pods)?

**Workaround in play.** SocialPulse writes through jetson like everything else; NDJSON export bypasses jetson entirely (manual `ServerHttpResponse`).

---

## A2. jetson wire contract is asymmetric: snake_case out, pass-through in

- **Status:** Open — same product decision as A1; document or configure
- **Severity:** High (silently breaks client/server key-name contracts)
- **Type:** intentional default, invisible by default

**Behavior.** `JetsonObjectMapper` defaults to `SnakeCaseNamingStrategy()`; jetleaf_web's `JetsonAutoConfiguration` registers it with pretty-print on; nothing overrides it on the web path. On **output**, raw map keys are transformed camelCase→snake_case. On **input**, `@RequestBody Map<String, dynamic>` arrives untransformed — casing applies to named DTO fields and output only.

**Evidence**
- Source: `packages/jetson/lib/src/jetson/jetson_object_mapper.dart` — `NamingStrategy _namingStrategy = SnakeCaseNamingStrategy();` and docs noting the default.
- Wire traces: `display_name`, `followers_count`, `unit_price_cents`, `is_deleted` for raw maps; `unread`, `notifications`, `count` unchanged (single words).
- Verified input untransformed: `POST /api/orders {"customerId":"cus_ada"}` works.
- Full-map escape hatch for control on output does not exist; escape hatches are: typed DTOs with `@JsonField(name: ...)` per field, or bypassing jetson (raw `ServerHttpResponse` writes, as SocialPulse's NDJSON exporter does).

**Impact.**
- Whatever you wrote in `toJson()` (camelCase) is not what clients see (snake_case) — docs and types must match the wire, not the code.
- Raw maps on output cannot pin exact keys; hand-built maps still get rewritten.

**Candidate fixes / options**
1. Document the wire contract + add a generator/linter rule: "never ship DTOs with names you haven't seen on the wire".
2. Framework-level setting to select naming strategy per app (`jetson.naming-strategy`), default stays snake_case.
3. Strict mode: new apps choose explicitly (fail startup if unset). More aggressive.

**Open questions.** If the flag lands, do we allow `@JsonField(name:)` always? Do we want the same for `XmlObjectMapper`?

**Workaround in play.** SocialPulse and microservices everywhere read keys with `@JsonField`-equivalents only on input; output is consumed as snake_case; SocialPulse reads `customer_id` defensively (`customerId ?? customer_id`) in the gateway aggregate.

---

## A3. Annotation-level `@Retryable` / `@Cacheable` / `@RateLimit` are inert by construction — **FIXED (2026-11-15); see B8–B16**

- **Status:** **FIXED** — implemented as the designed-for proxy pipeline; verified end-to-end
- **Severity:** was High — now resolved with caveats (see Part B)
- **Type:** incomplete wiring; design/engineering choice that hides itself

**Resolution summary.** The proxy generator was implemented (`AotProxyWriter`, wired into `jl build` and `jl dev` warm-up). Stereotype-annotated pod classes (root package only) get a generated `$$JLInterfaced$$<Class>` proxy implementing the same interface; the AOT registrar registers them in `registry_types`, `registry_pods` substituting at post-processing time (`DefaultMethodInterceptor.processAfterInitialization` instantiates the proxy and swaps it in for the delegate). Every member returning `Future`/`FutureOr`/`void` is invoked through `Interceptable.when()` → the interceptor dispatcher → registered `MethodInterceptor`s (e.g. `AnnotationAwareRetryFactory` for `@Retryable`, cache interceptor for `@Cacheable/@CachePut/@CacheEvict`, rate-limiter for `@RateLimit`). `@Recover` is resolved via `findRecoveryMethod` and invoked through the same reflective dispatch tables.

**Verified end-to-end** in `starter/social_media`: `ExternalPushClient` flipped from the programmatic executor to pure `@Retryable`/`@Recover` — through the warm VM + HTTP: retry attempt sequence (1→2) logged through the proxy, exhaustion (attempts 6–8 in sequence) hit the `@Recover` fallback and the listener logged the dropped receipt; the `#9/#10/#11` comment succeeded on retry 2. `dart analyze` is clean **including** the generated `_proxies/` files (all analyzer diagnostics for generated proxies were audited 240 → 0 and the proxies stay in analysis).

**Caveats / remaining work**
- Only members returning `Future`/`FutureOr`/`void` are interceptable — sync members are direct forwards by design (annotations that make no sense synchronously still pass through).
- Proxies are emitted only for the project's **root package**; library packages shipped as dependencies are not proxied.
- The generated proxies are lint-suppressed file-level and are expected to stay analyzer-clean; keep `lib/_proxies/**` included in analysis.
- No unit tests pin the interception path yet (verification is HTTP-level; see SocialPulse README).
- A separate silent-failure mode exists in `ApplicationEventMethodAdapter` (listener invocations are fire-and-forget, exceptions swallowed) — app-level listeners should try/catch or the framework should log; logged as a footnote in Part B.

**Original (pre-fix) symptom for the record:** transient failures **threw** out of `@Retryable` methods; `@Cacheable` never cached; `@RateLimit` never limited. Fixed by the new proxy pipeline; the programmatic `RetryExecutor` remains the right tool for non-pod helpers (e.g. `microservices/common`'s `ServiceHttpClient`).

---

## A4. `jl dev` / `jl run` / `jl build` are per-project-root; no pub-workspace awareness

- **Status:** Open — tooling gap; needs product decision + possible rewrite of model
- **Severity:** High for monorepos; the reason `microservices/` is a workspace instead of one app
- **Type:** architecture limitation (single root assumption baked in everywhere)

**Behavior.** `jl dev` resolves **one** project root (CWD or `jl dev --root <dir>`), discovers entries under `<root>/lib` + `<root>/bin` (and `test/` for test entries), warms `<root>/.jetleaf/`, and spawns one warm VM per `@JetleafEntry`. There is no workspace manager: member packages in a pub `workspace:` are invisible to a manager rooted at the workspace root, and a manager rooted at a *member* cannot see siblings. `jl run` needs the per-package manager alive; kill it and ports die.

**Evidence**
- Observations: multiple `jl dev` logs (root vs member); per-member `.jetleaf/`; required `--root`-less CWD juggling.
- Tooling source pointers: `jetleaf_tools/src/vm/jetleaf_vm.dart`, `src/cache/manager/_cacheable_manager.dart` (scans `lib`, `bin`, `test` under one root), `src/cli/dev_command.dart` (`Found N entries`, `Warming cache`).

**Impact.** No first-class "run my monorepo's 4 services" command. No shared AOT cache across members (duplicate ~1-2 min warm build each). Workspace roots produce zero entries (`bin/` empty at root) or wrong ones (root-package app that wasn't meant to be an app).

**Candidate fixes / options**
1. **Workspace awareness in `jl`**: teach the scanner to enumerate workspace members (read root `pubspec.yaml` `workspace:` list), resolve per-member caches (`.jetleaf/` per member or a shared registry folder), and spawn one manager per member. (Right long-term fix; touches discovery, cache keys, health/state files.)
2. **Thin supervisor** around existing per-package managers: a small `jl workspace` command that launches N `jl dev`s in parallel + merges state into one pidfile. (Pragmatic; mostly tooling.)
3. **Document the limitation and script it** — a `Makefile`/`up.sh` in the workspace README that starts members sequentially. (No code; most brittle; matches reality today.)

**Open questions.** Should members share one AOT registry and one VM process, or keep process-per-service? How do logs interleave? Does the control plane (`127.0.0.1:<port>`) become multiplexed?

**Workaround in play.** `starter/microservices/README.md` documents per-member `jl dev` + `jl run`; four parallel managers are required; `ps aux | grep "jl.dart dev"` shows 4–5 managers during a session.

---

## A5. `@ComponentScan(basePackages: …)` does not scope AOT registration or controller discovery

- **Status:** Open — defect or at least a documentation trap
- **Severity:** Medium–High (silently defeats app-scoping; led to broken "one app, four ports" prototype)
- **Type:** incomplete wiring / misleading configuration surface

**Behavior.** `basePackages` is parsed by the JIT scanners (`ComponentScanAnnotationParser`, used by `ConfigurationClassPostProcessor` for conditional/candidate logic) — but it is **not consulted by the web tier's route registration** (`AbstractAnnotatedHandlerMapping.onReady()` discovers controllers via `applicationContext.getDefinitionNames()` filtered by `@Controller`/`@RestController` annotations) and is **not consulted by AOT registration** either (the AOT registry builder scans `lib/` as one tree and registers every stereotype it finds).

**Evidence**
- Source: `packages/jetleaf_web/lib/src/server/handler_mapping/abstract_annotated_handler_mapping.dart` — `onReady()` uses `getDefinitionNames()` + `hasDirectAnnotation<Controller|RestController>()`; `basePackages` never read.
- Source: `libraries/jetleaf_tools/lib/src/aot/aot_pod_registry_writer.dart` and `aot_registrar_writer.dart` — emit registrations for every discovered component, no scan filtering.
- Live: single-package prototype — every port served identical route table; `/actuator/health` on port 8081 reported `"service": "notification"` (a user-service "notification-store" indicator registered everywhere).

**Impact.** Teams scoping apps with ComponentScan believe they have isolation; they do not. Actuator pods, controllers, filters, health indicators — everything registered is registered for every service.

**Candidate fixes / options**
1. **Honor scan scope in the web mapping** — filter `getDefinitionNames()` by `basePackages` prefix at `onReady()` time (cheap and correct for web).
2. **Honor scan scope in AOT registry emission** — emit only components whose package prefix matches an explicit scan root (correctness fix symmetrical to #1; requirements: reliable package-name extraction from `ClassDeclaration`).
3. **Fail loudly instead of silently** — at startup, if any registered controller is out-of-scope for the declared scan, throwing is better than serving the wrong routes. (Cheapest honest behavior.)
4. **Document** — remove or re-word the misleading parameter; direct to package separation.

**Open questions.** Which filter applies to pods other than controllers (health indicators, filters)? Does scan-scoping generalize to `@ConfigurationProperty`?

**Workaround in play.** `starter/microservices` split into a pub workspace with per-member packages — the only path to actual isolation; same for SocialPulse (single app by design).

---

## A6. Plain `dart run` boots a context with no HTTP server

- **Status:** Open — defect (or "required AOT; must document hard"); decide which
- **Severity:** High (breaks the obvious path; zeros out every "just run it" tutorial)
- **Type:** bootstrap defect; masked by `jl dev`/`jl run`

**Behavior.** `DefaultApplicationContextFactory` selects the context type by reflectively discovering `ConfigurableApplicationContext` subclasses and instantiating them. Without a registrar populating AOT constructor tables (`registerNamedConstructor(...)`), instantiation fails with `ConstructorNotFoundException` for *all* candidates (including `AnnotationConfigApplicationContext` and `ServerWebApplicationContext`), and the factory **silently falls back to `AnnotationConfigApplicationContext()`**. That context has no web bootstrap: no dispatcher, no `SmartLifecycle` chain to call `server.start()`, no port is ever bound; the app prints a banner and exits.

With the AOT registrar passed (`JetleafApplication.run(app, args, null, registerJetleafAot)`), the tables populate, the factory picks `ServerWebApplicationContext` for WEB, and the server binds. `jl dev`/`jl run` accomplish the same via the generated entry wrapper. Without the registrar, nothing about the web tier can ever start in plain Dart.

**Evidence**
- Source: `libraries/jetleaf_core/lib/src/lang/runtime/provider/_material_library.dart` (`getSubClasses()` uses the runtime cache; instantiation blind) — and `libraries/jetleaf_tools/lib/src/aot/aot_registrar_writer.dart` (the master `_jetleaf/aot_registry.g.dart` emits `registerNamedConstructor(...)`, which is what plain Dart lacks).
- Live (ecommerce_catalog_api, plain `dart run bin/debug_run.dart`): `Launching ... with application type: WEB` … `Started EcommerceCatalogApp in 8.834 seconds` → immediate graceful shutdown, port never bound.
- Instrumented instrumentation output (now reverted): `CONTEXTFACTORY: failed AnnotationConfigApplicationContext -> ConstructorNotFoundException` for both candidates; `falling back to AnnotationConfigApplicationContext`.
- With registrar via `jl run`: `Starting setup of ServerWebApplicationContext application context...`, `Binding HTTP server on localhost:8080`, `Server started in 21/30 ms`.

**Impact.** Every "getting started" command a new user tries (`dart run bin/foo.dart`) silently succeeds-and-exits without binding a port; the app prints "Application started" then closes. Looks like success; serves nothing; hours lost. Starters that do bind rely on `jl` indirection to mask this.

**Candidate fixes / options**
1. **Make the fallback loud** — detect `WEB` application type + see that web context could not be instantiated → throw a fatal with remediation: "This application type requires the Jetleaf AOT registrar; run via `jl run` or add `registerJetleafAot` to your entry point. `dart run` is not a supported bootstrap." (Fail-fast instead of silent no-op.)
2. **Always-JIT context** — guarantee `AnnotationConfigApplicationContext` can always be constructed (it actually can be instantiated statically from user code if user constructs it directly; the failure mode is the reflective path) — but it won't bind HTTP either, so this alone is insufficient; must route web-aware type selection statically.
3. **Ship registrar in entrypoint by default** (like our `bin/social_media.dart` fix) — and verify starter templates all do this (they do for the library's own examples, but `example/` misses it).
4. **Document hard + CI check** in tooling template that entrypoints import the generated registry.

**Open questions.** If we get http server bind with plain Dart through a static `ServerWebApplicationContext()` ctor in user code, we'd give up reproducible pod instantiation, so it's not technically achievable without significant baggage — the fail-loud route is probably right. Should `jl` warn if a bin/ lacks registrar?

**Workaround in play.** `bin/social_media.dart` and all starter `bin/*.dart` entries updated to pass `registerJetleafAot`, so `dart run` works too (verified for microservices entries through `jl run`; plain `dart run` for those bins was not re-run after the edit — see remaining gaps, Projects.md and SocialPulse README).

---

# Part B — Defects found and FIXED this cycle (do not re-fix)

These were real defects in the tree, fixed against the framework source and verified. Listed so they aren't reopened as backlog items.

| ID | Component | Defect | Fix |
|---|---|---|---|
| B1 | jetleaf_core — pod factory | `AbstractAutowirePodFactory.createInstance` ignored `root.instanceSupplier` when `factoryMethod` was set | Supplier now wins when present |
| B2 | jetleaf_tools — AOT generator | `@Value` on `@Pod` factory-method parameters emitted `factory.get(Class<int>())` (unresolvable); pods unbuildable | Generator now emits `_resolveConfigValue(...)` placeholder→env→ConversionService→cast; `INSTANCE.valueName`, `primitiveClassLiteral`, `dartStringLiteral`, `_valueExpression`, `_buildParameterLookup`, `_castTarget` helpers added in `aot_pod_registry_writer.dart` |
| B3 | jetleaf_tools — master registry emitter | `aot_registry.g.dart` never emitted `_resolveConfigValue` / `_optional` helpers | `_valueResolver` + `_optionalHelper` constants in `aot_registrar_writer.dart`, inserted after the generated `part` directives (must come after parts, before `bool _aotRuntimeInitialized...`) |
| B4 | jetleaf_tools — AOT generator | Generator emitted unconditional `factory.get(...)` for **nullable** injectable parameters — web server could never boot (`NoSuchPodDefinitionException` → 503) | Wrap optional lookups in `_optional(factory, () async => ...)` for parameters that are nullable or non-required |
| B5 | jetson / web boot pipeline | Chain B2+B4 kept `IoWebServerSecurityContextFactory?` unresolvable → web server could never bind | All `_jetleaf/` trees in monorepo regenerated with rebuilt `jetleaf_tools` |
| B6 | jetleaf_web — method argument adaptation | `@RequestParam int/bool/...` resolved as `String` and never converted → `String is not a subtype of int` crashes | `DefaultMethodArgumentResolverManager.resolveArgs` now converts via `ApplicationContext → PodFactory → ConversionService`; failures → 400 `InvalidArgumentException` |
| B7 | SocialPulse — notification listener | `onPostLiked` message used `event.post.authorHandle` (author) instead of the liker's handle | Now looks up liker via `UserRepository` |
| B8 | jetleaf_tools — AOT proxy generator | **Proxies were silently pruned from the cache and the AOT registry** — tree-shaking ran `_isReachableComponent` against the pre-proxy file set, so every `$$JLInterfaced$$` class was unreachable and dropped (1799 components vs 1840 with proxies) | `build_command.dart` re-scans after proxy emission and feeds the post-proxy `files` set into reachability analysis |
| B9 | jetleaf_tools — AOT proxy generator | **Proxy files were named after the source file only**, so multiple stereotype classes in one file (e.g. `social_pulse_listeners.dart` with 5 `@Service` classes) clobbered each other — 41 classes "written", only 31 proxies on disk, and AOT/unreachable cache silently missing classes like `HealthService`, `AuditEventListener`, `InMemoryNotificationRepository` | Proxy file now suffixed with snake_case class name (`social_pulse_listeners_audit_event_listener.proxy.dart`) |
| B10 | jetleaf_tools — all AOT writers | **`$$`-containing identifiers emitted raw into single-quoted literals** — e.g. `'$$JLInterfaced$$ExternalPushClient'` in `registry_types.g.dart` is unparseable (`$$` starts an interpolation); the application could never reach `registerJetleafAot`. Any `$`, `'` or `\` in class/pod/member names broke the generated source | `AotSubRegistrarWriter.escapeDartStringLiteral` added; applied at every literal emission site (type/constructor/method/field/pod registries) |
| B11 | jetleaf_tools — `jl dev` entry writer | Generated warm-VM entry imported `package:jetleaf_tools/src/runtime/scanner/runtime_scanner_configuration.dart`, **a path that does not exist** — every warm VM died at startup (`Method not found: 'RuntimeScannerConfiguration'`) | Entry stub now uses the public `jetleaf_tools.dart` API surface only (`jl.RuntimeScannerConfiguration`, `jl.RuntimeBuildMode`) |
| B12 | jetson-adjacent logging — `LogFactory` | **`_isWarnEnabled` / `_isFatalEnabled` / `_isTraceEnabled` defaulted to `false`** — every `_logger.warn(...)` in the framework was silently dropped (this masked exhausted-retry visibility during the SocialPulse verification loop; the `@Recover` path looked "dead" until WARN was observed to be suppressed by default) | WARN default flipped to `true` (consistent with DEBUG/INFO/ERROR); documented in the code comment; FATAL/TRACE left as opt-in |
| B13 | jetleaf_core — AOT registrar template | Generated `_valueResolver` threw raw `StateError` on unresolvable `@Value` placeholder | Throws `IllegalStateException` (framework exception policy); generated file imports `design.dart show IllegalStateException` |
| B14 | jetleaf_tools — proxy header builder | `writeGeneratedHeader` already emitted `// ignore_for_file: type=lint, ...` — generated proxies emitted a duplicate `// ignore_for_file: type=lint` (34 `duplicate_ignore` warnings) | Removed the duplicate line from the proxy template; proxies analyze clean |
| B15 | jetleaf_core — `DefaultMethodInterceptor` / AOP | Annotation-driven interception was inert **because no proxies were emitted at all** (see A3). With the proxy generator landed: `$$JLInterfaced$$` pod substituted at post-processing, async members routed through `Interceptable.when` → dispatcher. Verified: `@Retryable(maxAttempts: 3)` retried, `@Recover` returned the drop-receipt after exhaustion, all through the AOP proxy path | See A3 (resolved) + proxy writer in `aot_proxy_writer.dart`, `aot_sub_registrar_writer.dart` |
| B16 | jetleaf_tools — declaration builder & analysis | `declaration_builder.dart` warnings: `dead_code`, `dead_null_aware_expression`, `unnecessary_null_comparison` (`link != null` / `name ?? ''`); `cache_aware_scanner.dart` `prefer_initializing_formals` ×2; proxy writer: unused `isLate` + raw `$$` text in a doc sentence | Fixed; `dart analyze libraries/jetleaf_tools` is **0 issues**; SocialPulse **0 issues** with generated proxies included |

All package `.jetleaf/` registries regenerated after the fixes (jetleaf_core, all `packages/*`, `builder/server`, `example`, all `sample_projects`); `jetleaf_tools` rebuilt; `ultimate` sample suite re-run — 13/13 pass.

---

# Part C — Related notes

`Projects.md` documents the same API-truthful surface alongside these findings:
- `@Scheduled` has no `initialDelay`; cron is 6-field (`sec min hour dom mon dow`); `@CronType.MONTHLY_ON_LAST_MIDNIGHT` uses non-standard `L`.
- `@ConfigurationProperty` binds by **exact** case-insensitive dot-name (`maxRequests`, never `max-requests`); `@Value('#{key:default}')` for placeholders with defaults.
- `@Profile(['dev'])` list-only, `!` negation via `['!prod']` or `Profile.not(['prod'])`; **class-targeted**, method-target not supported.
- Validation constraints require `jetleaf_validation` interceptor wiring; the web layer does not validate `@RequestBody` — app-layer validation is mandatory.
- `ContextClosedEvent` fires on `close()`; no `GracefulShutdown` equivalent; publication via `ApplicationContext.publishEvent`.
- `JetleafApplication.run(primarySource, args, [scanConfiguration, aotRegistrar])` — third `null` like the samples, fourth is the registrar.

---

# Triage summary

| ID | Decision axis | Suggested owner | Risk to change |
|---|---|---|---|
| A1 | framework behavior vs wire-contract ergonomics | Jetleaf product/arch | High (tested behavior; clients depend on it) |
| A2 | same as A1 (wire contract) | Jetleaf product/arch | High (every client rewritten) |
| ~~A3~~ | fixed (proxy pipeline landed; verified) | jetleaf_tools + jetleaf_core | Low (opt-in emission; proxies analyzer-checked) |
| A4 | tooling architecture | jetleaf_tools | Medium (discovery + cache keys) |
| A5 | correctness defect | jetleaf_web/AOT | Low–Medium (scoping too tight could hide pods; escape hatch needed) |
| A6 | bootstrap correctness vs DX | jetleaf_core/tools | Low (fail-loud is safest) |

**Next step:** pick an A-item, decide policy (change / document / fail-loud), then open a focused task (branch, change, verify).
