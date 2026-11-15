import 'package:jetleaf/jetleaf.dart';

import 'diagnostics_provider.dart';

/// Fallback diagnostics used when no explicit profile is activated.
/// Activates under the framework's built-in default profile.
@Service()
@Profile(['default'])
class DefaultDiagnosticsProvider implements DiagnosticsProvider {
  @override
  String get name => 'default';

  @override
  bool get betaTooling => false;

  @override
  Map<String, Object?> describe() => {
        'provider': name,
        'betaTooling': betaTooling,
        'logLevel': 'INFO',
        'traceEndpoints': false,
      };
}
