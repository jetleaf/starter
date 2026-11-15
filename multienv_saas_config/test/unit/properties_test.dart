import 'package:test/test.dart';

import 'package:multienv_saas_config/src/config/saas_properties.dart';

void main() {
  group('Configuration properties defaults', () {
    test('SaasProperties has sensible defaults', () {
      final props = SaasProperties();
      expect(props.name, 'Unknown');
      expect(props.region, 'us-east-1');
    });

    test('RateLimitProperties defaults to 100 requests', () {
      expect(RateLimitProperties().maxRequests, 100);
    });

    test('FeatureProperties defaults', () {
      final features = FeatureProperties();
      expect(features.auditLog, isTrue);
      expect(features.betaDashboard, isFalse);
    });
  });
}
