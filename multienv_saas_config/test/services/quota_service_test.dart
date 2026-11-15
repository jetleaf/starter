import 'package:test/test.dart';

import 'package:multienv_saas_config/src/config/saas_properties.dart';
import 'package:multienv_saas_config/src/services/quota_service.dart';

void main() {
  group('QuotaService', () {
    test('remainingBudget is max minus used, clamped at zero', () {
      final service = QuotaService(RateLimitProperties()..maxRequests = 100);
      expect(service.remainingBudget(0), 100);
      expect(service.remainingBudget(40), 60);
      expect(service.remainingBudget(100), 0);
      expect(service.remainingBudget(150), 0);
    });

    test('isExhausted flips at the configured limit', () {
      final service = QuotaService(RateLimitProperties()..maxRequests = 50);
      expect(service.isExhausted(49), isFalse);
      expect(service.isExhausted(50), isTrue);
      expect(service.isExhausted(51), isTrue);
    });

    test('describe includes tenant, budget and exhaustion flag', () {
      final service = QuotaService(RateLimitProperties()..maxRequests = 10);
      final view = service.describe(tenant: 'acme', usedRequests: 10);
      expect(view['tenant'], 'acme');
      expect(view['maxRequestsPerMinute'], 10);
      expect(view['remainingRequests'], 0);
      expect(view['exhausted'], isTrue);
    });
  });
}
