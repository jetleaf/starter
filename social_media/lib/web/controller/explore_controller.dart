/// Faceted exploration API — showcases matrix variables.
///
/// `GET /api/explore/{segment}/posts;q=jetleaf;since=2026-01-01`
library;

import 'package:jetleaf_web/jetleaf_web.dart';

import '../../repository/post_repository.dart';
import '../../util/page.dart';

@RestController('/api/explore')
class ExploreController {
  ExploreController(this._posts);

  final PostRepository _posts;

  /// Matrix variables bound from the same path segment.
  @GetMapping(path: '/{segment}/posts')
  Future<Map<String, Object?>> explore(
    @PathVariable(value: 'segment') String segment,
    @MatrixVariable(value: 'q', pathVar: 'segment', required: false) String? q,
    @MatrixVariable(value: 'page', pathVar: 'segment', required: false, defaultValue: '0') int page,
    @MatrixVariable(value: 'size', pathVar: 'segment', required: false, defaultValue: '10') int size,
  ) async {
    final cleanSegment = segment.split(';').first;
    final posts = q == null || q.isEmpty
        ? (await _posts.findPublicFeed(
            PageRequest(page: page.clamp(0, 1000), size: size.clamp(1, 100)),
          )).content
        : await _posts.search(q, limit: size.clamp(1, 100));
    return {
      'segment': cleanSegment,
      'query': ?q,
      'page': page,
      'size': size,
      'count': posts.length,
      'posts': [for (final p in posts) p.toJson()],
    };
  }
}
