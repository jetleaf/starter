/// Health check data shared by every service in the cluster.
library;

class IndicatorResult {
  const IndicatorResult({
    required this.status,
    required this.duration,
    this.details = const {},
  });

  final String status;
  final Duration duration;
  final Map<String, Object?> details;

  bool get isUp => status == 'UP';

  Map<String, Object?> toJson() => {
        'status': status,
        'duration_ms': duration.inMilliseconds,
        if (details.isNotEmpty) 'details': details,
      };
}
