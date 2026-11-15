import 'package:jetleaf/jetleaf.dart';

import 'diagnostics_provider.dart';

/// Prod profile — locked-down diagnostics, beta tooling off.
@Service()
@Profile(['prod'])
class ProdDiagnosticsProvider implements DiagnosticsProvider {
  @override
  String get name => 'prod';

  @override
  bool get betaTooling => false;

  @override
  Map<String, Object?> describe() => {
        'provider': name,
        'betaTooling': betaTooling,
        'logLevel': 'WARN',
        'traceEndpoints': false,
      };
}
