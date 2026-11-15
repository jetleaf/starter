import 'package:jetleaf_web/jetleaf_web.dart';

import 'portal_data.dart';
import 'template_renderer.dart';

/// Server-rendered portal controller.
///
/// Every handler returns a fully composed HTML document — no client-side
/// JavaScript is required for content. Templates are rendered server-side
/// through JTL.
@RestController('/')
@Produces([MediaType.TEXT_HTML])
class PortalController {
  final PortalTemplateRenderer _renderer = PortalTemplateRenderer();

  @GetMapping(produces: [MediaType.TEXT_HTML])
  ResponseBody<String> home() {
    return _html(_renderer.render('home', {
      'title': 'Developer Portal',
      'description': 'Server-rendered developer portal built with Jetleaf and JTL',
      'heroTitle': 'Ship backend features with confidence 🍃',
      'heroSubtitle': 'Jetleaf + JTL gives you fast SSR HTML, typed pods, and a tiny runtime — perfect for SEO-friendly portals and docs sites.',
      'features': [
        'Server-side rendered HTML — crawlable out of the box',
        'Layouts and loops with JTL templates',
        'Constructor-injected services, zero globals',
        'Form handling with automatic validation errors',
      ],
      'betaBanner': true,
    }));
  }

  @GetMapping(path: '/docs', produces: [MediaType.TEXT_HTML])
  ResponseBody<String> docs(@RequestParam(value: 'section', required: false) String? section) {
    final key = section ?? 'getting-started';
    final current = PortalData.docsContent[key] ?? PortalData.docsContent['getting-started']!;

    return _html(_renderer.render('docs', {
      'title': 'Docs',
      'description': 'Jetleaf documentation browser',
      'section': PortalData.docsSections.firstWhere((s) => s['key'] == key, orElse: () => PortalData.docsSections.first)['label'],
      'sections': PortalData.docsSections,
      'currentTitle': current['title'],
      'currentBody': current['body'],
      'currentHasCode': current['hasCode'],
    }));
  }

  @GetMapping(path: '/contact', produces: [MediaType.TEXT_HTML])
  ResponseBody<String> contactForm() => _html(_renderContactForm(const {}));

  @PostMapping(path: '/contact', consumes: [MediaType.APPLICATION_FORM_URLENCODED], produces: [MediaType.TEXT_HTML])
  ResponseBody<String> contactSubmit(
    @RequestParam(value: 'name', required: false) String? name,
    @RequestParam(value: 'email', required: false) String? email,
    @RequestParam(value: 'message', required: false) String? message,
  ) {
    final values = {
      'name': name?.trim() ?? '',
      'email': email?.trim() ?? '',
      'message': message?.trim() ?? '',
    };

    final errors = <String>[];
    if ((values['name']!.length) < 2) {
      errors.add('Name must be at least 2 characters.');
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(values['email']!)) {
      errors.add('A valid email address is required.');
    }
    if (values['message']!.length < 10) {
      errors.add('Message must be at least 10 characters.');
    }

    if (errors.isNotEmpty) {
      return _html(_renderContactForm({...values, 'errors': errors}), HttpStatus.BAD_REQUEST);
    }

    return _html(_renderer.render('contact_success', {
      'title': 'Message received',
      'description': 'Thanks for reaching out',
      ...values,
    }));
  }

  /// Serves the site stylesheet.
  @GetMapping(path: '/assets/app.css', produces: [MediaType.TEXT_CSS])
  @Produces([MediaType.TEXT_CSS])
  ResponseBody<String> stylesheet() => ResponseBody.of(
        HttpStatus.OK,
        _css,
        HttpHeaders()..set('Content-Type', 'text/css; charset=utf-8'),
      );

  ResponseBody<String> _html(String html, [HttpStatus status = HttpStatus.OK]) {
    return ResponseBody.of(
      status,
      html,
      HttpHeaders()..set('Content-Type', 'text/html; charset=utf-8'),
    );
  }

  String _renderContactForm(Map<String, Object?> values) {
    final errors = (values['errors'] as List?)?.cast<String>() ?? const <String>[];
    return _renderer.render('contact', {
      'title': 'Contact',
      'description': 'Contact the Jetleaf team',
      'name': values['name'] ?? '',
      'email': values['email'] ?? '',
      'message': values['message'] ?? '',
      'hasErrors': errors.isNotEmpty,
      'errors': errors,
    });
  }
}

const _css = '''
:root { color-scheme: light; }
* { box-sizing: border-box; }
body { margin: 0; font-family: -apple-system, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; color: #1f2937; background: #f8fafc; }
.wrap { max-width: 960px; margin: 0 auto; padding: 0 1.25rem; }
.site-header { background: #0f172a; color: #e5e7eb; padding: 0.75rem 0; }
.site-header .wrap { display: flex; align-items: center; justify-content: space-between; }
.brand { color: #34d399; font-weight: 700; font-size: 1.1rem; text-decoration: none; }
.site-header nav a { color: #cbd5e1; margin-left: 1.25rem; text-decoration: none; }
.site-header nav a:hover { color: #fff; }
main.wrap { padding: 2rem 1.25rem 3rem; }
h1 { font-size: 2rem; margin-bottom: 0.25rem; }
.lede { color: #475569; font-size: 1.05rem; margin-top: 0; }
.features { line-height: 1.9; }
.button { display: inline-block; background: #059669; color: #fff; padding: 0.65rem 1.1rem; border-radius: 0.375rem; text-decoration: none; border: 0; cursor: pointer; font-size: 1rem; }
.button:hover { background: #047857; }
.docs-grid { display: grid; grid-template-columns: 220px 1fr; gap: 2rem; }
.docs-grid aside ul { list-style: none; padding: 0; }
.docs-grid aside a { color: #065f46; text-decoration: none; display: block; padding: 0.3rem 0; }
pre { background: #0f172a; color: #86efac; padding: 0.75rem; border-radius: 0.375rem; overflow-x: auto; }
.portal-form { display: grid; gap: 0.9rem; max-width: 560px; }
.portal-form label { display: grid; gap: 0.35rem; font-weight: 600; }
.portal-form input, .portal-form textarea { padding: 0.5rem; border: 1px solid #cbd5e1; border-radius: 0.375rem; font: inherit; }
.errors { background: #fef2f2; border: 1px solid #fecaca; color: #991b1b; padding: 0.75rem 1rem; border-radius: 0.375rem; margin-bottom: 1rem; }
.beta { color: #065f46; font-weight: 600; }
.site-footer { border-top: 1px solid #e2e8f0; padding: 1rem 0; color: #64748b; font-size: 0.9rem; }
''';
