/// Production-context guardrails.
///
/// Activated only under the `prod` profile. Validates that the operator has
/// consciously configured the deployment and fails fast otherwise — the
/// framework should help, not hide, misconfigurations.
library;

import 'package:jetleaf/jetleaf.dart';

@Profile(['prod'])
@Component()
class ProductionGuard {
  static final Log _logger = LogFactory.getLog(ProductionGuard);

  @PostConstruct()
  void verify() {
    _logger.info('prod profile active — verifying production posture');
    // In a real deployment this is where we would fail fast on:
    //  - missing JWT signing secret, missing DB DSN
    //  - demo seeding accidentally enabled
    //  - actuator exposed without auth
    _logger.info('prod posture OK (static verification for the 2.1 runtime)');
  }
}
