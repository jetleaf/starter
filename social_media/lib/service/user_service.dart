/// User registration, profile lookup, follow graph and suggestions.
library;


import 'package:jetleaf/jetleaf.dart';

import '../domain/user.dart';
import '../exception/social_pulse_exception.dart';
import '../repository/user_repository.dart';
import '../repository/comment_like_follow_notification_repository.dart';
import '../events/social_pulse_events.dart';
import '../util/ids.dart';
import '../util/page.dart';

@Service()
class UserService {
  UserService(this._users, this._follows, this._clock, this._applicationContext);

  final UserRepository _users;
  final FollowRepository _follows;
  final SocialClock _clock;
  final ApplicationContext _applicationContext;

  static final RegExp _handlePattern = RegExp(r'^[a-z0-9][a-z0-9_.]{2,29}[a-z0-9]$');

  Future<UserProfile> register({
    required String handle,
    required String displayName,
    String bio = '',
    String? avatarUrl,
  }) async {
    final normalized = handle.trim().toLowerCase();
    if (!_handlePattern.hasMatch(normalized)) {
      throw const InvalidMediaException(
          'Handle must be 4-31 chars of a-z, 0-9, "." or "_" and cannot start or end with "." or "_".');
    }
    if (await _users.existsByHandle(normalized)) {
      throw DuplicateHandleException(normalized);
    }
    final user = UserProfile(
      id: Ids.prefixed('usr'),
      handle: normalized,
      displayName: displayName.trim(),
      bio: bio.trim(),
      avatarUrl: avatarUrl,
      createdAt: _clock.now(),
    );
    final saved = await _users.save(user);
    await _applicationContext.publishEvent(UserRegisteredEvent(saved));
    return saved;
  }

  Future<UserProfile> requireByHandle(String handle) async {
    final user = await _users.findByHandle(handle);
    if (user == null) {
      throw UserNotFoundException(handle);
    }
    return user;
  }

  Future<UserProfile> requireActiveByHandle(String handle) async {
    final user = await requireByHandle(handle);
    if (user.isSuspended) {
      throw SuspendedAccountException(handle);
    }
    return user;
  }

  Future<UserProfile> updateProfile(String handle,
      {String? displayName, String? bio, String? avatarUrl}) async {
    final user = await requireActiveByHandle(handle);
    return _users.update(user.copyWith(
      displayName: displayName?.trim(),
      bio: bio?.trim(),
      avatarUrl: avatarUrl,
    ));
  }

  Future<UserProfile> suspend(String handle) async {
    final user = await requireByHandle(handle);
    return _users.update(user.copyWith(status: UserStatus.suspended));
  }

  Future<bool> follow(String followerHandle, String followeeHandle) async {
    final follower = await requireActiveByHandle(followerHandle);
    final followee = await requireActiveByHandle(followeeHandle);
    final created = await _follows.follow(follower.id, followee.id);
    if (created) {
      final updatedFollower =
          await _users.update(follower.copyWith(followingCount: follower.followingCount + 1));
      final updatedFollowee =
          await _users.update(followee.copyWith(followersCount: followee.followersCount + 1));
      await _applicationContext
          .publishEvent(UserFollowedEvent(updatedFollower, updatedFollowee));
    }
    return created;
  }

  Future<bool> unfollow(String followerHandle, String followeeHandle) async {
    final follower = await requireActiveByHandle(followerHandle);
    final followee = await requireActiveByHandle(followeeHandle);
    final removed = await _follows.unfollow(follower.id, followee.id);
    if (removed) {
      await _users.update(
          follower.copyWith(followingCount: (follower.followingCount - 1).clamp(0, 1 << 31)));
      await _users.update(
          followee.copyWith(followersCount: (followee.followersCount - 1).clamp(0, 1 << 31)));
    }
    return removed;
  }

  Future<Page<UserProfile>> followersOf(String handle, PageRequest page) async {
    final user = await requireByHandle(handle);
    final ids = await _follows.followerIds(user.id);
    final users = await _users.findByIds(ids);
    return Page(
      content: users.skip(page.offset).take(page.size).toList(growable: false),
      totalElements: users.length,
      page: page.page,
      size: page.size,
    );
  }

  Future<Page<UserProfile>> followingOf(String handle, PageRequest page) async {
    final user = await requireByHandle(handle);
    final ids = await _follows.followingIds(user.id);
    final users = await _users.findByIds(ids);
    return Page(
      content: users.skip(page.offset).take(page.size).toList(growable: false),
      totalElements: users.length,
      page: page.page,
      size: page.size,
    );
  }

  Future<List<String>> followingIds(String userId) => _follows.followingIds(userId);

  /// Cheap "who to follow": up to [limit] accounts with the most followers
  /// that the viewer does not already follow and is not suspended.
  Future<List<UserProfile>> suggestions(String viewerHandle, {int limit = 10}) async {
    final viewer = await requireByHandle(viewerHandle);
    final alreadyFollowing = (await _follows.followingIds(viewer.id)).toSet();
    final candidates = await _users.findAll(page: const PageRequest(page: 0, size: 100));
    final suggestions = candidates
        .where((u) =>
            u.id != viewer.id &&
            !u.isSuspended &&
            !alreadyFollowing.contains(u.id))
        .toList()
      ..sort((a, b) => b.followersCount.compareTo(a.followersCount));
    return suggestions.take(limit).toList(growable: false);
  }

  Future<List<UserProfile>> search(String query, {int limit = 20}) =>
      _users.search(query, limit: limit);

  Future<int> count() => _users.count();
}
