/// Post persistence contract + in-memory implementation.
library;

import 'package:jetleaf/jetleaf.dart';

import '../domain/post.dart';
import '../util/page.dart';

abstract class PostRepository {
  Future<Post?> findById(String id);
  Future<Post> save(Post post);
  Future<List<Post>> findByAuthor(String authorId, {PageRequest page = const PageRequest()});
  Future<int> countByAuthor(String authorId);
  Future<Page<Post>> findTimeline(Iterable<String> authorIds, PageRequest page);
  Future<Page<Post>> findPublicFeed(PageRequest page);
  Future<List<Post>> findByTag(String tag, {PageRequest page = const PageRequest()});
  Future<List<Post>> search(String query, {int limit = 20});
  Future<void> softDelete(String id);
  Future<Post?> incrementLikes(String postId, {required int delta});
  Future<Post?> incrementComments(String postId, {required int delta});
  Future<Post?> incrementReports(String postId);
  Future<int> count();
}

@Repository()
class InMemoryPostRepository implements PostRepository {
  final Map<String, Post> _byId = {};

  @override
  Future<Post?> findById(String id) async => _byId[id];

  @override
  Future<Post> save(Post post) async {
    _byId[post.id] = post;
    return post;
  }

  int _compare(Post a, Post b, PageRequest page) {
    final result = page.sortField == 'likes'
        ? a.likes.compareTo(b.likes)
        : a.createdAt.compareTo(b.createdAt);
    return page.descending ? -result : result;
  }

  @override
  Future<List<Post>> findByAuthor(String authorId,
      {PageRequest page = const PageRequest()}) async {
    final own = _byId.values.where((p) => p.authorId == authorId && !p.isDeleted).toList()
      ..sort((a, b) => _compare(a, b, page));
    return own.skip(page.offset).take(page.size).toList(growable: false);
  }

  @override
  Future<int> countByAuthor(String authorId) async =>
      _byId.values.where((p) => p.authorId == authorId && !p.isDeleted).length;

  @override
  Future<Page<Post>> findTimeline(Iterable<String> authorIds, PageRequest page) async {
    final authors = authorIds.toSet();
    final matched = _byId.values
        .where((p) => authors.contains(p.authorId) && !p.isDeleted)
        .toList()
      ..sort((a, b) => _compare(a, b, page));
    return Page(
      content: matched.skip(page.offset).take(page.size).toList(growable: false),
      totalElements: matched.length,
      page: page.page,
      size: page.size,
    );
  }

  @override
  Future<Page<Post>> findPublicFeed(PageRequest page) async {
    final matched = _byId.values.where((p) => p.isVisibleToPublic).toList()
      ..sort((a, b) => _compare(a, b, page));
    return Page(
      content: matched.skip(page.offset).take(page.size).toList(growable: false),
      totalElements: matched.length,
      page: page.page,
      size: page.size,
    );
  }

  @override
  Future<List<Post>> findByTag(String tag, {PageRequest page = const PageRequest()}) async {
    final normalized = tag.toLowerCase().replaceFirst(RegExp('^#'), '');
    final matched = _byId.values
        .where((p) => p.tags.contains(normalized) && !p.isDeleted)
        .toList()
      ..sort((a, b) => _compare(a, b, page));
    return matched.skip(page.offset).take(page.size).toList(growable: false);
  }

  @override
  Future<List<Post>> search(String query, {int limit = 20}) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _byId.values
        .where((p) => !p.isDeleted && p.content.toLowerCase().contains(q))
        .take(limit)
        .toList(growable: false);
  }

  @override
  Future<void> softDelete(String id) async {
    final post = _byId[id];
    if (post != null) {
      _byId[id] = post.copyWith(deletedAt: DateTime.now().toUtc());
    }
  }

  @override
  Future<Post?> incrementLikes(String postId, {required int delta}) async {
    final post = _byId[postId];
    if (post == null) return null;
    final updated = post.copyWith(likes: (post.likes + delta).clamp(0, 1 << 31));
    _byId[postId] = updated;
    return updated;
  }

  @override
  Future<Post?> incrementComments(String postId, {required int delta}) async {
    final post = _byId[postId];
    if (post == null) return null;
    final updated = post.copyWith(comments: (post.comments + delta).clamp(0, 1 << 31));
    _byId[postId] = updated;
    return updated;
  }

  @override
  Future<Post?> incrementReports(String postId) async {
    final post = _byId[postId];
    if (post == null) return null;
    final updated = post.copyWith(reports: post.reports + 1);
    _byId[postId] = updated;
    return updated;
  }

  @override
  Future<int> count() async => _byId.length;
}
