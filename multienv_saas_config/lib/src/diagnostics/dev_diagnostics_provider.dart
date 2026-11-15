import 'package:jetleaf/jetleaf.dart';

import 'diagnostics_provider.dart';

/// Dev profile — verbose diagnostics, beta tooling on, no audit pressure.
@Service()
@Profile(['dev'])
class DevDiagnosticsProvider implements DiagnosticsProvider {
  @override
  String get name => 'dev';

  @override
  bool get betaTooling => true;

  @override
  Map<String, Object?> describe() => {
        'provider': name,
        'betaTooling': betaTooling,
        'logLevel': 'DEBUG',
        'traceEndpoints': true,
      };
}
