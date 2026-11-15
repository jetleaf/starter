/// Typed, environment-bound configuration for SocialPulse.
///
/// Binds from `application.yaml` (and profile cascades) through Jetleaf's
/// `@ConfigurationProperty` — exact-field matching against relaxed keys.
library;

import 'package:jetleaf/jetleaf.dart';

@ConfigurationProperty(prefix: 'social.feed')
class FeedProperties {
  /// Default page size for paginated feeds.
  int pageSize = 20;

  /// Maximum page size a client may request.
  int maxPageSize = 100;

  /// How often the trending pipeline recomputes scores.
  int trendingRefreshSeconds = 30;
}

@ConfigurationProperty(prefix: 'social.rate-limit')
class RateLimitProperties {
  /// Requests per minute per API key before throttling kicks in.
  int requestsPerMinute = 600;

  /// Requests per minute for admin endpoints.
  int adminRequestsPerMinute = 60;
}

@ConfigurationProperty(prefix: 'social.push')
class PushProperties {
  /// Master switch for external push fan-out.
  bool enabled = true;

  /// Burst size for fan-out batching.
  int batchSize = 100;
}

@ConfigurationProperty(prefix: 'social.media')
class MediaProperties {
  /// Maximum upload size in bytes for any single media item.
  int maxUploadBytes = 5 * 1024 * 1024;

  /// Comma-separated allow-list of upload MIME types.
  String allowedTypes = 'image/png,image/jpeg,image/gif,image/webp';
}

@ConfigurationProperty(prefix: 'social.features')
class FeatureProperties {
  /// Serve JTL-rendered HTML profile + trending pages.
  bool ssrEnabled = true;

  /// Expose `/actuator/*` operational endpoints.
  bool actuatorExposed = true;

  /// Enable the (simulated) external push pipeline.
  bool pushEnabled = true;
}

@ConfigurationProperty(prefix: 'social.moderation')
class ModerationProperties {
  /// Reports against a post before the author is auto-suspended.
  int autoSuspendThreshold = 5;
}
