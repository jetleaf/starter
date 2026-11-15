/// Operational health indicators surfaced at `/health/*`.
///
/// Same contract as the actuator pattern: `name` + async `check()` returning
/// an `IndicatorResult`. Registered as pods and aggregated by `HealthService`.
library;

import 'package:jetleaf/jetleaf.dart';

import '../repository/post_repository.dart';
import '../repository/user_repository.dart';

final class IndicatorResult {
  final String status;
  final Duration duration;
  final Map<String, Object?> details;

  const IndicatorResult({
    required this.status,
    required this.duration,
    this.details = const {},
  });

  bool get isUp => status == 'UP';

  Map<String, Object?> toJson() => {
        'status': status,
        'duration_ms': duration.inMilliseconds,
        if (details.isNotEmpty) 'details': details,
      };
}

abstract class HealthIndicatorService {
  String get name;
  Future<IndicatorResult> check();
}

@Service()
class FeedStoreHealthIndicator implements HealthIndicatorService {
  FeedStoreHealthIndicator(this._posts, this._users);

  final PostRepository _posts;
  final UserRepository _users;

  @override
  String get name => 'feed-store';

  @override
  Future<IndicatorResult> check() async {
    final stopwatch = Stopwatch()..start();
    try {
      final posts = await _posts.count();
      final users = await _users.count();
      stopwatch.stop();
      return IndicatorResult(
        status: 'UP',
        duration: stopwatch.elapsed,
        details: {'posts': posts, 'users': users, 'backend': 'in-memory'},
      );
    } catch (e) {
      stopwatch.stop();
      return IndicatorResult(
        status: 'DOWN',
        duration: stopwatch.elapsed,
        details: {'error': e.toString()},
      );
    }
  }
}

@Service()
class PushGatewayHealthIndicator implements HealthIndicatorService {
  @override
  String get name => 'push-gateway';

  @override
  Future<IndicatorResult> check() async {
    final stopwatch = Stopwatch()..start();
    await Future<void>.delayed(const Duration(milliseconds: 2));
    stopwatch.stop();
    return IndicatorResult(
      status: 'UP',
      duration: stopwatch.elapsed,
      details: const {'probe': 'simulated-gateway', 'region': 'local'},
    );
  }
}

@Service()
class HealthService {
  HealthService(FeedStoreHealthIndicator feed, PushGatewayHealthIndicator push)
      : indicators = [feed, push];

  final List<HealthIndicatorService> indicators;

  Future<Map<String, Object?>> health() async {
    final results = <String, Object?>{};
    var overall = 'UP';
    for (final indicator in indicators) {
      final result = await indicator.check();
      results[indicator.name] = result.toJson();
      if (!result.isUp) overall = 'DOWN';
    }
    return {'status': overall, 'indicators': results};
  }

  Future<Map<String, Object?>> liveness() async => {'status': 'UP'};

  Future<Map<String, Object?>> readiness() async {
    final report = await health();
    return {'status': report['status']};
  }
}
