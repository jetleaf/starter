import 'package:jetleaf/jetleaf.dart';

/// Prototype-scoped pod — the container creates a new instance per injection point.
@Service()
@Scope('prototype')
class PrototypeTicket {
  final String id;
  final DateTime createdAt;

  PrototypeTicket()
      : id = _nextId(),
        createdAt = DateTime.now().toUtc();

  static int _counter = 0;
  static String _nextId() {
    _counter++;
    return 'ticket-${_counter.toString().padLeft(4, '0')}';
  }

  Map<String, Object?> describe() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// Singleton-scoped pod — one instance per container.
@Service()
class SingletonTicket {
  final String id;
  final DateTime createdAt;

  SingletonTicket()
      : id = 'singleton-${DateTime.now().microsecondsSinceEpoch}',
        createdAt = DateTime.now().toUtc();

  Map<String, Object?> describe() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
      };
}
