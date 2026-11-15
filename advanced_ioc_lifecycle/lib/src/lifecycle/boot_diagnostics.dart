import 'package:jetleaf/jetleaf.dart';

import 'lifecycle_log.dart';

/// Lifecycle demo: constructor → @PostConstruct.
@Service()
class BootDiagnostics {
  final LifecycleLog _log;

  BootDiagnostics(this._log) {
    _log.record('BootDiagnostics constructor ran');
  }

  @PostConstruct()
  void init() {
    _log.record('BootDiagnostics @PostConstruct init() ran');
  }

}
