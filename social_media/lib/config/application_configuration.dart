/// Application ports & factory-method wiring for SocialPulse.
///
/// Demonstrates the `@Configuration` + `@Pod` extension surface:
/// interface ports with multiple candidates disambiguated by `@Primary` /
/// `@Qualifier`, conditional registration via a custom `Condition`, and
/// scalar binding through `@Value`.
library;

import 'package:jetleaf/jetleaf.dart';

import '../service/external_push_client.dart';

/// Outbound notification sink — implemented by log (default) and external push.
abstract interface class NotificationDispatcher {
  Future<void> dispatch(String userId, String title, String body);
}

/// Default dispatcher: structured log. Always available.
class LogNotificationDispatcher implements NotificationDispatcher {
  static final Log _logger = LogFactory.getLog(LogNotificationDispatcher);

  @override
  Future<void> dispatch(String userId, String title, String body) async {
    _logger.info('NOTIFY user=$userId title="$title" body="$body"');
  }
}

/// External dispatcher: routes through [ExternalPushClient] (flaky gateway).
class ExternalNotificationDispatcher implements NotificationDispatcher {
  ExternalNotificationDispatcher(this._client);

  final ExternalPushClient _client;

  @override
  Future<void> dispatch(String userId, String title, String body) async {
    final receipt = await _client.send('device:$userId', title, body);
    if (!receipt.delivered) {
      throw IllegalStateException('push dispatch failed: ${receipt.detail}');
    }
  }
}

/// Custom condition: activates the external dispatcher only when the push
/// gateway is enabled in configuration (`social.push.enabled=true`).
///
/// Constant constructor + implements [Condition] — the two rules for
/// `@Conditional` predicates.
final class PushEnabledCondition implements Condition {
  const PushEnabledCondition();

  @override
  Future<bool> matches(ConditionalContext context, Annotation annotation, Source source) async {
    final raw = context.environment.getProperty('social.push.enabled')?.toString().toLowerCase();
    return raw == null || raw == 'true';
  }
}

@Configuration()
class SocialPulseConfiguration {
  @Pod()
  SocialFeedPolicy socialFeedPolicy(@Value('#{social.feed.pageSize:20}') int pageSize) =>
      SocialFeedPolicy(pageSize: pageSize);

  @Pod()
  @Primary()
  NotificationDispatcher logDispatcher() => LogNotificationDispatcher();

  @Pod(value: 'externalDispatcher')
  @Conditional([PushEnabledCondition()])
  NotificationDispatcher externalDispatcher(ExternalPushClient push) =>
      ExternalNotificationDispatcher(push);
}

/// Small value object created via factory method + `@Value` binding.
final class SocialFeedPolicy {
  SocialFeedPolicy({required this.pageSize});

  final int pageSize;

  Map<String, Object?> toJson() => {'pageSize': pageSize};
}
