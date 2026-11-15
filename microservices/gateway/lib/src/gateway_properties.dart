/// Gateway routing configuration — where each downstream service lives.
///
/// In production these URLs would come from the service registry; for this
/// reference they come from `services.*.base-url` in `application.yaml`.
library;

import 'package:jetleaf/jetleaf.dart';
import 'package:microservices_common/microservices_common.dart';

@Service()
class GatewayProperties implements EnvironmentAware {
  Environment? _environment;

  @override
  void setEnvironment(Environment environment) {
    _environment = environment;
  }

  String get userBaseUrl => _read('services.user.base-url', 'http://localhost:8081');
  String get orderBaseUrl => _read('services.order.base-url', 'http://localhost:8082');
  String get notificationBaseUrl => _read('services.notification.base-url', 'http://localhost:8083');

  int get userTimeoutMs => int.tryParse(_read('services.user.timeoutMs', '2000')) ?? 2000;
  int get orderTimeoutMs => int.tryParse(_read('services.order.timeoutMs', '2000')) ?? 2000;
  int get notificationTimeoutMs => int.tryParse(_read('services.notification.timeoutMs', '2000')) ?? 2000;

  bool get notificationsEnabled =>
      _read('services.notification.enabled', 'true').toLowerCase() != 'false';

  Map<String, String> get services => {
        'user': userBaseUrl,
        'order': orderBaseUrl,
        'notification': notificationBaseUrl,
      };

  int timeoutFor(String name) => switch (name) {
        'user' => userTimeoutMs,
        'order' => orderTimeoutMs,
        'notification' => notificationTimeoutMs,
        _ => 2000,
      };

  String baseUrlFor(String name) {
    final url = services[name];
    if (url == null) {
      throw ServiceUnavailableException(name);
    }
    return url;
  }

  String _read(String key, String defaultValue) {
    final raw = _environment?.getProperty(key);
    return (raw is String && raw.isNotEmpty) ? raw : defaultValue;
  }
}
