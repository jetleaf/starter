/// Community moderation: report triage and automatic account action.
library;

import '../domain/notification.dart';
import '../domain/user.dart';
import '../repository/post_repository.dart';
import '../repository/user_repository.dart';
import '../util/page.dart';
import '../util/stereotypes.dart';
import 'notification_service.dart';

@CommunityModerator()
class ModerationService {
  ModerationService(this._posts, this._users, this._notifications);

  final PostRepository _posts;
  final UserRepository _users;
  final NotificationService _notifications;

  static const int autoSuspendThreshold = 5;
  static const int trendingWindow = 100;

  /// Called after every report. When a post crosses the threshold the author
  /// is suspended and a system notification records the action.
  Future<void> evaluatePost(String postId) async {
    final post = await _posts.findById(postId);
    if (post == null) return;
    if (post.reports < autoSuspendThreshold) return;

    final author = await _users.findById(post.authorId);
    if (author == null || author.isSuspended) return;

    await _users.update(author.copyWith(status: UserStatus.suspended));
    await _notifications.notify(
      userId: author.id,
      kind: NotificationKind.reportThreshold,
      message:
          'Your account was suspended automatically: post $postId received ${post.reports} reports.',
    );
  }

  /// Reported posts queue for manual review (most-reported first).
  Future<List<Map<String, dynamic>>> reviewQueue({int limit = 20}) async {
    final feed = await _posts.findPublicFeed(const PageRequest(page: 0, size: trendingWindow));
    final reported = feed.content.where((p) => p.reports > 0).toList()
      ..sort((a, b) => b.reports.compareTo(a.reports));
    return [
      for (final post in reported.take(limit))
        {
          'postId': post.id,
          'authorHandle': post.authorHandle,
          'reports': post.reports,
          'contentPreview': post.content.length > 120
              ? '${post.content.substring(0, 120)}…'
              : post.content,
        },
    ];
  }
}
