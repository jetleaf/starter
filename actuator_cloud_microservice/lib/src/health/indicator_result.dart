/// Result of a single health indicator check.
final class IndicatorResult {
  final String status;
  final Duration duration;
  final Map<String, Object?> details;

  IndicatorResult({
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
