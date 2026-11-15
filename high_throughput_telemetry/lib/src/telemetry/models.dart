/// A single telemetry reading submitted for ingestion.
class TelemetryEvent {
  final String deviceId;
  final String metric;
  final double value;
  final DateTime timestamp;

  TelemetryEvent({
    required this.deviceId,
    required this.metric,
    required this.value,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().toUtc();

  factory TelemetryEvent.fromJson(Map<String, dynamic> json) {
    return TelemetryEvent(
      deviceId: json['deviceId']?.toString() ?? '',
      metric: json['metric']?.toString() ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      timestamp: json['ts'] is String ? DateTime.tryParse(json['ts'] as String)?.toUtc() : null,
    );
  }

  Map<String, Object?> toJson() => {
        'deviceId': deviceId,
        'metric': metric,
        'value': value,
        'ts': timestamp.toIso8601String(),
      };
}

/// Rolling aggregate for one (deviceId, metric) pair.
class MetricAggregate {
  int count = 0;
  double sum = 0;
  double? min;
  double? max;
  double? last;
  DateTime? lastSeen;

  void add(double value, DateTime at) {
    count++;
    sum += value;
    if (min == null || value < min!) min = value;
    if (max == null || value > max!) max = value;
    last = value;
    lastSeen = at;
  }

  double get average => count == 0 ? 0 : sum / count;

  Map<String, Object?> toJson() => {
        'count': count,
        'min': min,
        'max': max,
        'avg': average,
        'last': last,
        'lastSeen': lastSeen?.toIso8601String(),
      };
}
