/// Contract for environment-specific diagnostics.
/// Exactly one implementation is active at runtime, selected by the active profile.
abstract interface class DiagnosticsProvider {
  /// Human-readable name of this diagnostics implementation.
  String get name;

  /// Whether beta-only diagnostic tooling is enabled in this environment.
  bool get betaTooling;

  /// Diagnostics payload exposed on /api/v1/config/status.
  Map<String, Object?> describe();
}
