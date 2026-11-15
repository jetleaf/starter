import 'package:jetleaf/jetleaf.dart';
import '../models/webhook_event.dart';

/// Dead-letter log for payloads that could not be delivered after all retries.
///
/// In production, entries would be shipped to a worker queue or persisted
/// in a database for later replay; this starter keeps them in memory.
@Service()
class DeadLetterService {
  static final Log _logger = LogFactory.getLog(DeadLetterService);

  final List<Map<String, dynamic>> _entries = [];

  /// Records a permanently failed delivery for later replay.
  void recordFailure(WebhookEvent event, Object error, int attempts) {
    _entries.add({
      'deliveryId': event.id,
      'targetUrl': event.targetUrl,
      'eventType': event.type,
      'attempts': attempts,
      'error': error.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'payload': event.payload,
    });
    _logger.warn(
      'Webhook ${event.id} moved to dead-letter queue after $attempts attempts: $error',
    );
  }

  /// Returns all recorded dead-letter entries, newest last.
  List<Map<String, dynamic>> listEntries() => List.unmodifiable(_entries);

  /// Removes and returns every entry recorded so far.
  List<Map<String, dynamic>> drain() {
    final drained = List<Map<String, dynamic>>.from(_entries);
    _entries.clear();
    return drained;
  }

  int get size => _entries.length;

  void clear() => _entries.clear();
}
