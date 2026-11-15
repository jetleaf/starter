import 'package:jetleaf/jetleaf.dart';

import 'diagnostics_provider.dart';

/// Staging profile — production-like posture, beta tooling allowed.
@Service()
@Profile(['staging'])
class StagingDiagnosticsProvider implements DiagnosticsProvider {
  @override
  String get name => 'staging';

  @override
  bool get betaTooling => true;

  @override
  Map<String, Object?> describe() => {
        'provider': name,
        'betaTooling': betaTooling,
        'logLevel': 'INFO',
        'traceEndpoints': false,
      };
}
