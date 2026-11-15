import 'package:jetleaf/jetleaf.dart';

/// In-memory idempotency store used to drop duplicate webhook deliveries.
///
/// Real applications often back this with Redis or a database table with
/// TTL. Here, the store caps its retained entries and expires old keys so
/// it remains safe for long-running dispatches.
@Service()
class IdempotencyService {
  final _seen = <String, DateTime>{};
  final Duration _ttl;
  final int _maxEntries;

  IdempotencyService({
    Duration ttl = const Duration(hours: 24),
    int maxEntries = 10000,
  })  : _ttl = ttl,
        _maxEntries = maxEntries;

  /// Returns `true` the first time [key] is observed, `false` on repeats.
  bool claim(String key) {
    _evictExpired();
    if (_seen.containsKey(key)) {
      return false;
    }
    if (_seen.length >= _maxEntries) {
      _evictOldest();
    }
    _seen[key] = DateTime.now();
    return true;
  }

  /// Releases a key so it can be re-processed (useful after a transient failure).
  void release(String key) => _seen.remove(key);

  /// Returns `true` when [key] was claimed earlier and has not been released.
  bool isKnown(String key) => _seen.containsKey(key);

  int get size => _seen.length;

  void clear() => _seen.clear();

  void _evictExpired() {
    final limit = DateTime.now().subtract(_ttl);
    _seen.removeWhere((_, timestamp) => timestamp.isBefore(limit));
  }

  void _evictOldest() {
    final ordered = _seen.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    for (var i = 0; i < (_maxEntries ~/ 10 + 1); i++) {
      _seen.remove(ordered[i].key);
    }
  }
}
