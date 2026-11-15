import 'package:jetleaf/jetleaf.dart';

import 'lifecycle_log.dart';

/// Lifecycle demo: @PreDestroy runs on graceful shutdown (SIGTERM/SIGINT).
@Service()
class ShutdownMarker {
  static final Log _logger = LogFactory.getLog(ShutdownMarker);

  final LifecycleLog _log;

  ShutdownMarker(this._log) {
    _log.record('ShutdownMarker constructor ran');
  }

  @PreDestroy()
  void destroy() {
    _log.record('ShutdownMarker @PreDestroy destroy() ran — container closing');
    _logger.info('Graceful shutdown: resources released by ShutdownMarker');
  }
}
