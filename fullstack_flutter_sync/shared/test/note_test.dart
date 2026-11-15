import 'package:test/test.dart';

import 'package:fullstack_sync_shared/fullstack_sync_shared.dart';

void main() {
  group('Note serialization round-trip', () {
    test('fromJson(toJson(note)) preserves fields', () {
      final note = Note(
        id: 'note-1',
        title: 'Ship the release',
        body: 'Tag v1.0.0 and publish the Flutter build',
        pinned: true,
        updatedAt: DateTime.utc(2026, 11, 1, 12),
      );

      final decoded = Note.fromJson(note.toJson().cast<String, dynamic>());

      expect(decoded.id, 'note-1');
      expect(decoded.title, note.title);
      expect(decoded.body, note.body);
      expect(decoded.pinned, isTrue);
      expect(decoded.updatedAt, note.updatedAt);
    });

    test('fromJson tolerates missing optional fields', () {
      final note = Note.fromJson({'title': 'x', 'body': 'y', 'pinned': false, 'updated_at': '2026-11-01T12:00:00Z'});
      expect(note.id, isNull);
      expect(note.pinned, isFalse);
    });

    test('toJson emits server_time-compatible updated_at', () {
      final note = Note(id: null, title: 't', body: 'b', updatedAt: DateTime.utc(2026, 11, 1, 12));
      expect(note.toJson()['updated_at'], '2026-11-01T12:00:00.000Z');
    });
  });
}
