# SocialPulse — Social Media Platform on Jetleaf 2.1

A production-style social media platform built to exercise the **entire Jetleaf 2.1
API surface** — IoC/DI, AOP, events, scheduling, retry, validation, SSR, actuator
and multipart — so that friction and framework defects surface. It is also a
genuinely usable app: seeded local workspace, JSON API, SSR portal.

```text
┌───────────────────────────────────────────────────────────┐
│                    SocialPulse (port 8080)                │
│  REST API        /api/*      JTL SSR portal    /portal    │
│  actuator-style  /actuator/* exception advice /problem    │
└───────┬───────────┬───────────────┬───────────┬──────────┘
        │           │               │           │
   PostService  FeedRanker    NotificationSvc  ModerationSvc
        │           │               │           │
   InMemory* repos (users, posts, comments, likes, follows, notifications)
```

### Stack of features exercised

| Area | How it is exercised |
|---|---|
| IoC/DI | `@Service/@Repository/@Component/@Primary/@Qualifier/@Lazy/@Scope('prototype')`, `@PostConstruct`, `@Value`, `@ConfigurationProperty` (exact-key binding), factory-method `@Pod`, custom conditionals, custom stereotype (`CommunityModerator`), prototype `NotificationDraft` |
| Events | `PostLikedEvent/CommentAddedEvent/…` with `@EventListener` pods at `@Order(10..90)` (notifications → moderation → analytics → push → audit) |
| Scheduling | `@Scheduled(fixedRate)` + `@Cron` jobs (trending recalc, hourly sweep, nightly digest) |
| Validation | `@NotBlank/@Size/@Pattern/@Min/@Max/@Positive/@Email` on DTOs; manual pod path via `PodValidator` wrapper (framework has no web-side validation) |
| SSR | `jtl`-rendered `/portal` + `/portal/{handle}` with layout composition |
| Retry | **programmatic** `RetryExecutor` (`ExternalPushClient` — annotation-level `@Retryable` is inert in this build, see "Honest notes") |
| Actuator | userland `/actuator/health|liveness|readiness|metrics|info` + `FeedStoreHealthIndicator` pattern |
| Web | `@OncePerRequestFilter` (request logging, X-User gate, token-bucket rate limit), `@RestControllerAdvice` → RFC 7807 `application/problem+json` |
| Exceptions | Domain exception hierarchy (`UserNotFoundException/DuplicateHandleException/…`) → problem details |
| Multipart | Avatar upload with part constraints + magic-byte sniffing, 413 problem details on oversize |
| Test | `dart test` — 11 passing (ranker, repos, notifications, content rules) |

### Run it

```bash
# jl dev from the project directory, then trigger the boot:
dart run ../../jetleaf/libraries/jetleaf_tools/bin/jl.dart dev          # warms + parks lib/main.dart
dart run ../../jetleaf/libraries/jetleaf_tools/bin/jl.dart run lib/main.dart -- --jetleaf.profiles.active=dev

# or plain dart run (works, slow scan; entry passes registerGeneratedArtifacts)
dart run bin/social_media.dart --jetleaf.profiles.active=dev
```

Development (`dev`) seeds a demo workspace: users `ada`/`bola`/`chidi`, posts and
follows. Admin endpoints require `X-Admin-Key` (`dev-admin-key` in dev config;
prod ships `override-me-via-secret` — replace via env). The `prod` profile does
**not** seed demo data and runs a startup guard instead.

### API map (all verified in dev)

* `POST /api/users` (register) · `GET /api/users/{handle}/profile` · `GET /api/users/{handle}` · `PATCH /api/users/{handle}` · `GET /api/users/{handle}/posts`
* Follow graph: `POST/DELETE /api/users/{handle}/follow` · `GET .../followers|following` · `GET /api/users/suggestions/me` · `GET /api/users/search`
* Posts: `POST /api/posts` · `GET /api/posts/{id}` · `POST /api/posts/{id}/like|unlike|comments|report` · `GET /api/posts/trending|tag/{tag}|search|export/stream`
* Feed: `GET /api/feed/home` (followee graph + decay rank) · `GET /api/feed/global`
* Notifications: `GET /api/notifications[?unread=true]` · `GET /api/notifications/unread-count` · `POST /api/notifications/mark-all-read`
* Admin (requires `X-Admin-Key`): `GET /api/admin/review-queue|metrics|probe|suspend` (moderators also see suspended accounts)
* Actuator: `/actuator/health|liveness|readiness|metrics|info` · Portal: `/portal` · `/portal/{handle}`

### Moderation pipeline (verified)

Filing 5 reports against a post auto-suspends its author (`reports >= 5` →
`UserStatus.suspended` + system notification) — verified end-to-end for user
`ada_dev`.

### Honest notes (framework as shipped, 2.1.0)

* **Annotation-level `@Retryable` is inert** — no `$$JLInterfaced$$` proxy is emitted; the push pipeline uses `RetryExecutor` directly (~60% simulated transient failure, 3 attempts, backoff).
* **`@Cacheable`/`@RateLimit` intercept only via `Interceptable`** — SocialPulse instead ships a userland 600 req/min token-bucket `RateLimitFilter`.
* **`jetson` strips empty lists/maps/nulls** and serializes keys as `snake_case` — clients must tolerate missing keys (`notifications`, `unread`…) and `customer_id` on the wire.
* **AOT boot path** (`jl dev` + `jl run`) is the fully supported one; plain `dart run` works but scans for minutes. `bin/social_media.dart` passes the AOT registrar so both work.
* **`@RequestParam` primitives arrive as strings** — Jetleaf 2.1 does not convert for handlers; social_media marks handlers `int`-typed and Jetleaf was patched upstream this cycle to convert them via the ConversionService (see repo Git history note in `Projects.md`).
* **Seed users are dev-only** (`ApplicationRunner` under `@Profile(['dev'])`); prod never seeds.
* **Like notifications**: liker handle fix applied post-verification; the `onPostLiked` path was restructured to look the liker up from the user store — exercise it next run.
* **Rate-limit per-actor path** (`X-User`) not yet load-tested with 600 reqs.
* **Notifications filtered by active status**: suspended users receive no notifications (by design; unread counts for suspended users may appear stale — confirm intended before production).
