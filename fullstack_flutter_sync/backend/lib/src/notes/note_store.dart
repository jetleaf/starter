import 'package:fullstack_sync_shared/fullstack_sync_shared.dart';
import 'package:jetleaf/jetleaf.dart';

/// In-memory note store. The seeds below make the first-run experience
/// meaningful; a real deployment would swap this for a database while
/// keeping the REST contract identical.
@Service()
class NoteStore {
  static final Log _logger = LogFactory.getLog(NoteStore);

  final List<Note> _notes = [];
  int _counter = 0;

  NoteStore() {
    _seed();
  }

  void _seed() {
    for (final seed in [
      {'title': 'Welcome to Full-Stack Sync', 'body': 'Edits on this device sync to the Jetleaf API and back.', 'pinned': true},
      {'title': 'Try the sync flow', 'body': 'Create a note here and watch it appear on every client.', 'pinned': false},
      {'title': 'One contract, two sides', 'body': 'The shared package keeps the Flutter and Jetleaf JSON shapes identical.', 'pinned': false},
    ]) {
      _counter++;
      _notes.add(Note(
        id: 'seed-${_counter.toString().padLeft(2, '0')}',
        title: seed['title'] as String,
        body: seed['body'] as String,
        pinned: seed['pinned'] as bool,
        updatedAt: DateTime.now().toUtc().subtract(Duration(days: _counter)),
      ));
    }
    _logger.info('NoteStore seeded with ${_notes.length} notes');
  }

  List<Note> listAll() => List.unmodifiable(_notes);

  Note? findById(String id) {
    for (final note in _notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  Note create({required String title, required String body, bool pinned = false}) {
    _counter++;
    final note = Note(
      id: 'note-${_counter.toString().padLeft(4, '0')}',
      title: title,
      body: body,
      pinned: pinned,
      updatedAt: DateTime.now().toUtc(),
    );
    _notes.add(note);
    _logger.info('Created note ${note.id}');
    return note;
  }

  Note? update(String id, {String? title, String? body, bool? pinned}) {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index == -1) return null;

    final existing = _notes[index];
    final updated = existing.copyWith(
      title: title,
      body: body,
      pinned: pinned,
      updatedAt: DateTime.now().toUtc(),
    );
    _notes[index] = updated;
    return updated;
  }

  bool delete(String id) {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index == -1) return false;
    _notes.removeAt(index);
    return true;
  }

  /// Push-style full sync: client sends its desired set, server reconciles.
  /// For demo purposes the client wins; a real implementation would use
  /// vector clocks per record.
  List<Note> replaceAll(List<Note> incoming) {
    _notes
      ..clear()
      ..addAll(incoming.map((n) => n.copyWith(id: n.id ?? 'note-${(_counter++).toString().padLeft(4, '0')}')));
    return listAll();
  }
}
