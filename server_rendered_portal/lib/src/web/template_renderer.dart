import 'dart:io';

import 'package:jtl/jtl.dart';
import 'package:jetleaf_core/lang.dart';

/// Server-side template renderer.
///
/// Composes a page template into a shared layout, then renders the merged
/// document with JTL in a single pass (so variables in both the layout and
/// the page body resolve from one context).
///
/// Templates are read from `resources/templates/`. The lookup tries the
/// package working directory first, then the monorepo root, so the app works
/// whether launched from `starter/server_rendered_portal` or the repo root.
class PortalTemplateRenderer {
  final _jtl = JtlFactory();

  static const _candidates = [
    'resources/templates',
    'starter/server_rendered_portal/resources/templates',
    '../server_rendered_portal/resources/templates',
  ];

  Directory? _templateDir;

  Directory get _resolveDir {
    final cached = _templateDir;
    if (cached != null) return cached;

    for (final candidate in _candidates) {
      final dir = Directory(candidate);
      if (dir.existsSync()) {
        _templateDir = dir;
        return dir;
      }
    }

    throw StateError(
      'Template directory not found. Tried: ${_candidates.join(', ')}. '
      'Run from the package root (starter/server_rendered_portal).',
    );
  }

  /// Renders [page] wrapped in the shared layout with [context] data.
  String render(String page, Map<String, Object?> context) {
    final dir = _resolveDir;

    final layout = File('${dir.path}/layout.html').readAsStringSync();
    final body = File('${dir.path}/$page.html').readAsStringSync();
    final merged = layout.replaceFirst('{{content}}', body);

    final mergedAttrs = <String, Object?>{
      'year': DateTime.now().year.toString(),
      ...context,
    };

    // JTL caches renders by template location — key by page + attributes so
    // dynamic pages never serve stale output.
    final location = '$page.html?${mergedAttrs.entries.map((e) => '${e.key}=${e.value}').join('&').hashCode}';

    final template = JtlTemplate(
      location,
      mergedAttrs,
    );

    final asset = AssetResource(merged);
    return _jtl.render(template, asset).getRenderedContent();
  }
}
