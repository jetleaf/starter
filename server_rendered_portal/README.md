# 🌿 Server Rendered Portal (JTL SSR)

An SEO-friendly developer portal rendered entirely on the server with
**JTL** (Jetleaf Template Language) — no client-side JavaScript required
for content.

## Highlights

- **Server-side rendering** — every page is a composed HTML document via
  `PortalTemplateRenderer.render(page, context)`:
  page body → merged into `resources/templates/layout.html` → single JTL pass.
- **Dynamic content** — `{{#each features}}` loops, `{{#if}}` conditionals,
  nested `{{user.name}}` interpolation.
- **Form handling with server-side validation** — `POST /contact` parses
  `application/x-www-form-urlencoded` bodies, validates, and either re-renders
  the form with inline errors (HTTP 400) or a success page.
- **Static assets** — `GET /assets/app.css` serves the site stylesheet
  (`text/css`).
- **Correct content negotiation** — pages are served as `text/html; charset=utf-8`.

## Layout

```
resources/templates/
  layout.html          # site chrome — header/footer/nav; page body slot {{content}}
  home.html            # hero + {{#each features}} + {{#if betaBanner}}
  docs.html            # sidebar nav + {{currentTitle}}/{{currentBody}} + {{#if currentHasCode}}
  contact.html         # form with {{#if hasErrors}} error list and {{#each errors}}
  contact_success.html # post-submit confirmation
lib/
  main.dart                          # @JetleafApplicationStarter entrypoint
  src/web/template_renderer.dart     # layout composition + JTL rendering; CWD-robust template lookup
  src/web/portal_data.dart           # docs content model
  src/web/portal_controller.dart     # routes: /  /docs  /contact (GET+POST)  /assets/app.css
bin/
test/services/template_renderer_test.dart   # SSR unit tests — layout composition, loops, conditionals
```

## Run

```bash
cd starter/server_rendered_portal
jl build
dart run lib/main.dart
```

## Try it

```bash
curl -s -o /tmp/portal.html http://localhost:8080/ && head /tmp/portal.html
curl -s "http://localhost:8080/docs?section=scheduling"
curl -s -X POST -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'name=Ada Lovelace' --data-urlencode 'email=ada@example.com' \
  --data-urlencode 'message=Show me the scheduling docs' \
  http://localhost:8080/contact
curl -s -I http://localhost:8080/assets/app.css
```

Note: curl sends `Accept: */*` by default; browsers send richer Accept headers.
Pages are always written as `text/html` regardless of the client.

## Templates

Templates use JTL (Mustache-style):

```html
<ul>
  {{#each features}}
  <li>{{this}}</li>
  {{/each}}
</ul>
{{#if betaBanner}}<p class="beta">Beta open</p>{{/if}}
```

Layout composition is a simple, explicit `{{content}}` slot replacement before
the JTL pass, so page-level variables and layout-level variables share one
evaluation context.

## Tests

```bash
dart test
```
