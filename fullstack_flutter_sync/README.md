# 🔗 Full-Stack Dart Sync — Flutter + Jetleaf

A monorepo syncing a **Flutter** client app with a **Jetleaf** backend API,
using **one shared Dart package** for the data contract so both sides can
never drift out of sync.

## Monorepo layout

```
fullstack_flutter_sync/
  shared/                  # fullstack_sync_shared — the contract package
    lib/src/note.dart      # Note DTO + SyncPullResponse (hand-written JSON)
    test/note_test.dart    # round-trip tests
  backend/                 # fullstack_sync_backend — Jetleaf API
    lib/src/notes/note_store.dart          # in-memory seeded store
    lib/src/notes/notes_controller.dart    # CRUD + CORS
    lib/src/config/cors_registration.dart  # /api/** CORS registrar pod
  flutter_app/             # fullstack_sync_flutter — Flutter web UI
    lib/main.dart          # Notes screen + NotesApi (http package)
```

## How the pieces fit together

- **shared** is a plain path-dependency of both `backend` and `flutter_app`.
  Server and client serialize/deserialize the exact same `Note` shape.
- **backend** exposes `GET|POST /api/v1/notes`, `GET|PUT|DELETE /api/v1/notes/{id}`.
  CORS is enabled for development (`jetleaf.web.cors.enabled=true` in
  `resources/application.yaml`) and routes are registered via the
  `ApiCorsRegistrar` pod (`/api/**`, any origin — narrow in production).
- **flutter_app** uses `dart:http` against the API and renders a
  pull-to-refresh notes list with pinning and deletion.

## Run it

### 1. Backend (terminal A)
```bash
cd starter/fullstack_flutter_sync/backend
jl build
dart run lib/main.dart
```

### 2. Verify the API
```bash
curl -s http://localhost:8080/api/v1/notes
curl -s http://[::1]:8080/api/v1/notes          # Jetleaf binds IPv6 by default
curl -X POST -H 'Content-Type: application/json' \
  -d '{"title":"curl note","body":"it works"}' \
  http://localhost:8080/api/v1/notes
```

### 3. Flutter app (terminal B)
```bash
cd starter/fullstack_flutter_sync/flutter_app
flutter run -d chrome
# or use a browser against the compiled web build:
flutter build web --release && cd build/web && python3 -m http.server 3000
```

Set the API base URL with `--dart-define=API_BASE_URL=http://localhost:8080`.

## API

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/v1/notes | List all notes + server_time |
| GET | /api/v1/notes/{id} | Fetch one note (404 → advice) |
| POST | /api/v1/notes | Create note `{title, body, pinned?}` → 201 |
| PUT | /api/v1/notes/{id} | Update `{title?, body?, pinned?}` |
| DELETE | /api/v1/notes/{id} | Delete note |

## Shared contract

```dart
class Note {
  final String? id;          // server-assigned
  final String title;        // required
  final String body;
  final bool pinned;
  final DateTime updatedAt;
}
```

`Note.toJson()` / `Note.fromJson()` are implemented once in `shared/`
and used verbatim by both sides.

## CORS

- Enabled via `jetleaf.web.cors.enabled: true`
- Route-scoped `/api/**` policy registered programmatically as a
  `CorsConfigurationRegistrar` pod (`lib/src/config/cors_registration.dart`)
- Preflight `OPTIONS` → 204 with full Access-Control-* headers
- Verified working from multiple origins

## Tests

```bash
cd shared && dart test          # contract tests
cd backend && dart test         # store tests
cd flutter_app && flutter test  # widget smoke test
```
