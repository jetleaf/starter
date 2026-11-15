/// Comment, like, follow and notification persistence (in-memory).
library;

import 'package:jetleaf/jetleaf.dart';

import '../domain/comment.dart';
import '../domain/follow.dart';
import '../domain/notification.dart';

abstract class CommentRepository {
  Future<Comment> save(Comment comment);
  Future<Comment?> findById(String id);
  Future<List<Comment>> findByPost(String postId, {int limit = 100});
  Future<int> countByPost(String postId);
}

@Repository()
class InMemoryCommentRepository implements CommentRepository {
  final Map<String, Comment> _byId = {};

  @override
  Future<Comment> save(Comment comment) async {
    _byId[comment.id] = comment;
    return comment;
  }

  @override
  Future<Comment?> findById(String id) async => _byId[id];

  @override
  Future<List<Comment>> findByPost(String postId, {int limit = 100}) async {
    final matched = _byId.values.where((c) => c.postId == postId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matched.take(limit).toList(growable: false);
  }

  @override
  Future<int> countByPost(String postId) async =>
      _byId.values.where((c) => c.postId == postId).length;
}

abstract class LikeRepository {
  /// Returns true when the like was created, false when it already existed.
  Future<bool> like(String postId, String userId);
  /// Returns true when the unlike removed a like, false when none existed.
  Future<bool> unlike(String postId, String userId);
  Future<bool> isLiked(String postId, String userId);
  Future<List<String>> likersOf(String postId, {int limit = 100});
}

@Repository()
class InMemoryLikeRepository implements LikeRepository {
  final Map<String, Like> _likes = {};

  @override
  Future<bool> like(String postId, String userId) async {
    final key = '$postId::$userId';
    if (_likes.containsKey(key)) return false;
    _likes[key] = Like(postId: postId, userId: userId, createdAt: DateTime.now().toUtc());
    return true;
  }

  @override
  Future<bool> unlike(String postId, String userId) async {
    return _likes.remove('$postId::$userId') != null;
  }

  @override
  Future<bool> isLiked(String postId, String userId) async =>
      _likes.containsKey('$postId::$userId');

  @override
  Future<List<String>> likersOf(String postId, {int limit = 100}) async =>
      _likes.values.where((l) => l.postId == postId).map((l) => l.userId).take(limit).toList();
}

abstract class FollowRepository {
  Future<bool> follow(String followerId, String followeeId);
  Future<bool> unfollow(String followerId, String followeeId);
  Future<bool> isFollowing(String followerId, String followeeId);
  Future<List<String>> followingIds(String userId);
  Future<List<String>> followerIds(String userId);
  Future<int> followingCount(String userId);
  Future<int> followerCount(String userId);
}

@Repository()
class InMemoryFollowRepository implements FollowRepository {
  final Map<String, Follow> _follows = {};

  @override
  Future<bool> follow(String followerId, String followeeId) async {
    if (followerId == followeeId) return false;
    final key = '$followerId::$followeeId';
    if (_follows.containsKey(key)) return false;
    _follows[key] =
        Follow(followerId: followerId, followeeId: followeeId, createdAt: DateTime.now().toUtc());
    return true;
  }

  @override
  Future<bool> unfollow(String followerId, String followeeId) async =>
      _follows.remove('$followerId::$followeeId') != null;

  @override
  Future<bool> isFollowing(String followerId, String followeeId) async =>
      _follows.containsKey('$followerId::$followeeId');

  @override
  Future<List<String>> followingIds(String userId) async =>
      _follows.values.where((f) => f.followerId == userId).map((f) => f.followeeId).toList();

  @override
  Future<List<String>> followerIds(String userId) async =>
      _follows.values.where((f) => f.followeeId == userId).map((f) => f.followerId).toList();

  @override
  Future<int> followingCount(String userId) async =>
      _follows.values.where((f) => f.followerId == userId).length;

  @override
  Future<int> followerCount(String userId) async =>
      _follows.values.where((f) => f.followeeId == userId).length;
}

abstract class NotificationRepository {
  Future<AppNotification> save(AppNotification notification);
  Future<List<AppNotification>> findUnread(String userId, {int limit = 50});
  Future<List<AppNotification>> findByUser(String userId, {PageRequestSlice page = const PageRequestSlice()});
  Future<int> markAllRead(String userId);
  Future<int> unreadCount(String userId);
}

class PageRequestSlice {
  const PageRequestSlice({this.offset = 0, this.limit = 20});
  final int offset;
  final int limit;
}

@Repository()
class InMemoryNotificationRepository implements NotificationRepository {
  final Map<String, AppNotification> _byId = {};

  @override
  Future<AppNotification> save(AppNotification notification) async {
    _byId[notification.id] = notification;
    return notification;
  }

  @override
  Future<List<AppNotification>> findUnread(String userId, {int limit = 50}) async {
    return _unreadSorted(userId).take(limit).toList(growable: false);
  }

  @override
  Future<List<AppNotification>> findByUser(String userId,
      {PageRequestSlice page = const PageRequestSlice()}) async {
    final all = _byId.values.where((n) => n.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all.skip(page.offset).take(page.limit).toList(growable: false);
  }

  @override
  Future<int> markAllRead(String userId) async {
    var count = 0;
    for (final n in _byId.values) {
      if (n.userId == userId && !n.read) {
        n.read = true;
        count++;
      }
    }
    return count;
  }

  @override
  Future<int> unreadCount(String userId) async => _unreadSorted(userId).length;

  List<AppNotification> _unreadSorted(String userId) {
    final unread = _byId.values.where((n) => n.userId == userId && !n.read).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return unread;
  }
}
