import 'package:jetleaf/jetleaf.dart';

import '../telemetry/models.dart';

/// In-memory, thread-safe telemetry aggregator.
///
/// Keeps rolling aggregates per (deviceId, metric), tracks ingestion
/// throughput over a sliding one-minute window, and never holds raw events
/// beyond ingestion.
@Service()
class IngestionService {
  final Map<String, MetricAggregate> _aggregates = {};
  final List<DateTime> _recentIngestions = [];
  int _totalIngested = 0;
  DateTime? _lastIngestAt;

  /// Ingests a batch of events. Returns the count accepted.
  int ingestBatch(List<Map<String, dynamic>> rawEvents) {
    var accepted = 0;
    final now = DateTime.now().toUtc();

    for (final raw in rawEvents) {
      final event = TelemetryEvent.fromJson(raw);
      if (event.deviceId.isEmpty || event.metric.isEmpty) {
        continue; // skip malformed rows silently — producers retry upstream
      }

      final key = '${event.deviceId}|${event.metric}';
      (_aggregates[key] ??= MetricAggregate()).add(event.value, event.timestamp);
      accepted++;
    }

    _totalIngested += accepted;
    _lastIngestAt = now;
    _recentIngestions.addAll(List.filled(accepted, now));
    _pruneWindow(now);

    return accepted;
  }

  void _pruneWindow(DateTime now) {
    final cutoff = now.subtract(const Duration(minutes: 1));
    while (_recentIngestions.isNotEmpty && _recentIngestions.first.isBefore(cutoff)) {
      _recentIngestions.removeAt(0);
    }
  }

  /// Events ingested within the trailing one-minute window.
  int get recentEvents {
    _pruneWindow(DateTime.now().toUtc());
    return _recentIngestions.length;
  }

  /// Ingest rate (events/second) over the trailing minute.
  double get eventsPerSecond => recentEvents / 60.0;

  int get totalIngested => _totalIngested;

  /// Aggregates grouped by device.
  Map<String, Object?> summary() {
    final byDevice = <String, Map<String, Object?>>{};

    for (final entry in _aggregates.entries) {
      final parts = entry.key.split('|');
      final deviceId = parts.first;
      final metric = parts.length > 1 ? parts[1] : 'unknown';
      byDevice.putIfAbsent(deviceId, () => {})[metric] = entry.value.toJson();
    }

    return {
      'totalIngested': _totalIngested,
      'recentEventsPerMinute': recentEvents,
      'eventsPerSecond': eventsPerSecond,
      'lastIngestAt': _lastIngestAt?.toIso8601String(),
      'devices': byDevice,
    };
  }
}
