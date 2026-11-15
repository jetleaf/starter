/// Periodic digest job — demonstrates field-injection disambiguation:
/// `@Autowired` + `@TargetType<Interface>()` + `@Qualifier`, and `@Lazy`
/// pod initialization at the class level.
library;

import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_scheduling/jetleaf_scheduling.dart';

import '../config/application_configuration.dart';
import '../repository/user_repository.dart';
import '../util/page.dart';

/// Expensive, lazily-initialized recommender. The pod is only constructed
/// on first injection — never at startup.
@Lazy()
@Component()
class RecommendationEngine {
  RecommendationEngine() {
    LogFactory.getLog(RecommendationEngine).info('recommendation engine warmed');
  }

  /// Cheap heuristic: first N candidate ids.
  Future<List<String>> suggest(String viewerId, List<String> candidateIds) async =>
      candidateIds.take(3).toList(growable: false);
}

@Service()
class DigestService {
  DigestService(this._users, this._recommendations);

  static final Log _logger = LogFactory.getLog(DigestService);

  final UserRepository _users;
  final RecommendationEngine _recommendations;

  /// External push path — disambiguated by qualifier among two candidates
  /// (`logDispatcher` primary vs `externalDispatcher`).
  @Autowired()
  @TargetType<NotificationDispatcher>()
  @Qualifier('externalDispatcher')
  late NotificationDispatcher externalDispatcher;

  /// Daily digest at 06:00 — shallow implementation proving the wiring works.
  @Scheduled(cron: '0 0 6 * * *')
  Future<void> sendDailyDigest() async {
    final sample = await _users.findAll(page: const PageRequest(page: 0, size: 5));
    final suggestions = await _recommendations.suggest(
      'digest',
      sample.map((u) => u.id).toList(),
    );
    for (final user in sample) {
      try {
        await externalDispatcher.dispatch(
          user.id,
          'Your SocialPulse digest',
          'Catch up with the conversation, ${user.displayName}.',
        );
      } catch (e) {
        _logger.warn('digest push failed for ${user.id}: $e');
      }
    }
    _logger.info('digest fanned out to ${suggestions.length} workspace member(s)');
  }
}
