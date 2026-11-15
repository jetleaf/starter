/// In-process metrics counters + anonymous analytics sink.
///
/// Deliberately framework-free so the same counters can be surfaced through
/// `jetleaf_actuator` (see `config/social_media_metrics.dart`) without any
/// coupling to the metering backend.
library;

import 'package:jetleaf/jetleaf.dart';

@Service()
class AnalyticsService {
  final Map<String, int> _counters = HashMap();
  final List<String> _recentEvents = [];
  static const int _maxRecentEvents = 50;

  int increment(String metric, [int delta = 1]) =>
      _counters.update(metric, (v) => v + delta, ifAbsent: () => delta);

  int counter(String metric) => _counters[metric] ?? 0;

  Map<String, int> snapshot() => Map.unmodifiable(_counters);

  void track(String event) {
    _recentEvents.insert(0, event);
    if (_recentEvents.length > _maxRecentEvents) {
      _recentEvents.removeRange(_maxRecentEvents, _recentEvents.length);
    }
  }

  List<String> recentEvents() => List.unmodifiable(_recentEvents);
}
