import 'package:test/test.dart';

import 'package:fullstack_sync_backend/src/notes/note_store.dart';

void main() {
  group('NoteStore', () {
    late NoteStore store;

    setUp(() => store = NoteStore());

    test('seeds demo notes on construction', () {
      expect(store.listAll(), isNotEmpty);
    });

    test('create assigns a unique id', () {
      final note = store.create(title: 'hello', body: 'world');
      expect(note.id, startsWith('note-'));
    });

    test('update modifies existing notes in place', () {
      final created = store.create(title: 'before', body: 'text');
      final updated = store.update(created.id!, title: 'after', body: 'text 2');
      expect(updated!.title, 'after');
      expect(updated.body, 'text 2');
    });

    test('update returns null for unknown id', () {
      expect(store.update('nope', title: 'x'), isNull);
    });

    test('delete removes and reports', () {
      final created = store.create(title: 'to delete', body: 'x');
      expect(store.delete(created.id!), isTrue);
      expect(store.delete(created.id!), isFalse);
    });
  });
}
