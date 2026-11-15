/// Posts: creation with moderation gate, likes, comments, search, export.
library;

import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_actuator/jetleaf_actuator.dart';

import '../domain/comment.dart';
import '../domain/post.dart';
import '../exception/social_pulse_exception.dart';
import '../events/social_pulse_events.dart';
import '../repository/comment_like_follow_notification_repository.dart';
import '../repository/post_repository.dart';
import '../repository/user_repository.dart';
import '../util/ids.dart';
import '../util/page.dart';
import 'feed_ranker.dart';

@Monitor('postService')
@Service()
class PostService {
  PostService(
    this._posts,
    this._comments,
    this._likes,
    this._users,
    this._applicationContext,
    this._ranker,
    this._clock,
  );

  final PostRepository _posts;
  final CommentRepository _comments;
  final LikeRepository _likes;
  final UserRepository _users;
  final ApplicationContext _applicationContext;
  final FeedRanker _ranker;
  final SocialClock _clock;

  static final RegExp _mentionPattern = RegExp(r'@([a-z0-9_.]{3,32})');

  Future<Post> createPost({
    required String authorId,
    required String authorHandle,
    required String content,
    required PostVisibility visibility,
    List<PostMedia> media = const [],
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty && media.isEmpty) {
      throw const ContentRejectedException('A post needs text or at least one media item.');
    }
    if (trimmed.length > 500) {
      throw const ContentRejectedException('Posts are limited to 500 characters.');
    }
    _rejectSpam(trimmed);

    final post = Post(
      id: Ids.prefixed('post'),
      authorId: authorId,
      authorHandle: authorHandle,
      content: trimmed,
      visibility: visibility,
      media: media,
      tags: Post.extractTags(trimmed),
      createdAt: _clock.now(),
    );
    await _posts.save(post);
    final author = await _users.findById(authorId);
    if (author != null) {
      await _users.update(author.copyWith(postsCount: author.postsCount + 1));
    }
    await _applicationContext.publishEvent(PostCreatedEvent(post));
    for (final match in _mentionPattern.allMatches(trimmed)) {
      await _applicationContext.publishEvent(MentionDetectedEvent(post, match.group(1)!));
    }
    return post;
  }

  static final RegExp _spamPattern = RegExp(
    r'(buy\s+now|free\s+money|crypto\s+airdrop|click\s+here\s+now)',
    caseSensitive: false,
  );

  void _rejectSpam(String content) {
    if (_spamPattern.hasMatch(content)) {
      throw const ContentRejectedException('Content matched anti-spam heuristics.');
    }
  }

  Future<Post> requireVisible(String postId) async {
    final post = await _posts.findById(postId);
    if (post == null || post.isDeleted) {
      throw PostNotFoundException(postId);
    }
    return post;
  }

  Future<Post> deletePost(String postId, String actorId, {bool moderator = false}) async {
    final post = await requireVisible(postId);
    if (post.authorId != actorId && !moderator) {
      throw const ForbiddenActionException('only the author or a moderator can delete this post');
    }
    await _posts.softDelete(postId);
    await _applicationContext.publishEvent(PostDeletedEvent(postId, post.authorId));
    return post;
  }

  Future<Post> likePost(String postId, String userId) async {
    final post = await requireVisible(postId);
    final created = await _likes.like(postId, userId);
    final updated = await _posts.incrementLikes(postId, delta: created ? 1 : 0);
    if (created) {
      await _applicationContext.publishEvent(PostLikedEvent(updated ?? post, userId));
    }
    return updated ?? post;
  }

  Future<Post> unlikePost(String postId, String userId) async {
    final post = await requireVisible(postId);
    final removed = await _likes.unlike(postId, userId);
    final updated = await _posts.incrementLikes(postId, delta: removed ? -1 : 0);
    if (removed) {
      await _applicationContext.publishEvent(PostUnlikedEvent(postId, userId));
    }
    return updated ?? post;
  }

  Future<Comment> addComment({
    required String postId,
    required String authorId,
    required String authorHandle,
    required String content,
  }) async {
    final post = await requireVisible(postId);
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw const ContentRejectedException('Comment cannot be empty.');
    }
    if (trimmed.length > 1000) {
      throw const ContentRejectedException('Comments are limited to 1000 characters.');
    }
    final comment = Comment(
      id: Ids.prefixed('cmt'),
      postId: post.id,
      authorId: authorId,
      authorHandle: authorHandle,
      content: trimmed,
      createdAt: _clock.now(),
    );
    await _comments.save(comment);
    await _posts.incrementComments(postId, delta: 1);
    await _applicationContext.publishEvent(CommentAddedEvent(comment, post.authorId));
    return comment;
  }

  Future<List<Comment>> commentsOf(String postId, {int limit = 100}) async {
    await requireVisible(postId);
    return _comments.findByPost(postId, limit: limit);
  }

  Future<Page<Post>> postsByAuthor(String authorId, PageRequest page) async {
    final posts = await _posts.findByAuthor(authorId, page: page);
    final total = await _posts.countByAuthor(authorId);
    return Page(content: posts, totalElements: total, page: page.page, size: page.size);
  }

  Future<Page<Post>> homeTimeline(Iterable<String> followeeIds, PageRequest page) async {
    return _posts.findTimeline(followeeIds, page);
  }

  Future<Page<Post>> globalFeed(PageRequest page) => _posts.findPublicFeed(page);

  Future<List<Post>> postsByTag(String tag, {PageRequest page = const PageRequest(size: 20)}) =>
      _posts.findByTag(tag, page: page);

  Future<List<Post>> search(String query, {int limit = 20}) => _posts.search(query, limit: limit);

  Future<Post> reportPost(String postId, String reporterId, String reason) async {
    final post = await requireVisible(postId);
    final updated = await _posts.incrementReports(postId);
    final reports = updated?.reports ?? post.reports + 1;
    await _applicationContext
        .publishEvent(PostReportedEvent(postId, reporterId, reason, reports));
    return updated ?? post.copyWith(reports: reports);
  }

  /// Streaming-friendly full export of public posts (NDJSON).
  Future<Iterable<Post>> exportPublicPosts() async {
    final feed = await _posts.findPublicFeed(const PageRequest(page: 0, size: 100));
    return feed.content;
  }

  Future<List<Post>> trending({int limit = 10}) async {
    final feed = await _posts.findPublicFeed(const PageRequest(page: 0, size: 100));
    final ranked = _ranker.rank(feed.content, const PageRequest(page: 0, size: 100), _clock.now());
    return ranked.content.take(limit).toList(growable: false);
  }
}
