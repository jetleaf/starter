import 'package:jetleaf/jetleaf.dart';

import 'lifecycle_log.dart';

/// Simulates an expensive, lazily-initialized dependency.
///
/// The expensive part (e.g. warming a query cache, loading a model file)
/// happens in the constructor, so construction is only worth doing on first
/// actual use — hence [@Lazy] is declared at the injection point.
@Service()
@Lazy()
class ExpensiveReportService {
  static int _constructionCount = 0;

  final int constructionIndex;
  final Duration bootTime;
  final LifecycleLog _log;

  ExpensiveReportService(this._log)
      : constructionIndex = ++_constructionCount,
        bootTime = const Duration(milliseconds: 150) {
    _log.record('ExpensiveReportService constructed (instance #$constructionIndex)');
  }

  static int get constructionCount => _constructionCount;

  Map<String, Object?> describe() => {
        'constructionCount': constructionCount,
        'constructionIndex': constructionIndex,
        'origin': 'expensive',
      };
}
