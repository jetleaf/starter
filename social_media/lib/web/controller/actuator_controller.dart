/// Actuator-style operational endpoints.
///
/// `/actuator/health`, `/actuator/liveness`, `/actuator/readiness`,
/// `/actuator/metrics`, `/actuator/info` — deliberately public for k8s probes.
library;

import 'package:jetleaf_web/jetleaf_web.dart';

import '../../health/social_health.dart';
import '../../service/analytics_service.dart';
import '../../config/social_properties.dart';

@RestController('/actuator')
class ActuatorController {
  ActuatorController(this._health, this._analytics, this._feed, this._rateLimit, this._features);

  final HealthService _health;
  final AnalyticsService _analytics;
  final FeedProperties _feed;
  final RateLimitProperties _rateLimit;
  final FeatureProperties _features;

  @GetMapping(path: '/health')
  Future<Map<String, Object?>> health() => _health.health();

  @GetMapping(path: '/liveness')
  Future<Map<String, Object?>> liveness() => _health.liveness();

  @GetMapping(path: '/readiness')
  Future<Map<String, Object?>> readiness() => _health.readiness();

  @GetMapping(path: '/metrics')
  Map<String, Object?> metrics() => {
        'counters': _analytics.snapshot(),
        'recentEvents': _analytics.recentEvents(),
      };

  @GetMapping(path: '/info')
  Map<String, Object?> info() => {
        'app': {
          'name': 'SocialPulse',
          'description': 'Production-grade social media platform on Jetleaf 2.1',
          'version': '1.0.0',
        },
        'config': {
          'feed.pageSize': _feed.pageSize,
          'feed.maxPageSize': _feed.maxPageSize,
          'rateLimit.requestsPerMinute': _rateLimit.requestsPerMinute,
          'features.ssrEnabled': _features.ssrEnabled,
          'features.pushEnabled': _features.pushEnabled,
        },
      };
}
