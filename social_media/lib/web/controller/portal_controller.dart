/// Server-rendered portal — JTL templates, no client JavaScript required.
///
/// Public HTML pages for SEO and link sharing: a live trending board and
/// per-user profile cards.
library;

import 'dart:io';

import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

import '../../service/post_service.dart';
import '../../service/user_service.dart';
import '../../util/page.dart';

@RestController('/portal')
@Produces([MediaType.TEXT_HTML])
class PortalController {
  PortalController(this._users, this._posts);

  final UserService _users;
  final PostService _posts;
  final _renderer = PortalTemplateRenderer();

  /// Public trending board.
  @GetMapping(produces: [MediaType.TEXT_HTML])
  Future<ResponseBody<String>> trending(
    @CookieValue(value: 'social_theme', required: false, defaultValue: 'dark') String theme,
  ) async {
    final posts = await _posts.trending(limit: 20);
    return _html(_renderer.render('trending', {
      'title': 'Trending',
      'description': 'The live trending board on SocialPulse',
      'theme': theme,
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'posts': [
        for (final p in posts)
          {
            'authorHandle': p.authorHandle,
            'content': p.content,
            'likes': p.likes,
            'comments': p.comments,
            'tags': p.tags.join(', '),
          },
      ],
      'hasPosts': posts.isNotEmpty,
    }));
  }

  /// Public profile card.
  @GetMapping(path: '/{handle}', produces: [MediaType.TEXT_HTML])
  Future<ResponseBody<String>> profile(@PathVariable(value: 'handle') String handle) async {
    final user = await _users.requireByHandle(handle);
    final page = await _posts.postsByAuthor(
      user.id,
      const PageRequest(page: 0, size: 5),
    );
    return _html(_renderer.render('profile', {
      'title': '@${user.handle}',
      'description': '${user.displayName} on SocialPulse',
      'handle': user.handle,
      'displayName': user.displayName,
      'bio': user.bio,
      'followers': user.followersCount,
      'following': user.followingCount,
      'posts': user.postsCount,
      'joined': user.createdAt.toIso8601String().substring(0, 10),
      'recentPosts': [
        for (final p in page.content)
          {'content': p.content, 'likes': p.likes, 'comments': p.comments},
      ],
      'hasPosts': page.content.isNotEmpty,
    }));
  }

  ResponseBody<String> _html(String html, [HttpStatus status = HttpStatus.OK]) =>
      ResponseBody.of(status, html,
          HttpHeaders()..set('Content-Type', 'text/html; charset=utf-8'));
}

class PortalTemplateRenderer {
  final _jtl = JtlFactory();

  static const _candidates = [
    'resources/templates',
    'starter/social_media/resources/templates',
    '../social_media/resources/templates',
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
    throw IllegalStateException('Template directory not found. Tried: ${_candidates.join(', ')}');
  }

  String render(String page, Map<String, Object?> context) {
    final dir = _resolveDir;
    final layout = File('${dir.path}/layout.html').readAsStringSync();
    final body = File('${dir.path}/$page.html').readAsStringSync();
    final merged = layout.replaceFirst('{{content}}', body);

    final mergedAttrs = <String, Object?>{
      'year': DateTime.now().year.toString(),
      'theme': 'dark',
      ...context,
    };

    // JTL caches by template location — salt with attributes hash so dynamic
    // pages never serve stale output.
    final location =
        '$page.html?${mergedAttrs.entries.map((e) => '${e.key}=${e.value}').join('&').hashCode}';

    final template = JtlTemplate(location, mergedAttrs);
    final asset = AssetResource(merged);
    return _jtl.render(template, asset).getRenderedContent();
  }
}
