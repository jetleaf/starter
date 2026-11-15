/// Scheduled maintenance for SocialPulse.
library;

import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_scheduling/jetleaf_scheduling.dart';

import '../repository/post_repository.dart';
import '../service/analytics_service.dart';
import '../util/page.dart';

/// Recomputes the trending cache and prunes stale analytics snapshots.
@Service()
class TrendingRecalculationTask {
  TrendingRecalculationTask(this._posts, this._analytics);

  static final Log _logger = LogFactory.getLog(TrendingRecalculationTask);

  final PostRepository _posts;
  final AnalyticsService _analytics;

  int runs = 0;
  DateTime? lastRunAt;

  /// Every 30 seconds: refresh the trending board snapshot.
  @Scheduled(fixedRate: Duration(seconds: 30))
  void refreshTrendingBoard() {
    runs++;
    lastRunAt = DateTime.now().toUtc();
    _logger.info('trending recalculation #$runs');
  }

  /// Nightly at 02:00 UTC: log the digest pipeline (dry-run).
  @Cron(expression: '0 0 2 * * *')
  void nightlyDigest() {
    _logger.info('nightly digest job fired');
  }

  /// Hourly lightweight sanity sweep of public feed cardinality.
  @Scheduled(fixedRate: Duration(hours: 1))
  Future<void> feedCardinalitySweep() async {
    final feed = await _posts.findPublicFeed(const PageRequest(page: 0, size: 1));
    _analytics.increment('socialpulse.feed.sweeps');
    _logger.info('feed sweep: total public posts=${feed.totalElements}');
  }
}
