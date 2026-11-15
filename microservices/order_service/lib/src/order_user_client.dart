/// HTTP client for the user service — used to validate customers at write time.
///
/// Uses the shared client (single retry with backoff, 2s timeout).
library;

import 'package:jetleaf/jetleaf.dart';
import 'package:microservices_common/microservices_common.dart';

class CustomerSummary {
  const CustomerSummary({required this.id, required this.handle, required this.tier});

  final String id;
  final String handle;
  final String tier;
}

@Service()
class OrderUserClient implements EnvironmentAware {
  Environment? _environment;

  @override
  void setEnvironment(Environment environment) {
    _environment = environment;
  }

  String get baseUrl {
    final raw = _environment?.getProperty('services.user.base-url');
    return (raw is String && raw.isNotEmpty) ? raw : 'http://localhost:8081';
  }

  /// Returns the customer summary, or null when the user service says the
  /// customer does not exist, or throws [ServiceUnavailableException] when the
  /// user service is unreachable.
  Future<CustomerSummary?> findCustomer(String customerId) async {
    final client = ServiceHttpClient(
      service: 'user',
      baseUrl: baseUrl,
      timeout: const Duration(seconds: 2),
      retryMaxAttempts: 2,
    );
    try {
      final exchange = await client.get('/users/$customerId');
      if (exchange.status == 404) {
        return null; // genuinely missing customer — no point retrying
      }
      if (exchange.status < 200 || exchange.status >= 300) {
        throw const ServiceUnavailableException('user');
      }
      final json = exchange.decodeJsonObject();
      if (json == null) {
        throw const FormatException('user-service returned malformed JSON');
      }
      return CustomerSummary(
        id: json['id'] as String,
        handle: json['handle'] as String,
        tier: (json['tier'] as String?) ?? 'standard',
      );
    } finally {
      await client.close();
    }
  }
}
