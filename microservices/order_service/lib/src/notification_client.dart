/// HTTP client for the notification service — fire-and-forget with retry.
library;

import 'package:jetleaf/jetleaf.dart';
import 'package:microservices_common/microservices_common.dart';

final class NotificationDispatchResult {
  const NotificationDispatchResult({required this.sent, required this.detail});

  final bool sent;
  final String detail;

  Map<String, dynamic> toJson() => {'sent': sent, 'detail': detail};
}

@Service()
class NotificationClient implements EnvironmentAware {
  Environment? _environment;

  @override
  void setEnvironment(Environment environment) {
    _environment = environment;
  }

  bool get notificationsEnabled {
    final raw = _environment?.getProperty('services.notification.enabled');
    return raw == null || raw.toString().toLowerCase() != 'false';
  }

  String get baseUrl {
    final raw = _environment?.getProperty('services.notification.base-url');
    return (raw is String && raw.isNotEmpty) ? raw : 'http://localhost:8083';
  }

  Future<NotificationDispatchResult> send({
    required String customerId,
    required String title,
    required String body,
    required String kind,
  }) async {
    if (!notificationsEnabled) {
      return const NotificationDispatchResult(
        sent: false,
        detail: 'notifications disabled by configuration (services.notification.enabled=false)',
      );
    }

    final client = ServiceHttpClient(
      service: 'notification',
      baseUrl: baseUrl,
      timeout: const Duration(seconds: 2),
      retryMaxAttempts: 2,
    );
    try {
      final exchange = await client.post('/notifications', {
        'customerId': customerId,
        'title': title,
        'body': body,
        'kind': kind,
      });
      if (exchange.status >= 200 && exchange.status < 300) {
        return const NotificationDispatchResult(sent: true, detail: 'notification persisted');
      }
      return NotificationDispatchResult(
        sent: false,
        detail: 'notification-service answered ${exchange.status}',
      );
    } finally {
      await client.close();
    }
  }
}
