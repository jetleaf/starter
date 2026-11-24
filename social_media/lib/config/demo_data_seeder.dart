/// Dev-only demo data seeder — never active in production.
///
/// Wired with `@Profile(['dev'])` so the pod vanishes from the production
/// context entirely; production deploys must pass `--spring.profiles.active=prod`
/// (or the `jetleaf.profiles.active` property) and will *not* get synthetic users.
library;

import 'package:jetleaf/jetleaf.dart';

import '../domain/user.dart';
import '../domain/post.dart';
import '../repository/comment_like_follow_notification_repository.dart';
import '../repository/post_repository.dart';
import '../repository/user_repository.dart';
import '../util/ids.dart';

@Profile(['dev'])
@Component()
class DemoDataSeeder implements CommandLineRunner {
  DemoDataSeeder(this._users, this._posts, this._follows, this._likes, this._clock);

  static final Log _logger = LogFactory.getLog(DemoDataSeeder);

  final UserRepository _users;
  final PostRepository _posts;
  final FollowRepository _follows;
  final LikeRepository _likes;
  final SocialClock _clock;

  @override
  int getOrder() => 100;

  @override
  Future<void> run(List<String> args) async {
    final now = _clock.now();
    _logger.info('demo seeder: populating local workspace');

    final seedUsers = [
      UserProfile(
        id: 'usr_demoada',
        handle: 'ada',
        displayName: 'Ada Okoye',
        bio: 'Dart & Jetleaf fanatic. Shipping backends that behave.',
        roles: const [UserRole.member],
        followersCount: 2,
        followingCount: 1,
        postsCount: 2,
        createdAt: now.subtract(const Duration(days: 120)),
      ),
      UserProfile(
        id: 'usr_demobola',
        handle: 'bola',
        displayName: 'Bola Tinubu',
        bio: 'Community manager @ SocialPulse',
        roles: const [UserRole.moderator],
        followersCount: 1,
        followingCount: 2,
        postsCount: 1,
        createdAt: now.subtract(const Duration(days: 90)),
      ),
      UserProfile(
        id: 'usr_demochidi',
        handle: 'chidi',
        displayName: 'Chidi Nwosu',
        bio: 'Staff engineer. Federation > centralization.',
        roles: const [UserRole.member],
        followersCount: 1,
        followingCount: 1,
        postsCount: 1,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
    ];

    for (final user in seedUsers) {
      await _users.save(user);
    }

    await _follows.follow('usr_demoada', 'usr_demobola');
    await _follows.follow('usr_demobola', 'usr_demoada');
    await _follows.follow('usr_demobola', 'usr_demochidi');
    await _follows.follow('usr_demochidi', 'usr_demoada');

    final ada = seedUsers.first;
    final chidi = seedUsers.last;
    final posts = [
      Post(
        id: 'post_demo1',
        authorId: ada.id,
        authorHandle: ada.handle,
        content: 'Just shipped a Jetleaf-powered API. AOT cold start is unreal. #jetleaf #dart',
        tags: const ['jetleaf', 'dart'],
        likes: 24,
        comments: 3,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      Post(
        id: 'post_demo2',
        authorId: ada.id,
        authorHandle: ada.handle,
        content: 'Designing feed ranking: engagement / age^1.5 works surprisingly well. #feeds',
        tags: const ['feeds'],
        likes: 15,
        comments: 1,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      Post(
        id: 'post_demo3',
        authorId: chidi.id,
        authorHandle: chidi.handle,
        content: 'Microservices with Jetleaf: gateway + retry-recover is 80% of the pattern.',
        tags: const ['jetleaf', 'microservices'],
        likes: 31,
        comments: 4,
        createdAt: now.subtract(const Duration(minutes: 40)),
      ),
    ];
    for (final post in posts) {
      await _posts.save(post);
    }
    await _likes.like('post_demo1', chidi.id);
    await _likes.like('post_demo3', ada.id);

    final seededPosts = posts.length;
    _logger.info('demo seeder: ${seedUsers.length} users, $seededPosts posts, follows & likes wired');
  }
}
