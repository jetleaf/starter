// SocialPulse tests — plain package:test with direct instantiation,
// matching starter-project conventions.
import 'package:test/test.dart';

import 'package:social_media/domain/post.dart';
import 'package:social_media/domain/user.dart';
import 'package:social_media/domain/notification.dart';
import 'package:social_media/exception/social_pulse_exception.dart';
import 'package:social_media/repository/post_repository.dart';
import 'package:social_media/repository/user_repository.dart';
import 'package:social_media/repository/comment_like_follow_notification_repository.dart';
import 'package:social_media/service/feed_ranker.dart';
import 'package:social_media/util/page.dart';

void main() {
  group('FeedRanker', () {
    const ranker = FeedRanker();

    test('fresher post with equal engagement wins', () {
      final now = DateTime.utc(2026, 11, 14, 12);
      final fresh = Post(
        id: 'a', authorId: 'u', authorHandle: 'a', content: 'fresh',
        createdAt: now.subtract(const Duration(hours: 1)), likes: 10,
      );
      final stale = Post(
        id: 'b', authorId: 'u', authorHandle: 'b', content: 'stale',
        createdAt: now.subtract(const Duration(hours: 12)), likes: 10,
      );
      expect(ranker.scoreOf(fresh, now), greaterThan(ranker.scoreOf(stale, now)));
    });

    test('engagement dominates pure recency past a threshold', () {
      final now = DateTime.utc(2026, 11, 14, 12);
      // Very high signal: even a full day older, decay cannot hide 5000 likes.
      final highSignal = Post(
        id: 'a', authorId: 'u', authorHandle: 'a', content: 'hot',
        createdAt: now.subtract(const Duration(hours: 24)), likes: 5000, comments: 400,
      );
      final quiet = Post(
        id: 'b', authorId: 'u', authorHandle: 'b', content: 'quiet',
        createdAt: now.subtract(const Duration(minutes: 5)), likes: 0, comments: 0,
      );
      expect(ranker.scoreOf(highSignal, now), greaterThan(ranker.scoreOf(quiet, now)));
    });
  });

  group('InMemoryUserRepository', () {
    test('save + findByHandle round-trips and enforces uniqueness by caller', () async {
      final users = InMemoryUserRepository();
      final ada = UserProfile(
        id: 'usr_1',
        handle: 'ada',
        displayName: 'Ada Okoye',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      await users.save(ada);
      expect((await users.findByHandle('ada'))?.displayName, 'Ada Okoye');
      expect(await users.existsByHandle('ADA'), isTrue, reason: 'handle lookup is case-insensitive');
      expect((await users.search('ada')).single.id, 'usr_1');
    });

    test('search is case-insensitive on handle and display name', () async {
      final users = InMemoryUserRepository();
      await users.save(UserProfile(
        id: 'usr_1',
        handle: 'bola',
        displayName: 'Bola Tinubu',
        createdAt: DateTime.utc(2026, 1, 1),
      ));
      expect(await users.search('TINUBU'), isNotEmpty);
      expect(await users.search('bola'), isNotEmpty);
    });
  });

  group('InMemoryPostRepository', () {
    test('save + findById + softDelete hides the post', () async {
      final posts = InMemoryPostRepository();
      final post = Post(
        id: 'post_1',
        authorId: 'u1',
        authorHandle: 'ada',
        content: 'hello #jetleaf',
        createdAt: DateTime.utc(2026, 11, 1),
        tags: Post.extractTags('hello #jetleaf'),
      );
      await posts.save(post);
      expect((await posts.findById('post_1'))?.content, contains('jetleaf'));
      await posts.softDelete('post_1');
      expect((await posts.findById('post_1'))!.isDeleted, isTrue);
      expect((await posts.findByTag('jetleaf')), isEmpty);
    });

    test('findTimeline only returns posts from the followee set', () async {
      final posts = InMemoryPostRepository();
      final now = DateTime.utc(2026, 11, 14);
      Post p(String id, String authorId) => Post(
            id: id,
            authorId: authorId,
            authorHandle: authorId,
            content: 'x',
            createdAt: now,
          );
      await posts.save(p('a', 'u1'));
      await posts.save(p('b', 'u2'));
      await posts.save(p('c', 'u3'));
      final page = await posts.findTimeline(['u1', 'u3'], const PageRequest(size: 10));
      expect(page.content.map((e) => e.id).toSet(), {'a', 'c'});
    });

    test('incrementLikes clamps at zero', () async {
      final posts = InMemoryPostRepository();
      await posts.save(Post(
        id: 'p', authorId: 'u', authorHandle: 'u', content: 'c', createdAt: DateTime.utc(2026),
        likes: 2,
      ));
      await posts.incrementLikes('p', delta: -5);
      expect((await posts.findById('p'))!.likes, 0);
    });
  });

  group('notification fan-out primitives', () {
    test('unread count + markAllRead drains the inbox', () async {
      final notifications = InMemoryNotificationRepository();
      final now = DateTime.utc(2026, 11, 14);
      for (var i = 0; i < 3; i++) {
        await notifications.save(AppNotification(
          id: 'n$i',
          userId: 'u1',
          kind: NotificationKind.like,
          message: 'note $i',
          createdAt: now,
        ));
      }
      await notifications.save(AppNotification(
        id: 'other',
        userId: 'u2',
        kind: NotificationKind.follow,
        message: 'note u2',
        createdAt: now,
      ));
      expect(await notifications.unreadCount('u1'), 3);
      expect(await notifications.markAllRead('u1'), 3);
      expect(await notifications.unreadCount('u1'), 0);
      expect(await notifications.unreadCount('u2'), 1);
    });
  });

  group('content rules', () {
    test('hashtag extraction finds and lowercases tags', () {
      expect(Post.extractTags('shipping #Jetleaf with #DART today'), ['jetleaf', 'dart']);
      expect(Post.extractTags('no tags here'), isEmpty);
    });

    test('handle validation regex accepts only legal handles', () {
      final legal = RegExp(r'^[a-z0-9][a-z0-9_.]{2,29}[a-z0-9]$');
      expect(legal.hasMatch('ada_okoye'), isTrue);
      expect(legal.hasMatch('a'), isFalse);
      expect(legal.hasMatch('-bad'), isFalse);
      expect(legal.hasMatch('two..dots'), isTrue); // allowed: dots mid-handle
      expect(legal.hasMatch('trail.'), isFalse);
    });

    test('domain errors carry RFC7807-shaped metadata', () {
      const error = DuplicateHandleException('ada');
      expect(error.status, 409);
      expect(error.code, 'duplicate_handle');
    });
  });
}
