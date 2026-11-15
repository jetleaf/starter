/// Home timeline & global feed API.
library;

import 'package:jetleaf_web/jetleaf_web.dart';

import '../../service/post_service.dart';
import '../../service/user_service.dart';
import '../../util/page.dart';

@RestController('/api/feed')
class FeedController {
  FeedController(this._posts, this._users);

  final PostService _posts;
  final UserService _users;

  /// Viewer's home timeline — posts from accounts they follow, scored by
  /// engagement/age decay.
  @GetMapping(path: '/home')
  Future<Map<String, dynamic>> home(
    @RequestAttribute(value: 'actorHandle') String actor,
    @RequestParam(value: 'page', required: false, defaultValue: '0') int page,
    @RequestParam(value: 'size', required: false, defaultValue: '20') int size,
  ) async {
    final viewer = await _users.requireActiveByHandle(actor);
    final followeeIds = await _users.followingIds(viewer.id);
    final timeline = await _posts.homeTimeline(
        followeeIds, PageRequest(page: page.clamp(0, 1000), size: size.clamp(1, 100)));
    return timeline.toJson((p) => p.toJson());
  }

  /// Global public feed — unauthenticated.
  @GetMapping(path: '/global')
  Future<Map<String, dynamic>> globalFeed(
    @RequestParam(value: 'page', required: false, defaultValue: '0') int page,
    @RequestParam(value: 'size', required: false, defaultValue: '20') int size,
  ) async {
    final feed = await _posts.globalFeed(
        PageRequest(page: page.clamp(0, 1000), size: size.clamp(1, 100)));
    return feed.toJson((p) => p.toJson());
  }
}
