/// Posts API — creation, likes, comments, reporting, tag feeds, export.
library;

import 'dart:convert';

import 'package:jetleaf_web/jetleaf_web.dart';

import '../../domain/post.dart';
import '../../exception/social_pulse_exception.dart';
import '../../service/post_service.dart';
import '../../service/user_service.dart';
import '../../util/page.dart';
import '../../web/dto/bean_validator.dart';
import '../../web/dto/requests.dart';
import '../../repository/post_repository.dart';

@CrossOrigin(origins: ['https://socialpulse.example.com'], methods: [HttpMethod.GET, HttpMethod.POST], allowedHeaders: ['Content-Type', 'X-User'], maxAge: 3600)
@RestController('/api/posts')
class PostController {
  PostController(this._posts, this._users, this._validator, this._postRepository);

  final PostService _posts;
  final UserService _users;
  final BeanValidator _validator;
  final PostRepository _postRepository;

  /// Create a post as the actor identified by `X-User`.
  @PostMapping()
    Future<ResponseBody<Map<String, dynamic>>> createPost(
    @RequestAttribute(value: 'actorHandle') String actor,
    @RequestBody() Map<String, dynamic> body,
  ) async {
    final request = _validator.validateOrThrow(CreatePostRequest.fromJson(body));
    final author = await _users.requireActiveByHandle(actor);

    final visibility = switch (request.visibility) {
      'followers' => PostVisibility.followers,
      'unlisted' => PostVisibility.unlisted,
      _ => PostVisibility.publicPost,
    };
    final media = [for (final url in request.mediaUrls) PostMedia(url: url)];

    final post = await _posts.createPost(
      authorId: author.id,
      authorHandle: author.handle,
      content: request.content,
      visibility: visibility,
      media: media,
    );
    return ResponseBody.of(HttpStatus.CREATED, post.toJson());
  }

  /// Fetch a single visible post.
  @GetMapping(path: '/{id}')
  Future<Map<String, dynamic>> getPost(@PathVariable(value: 'id') String id) async =>
      (await _posts.requireVisible(id)).toJson();

  /// Delete a post — author or moderator (`X-Admin-Key` for moderation path).
  @DeleteMapping(path: '/{id}')
  Future<Map<String, dynamic>> deletePost(
    @PathVariable(value: 'id') String id,
    @RequestAttribute(value: 'actorHandle') String actor,
    @RequestHeader(value: 'X-Admin-Key', required: false) String? adminKey,
  ) async {
    final author = await _users.requireByHandle(actor);
    final post = await _posts.deletePost(id, author.id, moderator: adminKey != null);
    return {'deleted': post.id};
  }

  @PostMapping(path: '/{id}/like')
  Future<Map<String, dynamic>> likePost(
    @PathVariable(value: 'id') String id,
    @RequestAttribute(value: 'actorHandle') String actor,
  ) async {
    final user = await _users.requireActiveByHandle(actor);
    final post = await _posts.likePost(id, user.id);
    return {'postId': post.id, 'likes': post.likes};
  }

  @DeleteMapping(path: '/{id}/like')
  Future<Map<String, dynamic>> unlikePost(
    @PathVariable(value: 'id') String id,
    @RequestAttribute(value: 'actorHandle') String actor,
  ) async {
    final user = await _users.requireActiveByHandle(actor);
    final post = await _posts.unlikePost(id, user.id);
    return {'postId': post.id, 'likes': post.likes};
  }

  @PostMapping(path: '/{id}/comments')
    Future<ResponseBody<Map<String, dynamic>>> addComment(
    @PathVariable(value: 'id') String id,
    @RequestAttribute(value: 'actorHandle') String actor,
    @RequestBody() Map<String, dynamic> body,
  ) async {
    final request = _validator.validateOrThrow(CreateCommentRequest.fromJson(body));
    final user = await _users.requireActiveByHandle(actor);
    final comment = await _posts.addComment(
      postId: id,
      authorId: user.id,
      authorHandle: user.handle,
      content: request.content,
    );
    return ResponseBody.of(HttpStatus.CREATED, comment.toJson());
  }

  @GetMapping(path: '/{id}/comments')
  Future<List<Map<String, dynamic>>> listComments(
    @PathVariable(value: 'id') String id,
    @RequestParam(value: 'limit', required: false, defaultValue: '100') int limit,
  ) async {
    final comments = await _posts.commentsOf(id, limit: limit.clamp(1, 500));
    return [for (final c in comments) c.toJson()];
  }

  @PostMapping(path: '/{id}/report')
    Future<ResponseBody<Map<String, dynamic>>> reportPost(
    @PathVariable(value: 'id') String id,
    @RequestAttribute(value: 'actorHandle') String actor,
    @RequestBody() Map<String, dynamic> body,
  ) async {
    final request = _validator.validateOrThrow(ReportPostRequest.fromJson(body));
    final user = await _users.requireByHandle(actor);
    final post = await _posts.reportPost(id, user.id, request.reason);
    return ResponseBody.of(HttpStatus.ACCEPTED, {'postId': post.id, 'reports': post.reports});
  }

  /// Trending board — ranked public posts.
  @GetMapping(path: '/trending')
  Future<Map<String, dynamic>> trending(
    @RequestParam(value: 'limit', required: false, defaultValue: '10') int limit,
  ) async {
    final posts = await _posts.trending(limit: limit.clamp(1, 50));
    return {
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'posts': [for (final p in posts) p.toJson()],
    };
  }

  /// Posts for a hashtag — `GET /api/posts/tag/{tag}?page=0&size=20`
  @GetMapping(path: '/tag/{tag}')
  Future<Map<String, dynamic>> byTag(
    @PathVariable(value: 'tag') String tag,
    @RequestParam(value: 'page', required: false, defaultValue: '0') int page,
    @RequestParam(value: 'size', required: false, defaultValue: '20') int size,
  ) async {
    final posts = await _posts.postsByTag(tag,
        page: PageRequest(page: page.clamp(0, 1000), size: size.clamp(1, 100)));
    return {'tag': tag.toLowerCase().replaceFirst('#', ''), 'posts': [for (final p in posts) p.toJson()]};
  }

  /// Full-text search — `GET /api/posts/search?q=jetleaf&limit=20`
  @GetMapping(path: '/search')
  Future<Map<String, dynamic>> search(
    @RequestParam(value: 'q') String query,
    @RequestParam(value: 'limit', required: false, defaultValue: '20') int limit,
  ) async {
    if (query.trim().isEmpty) {
      throw const ContentRejectedException('search query must not be empty');
    }
    final posts = await _posts.search(query, limit: limit.clamp(1, 100));
    return {'query': query, 'count': posts.length, 'posts': [for (final p in posts) p.toJson()]};
  }

  /// NDJSON export of the public feed — streamed chunk-by-chunk.
  @GetMapping(path: '/export/stream', produces: [MediaType('application', 'x-ndjson')])
  Future<void> exportStream(ServerHttpResponse response) async {
    response.setStatus(HttpStatus.OK);
    response.getHeaders().setContentType(const MediaType('application', 'x-ndjson'));

    final out = response.getBody();
    final feed = await _postRepository.findPublicFeed(const PageRequest(page: 0, size: 100));
    for (final post in feed.content) {
      await out.writeString('${jsonEncode(post.toJson())}\n');
      await out.flush();
    }
    await out.writeString('{"type":"end","exported":${feed.content.length}}\n');
    await out.close();
  }
}
