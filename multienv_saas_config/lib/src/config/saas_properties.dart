import 'package:jetleaf_core/annotation.dart';

/// Binds the `app.*` base properties (shared by all profiles).
///
/// Note: Jetleaf binds fields by exact name (`app.name`, `app.region`).
@ConfigurationProperty(prefix: 'app')
class SaasProperties {
  String name = 'Unknown';
  String region = 'us-east-1';
}

/// Binds the `app.rate-limit.*` properties.
@ConfigurationProperty(prefix: 'app.rate-limit')
class RateLimitProperties {
  /// Maximum number of API requests allowed per tenant per minute.
  int maxRequests = 100;
}

/// Binds the `app.features.*` feature flags.
@ConfigurationProperty(prefix: 'app.features')
class FeatureProperties {
  bool auditLog = true;
  bool betaDashboard = false;
}
