/// Operations API — moderation queue, counters, actuator-style health.
///
/// All endpoints require the `X-Admin-Key` header (enforced by SecurityFilter).
library;

import 'package:jetleaf_web/jetleaf_web.dart';

import '../../service/analytics_service.dart';
import '../../service/moderation_service.dart';
import '../../service/post_service.dart';
import '../../service/user_service.dart';
import '../../scheduling/trending_recalculation_task.dart';
import '../../config/application_configuration.dart';
import '../../util/page.dart';

@RestController('/api/admin')
class AdminController {
  AdminController(
    this._moderation,
    this._analytics,
    this._posts,
    this._users,
    this._feedPolicy,
    this._trendingTask,
  );

  final ModerationService _moderation;
  final AnalyticsService _analytics;
  final PostService _posts;
  final UserService _users;
  final SocialFeedPolicy _feedPolicy;
  final TrendingRecalculationTask _trendingTask;

  /// Posts waiting for moderator review (most-reported first).
  @GetMapping(path: '/review-queue')
  Future<Map<String, dynamic>> reviewQueue(
    @RequestParam(value: 'limit', required: false, defaultValue: '20') int limit,
  ) async =>
      {'queue': await _moderation.reviewQueue(limit: limit.clamp(1, 100))};

  /// Snapshot of the in-process counters (feeds the dashboard).
  @GetMapping(path: '/metrics')
  Map<String, Object?> metrics() => {
        'generatedAt': DateTime.now().toUtc().toIso8601String(),
        'counters': _analytics.snapshot(),
        'recentEvents': _analytics.recentEvents(),
      };

  /// Suspend a user (moderation action).
  @PostMapping(path: '/users/{handle}/suspend')
  Future<Map<String, dynamic>> suspend(@PathVariable(value: 'handle') String handle) async {
    final user = await _users.suspend(handle);
    return {'suspended': user.handle, 'status': user.status.name};
  }

  /// Runtime configuration snapshot — binds what `@ConfigurationProperty` bound.
  @GetMapping(path: '/policy')
  Map<String, Object?> policy() => {
        'feedPolicy': _feedPolicy.toJson(),
        'trendingTask': {
          'runs': _trendingTask.runs,
          'lastRunAt': _trendingTask.lastRunAt?.toIso8601String(),
        },
      };

  /// Liveness/readiness probe for the process.
  @GetMapping(path: '/probe')
  Future<Map<String, Object?>> probe() async {
    return {
      'status': 'UP',
      'checkedAt': DateTime.now().toUtc().toIso8601String(),
      'feedSweeps': _trendingTask.runs,
      'users': await _users.count(),
      'publicPosts': (await _posts.globalFeed(const PageRequest(page: 0, size: 1))).totalElements,
    };
  }
}
