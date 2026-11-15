import 'package:jetleaf/jetleaf.dart';

/// In-memory recorder of container lifecycle events.
/// Exposed on the REST API to make scope/order behavior observable.
@Service()
class LifecycleLog {
  static final Log _logger = LogFactory.getLog(LifecycleLog);

  final List<String> _entries = [];

  void record(String event) {
    final entry = '[${DateTime.now().toUtc().toIso8601String()}] $event';
    _entries.add(entry);
    _logger.info(entry);
  }

  List<String> get entries => List.unmodifiable(_entries);
}
