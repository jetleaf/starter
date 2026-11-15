import 'package:jetleaf_web/jetleaf_web.dart';

import 'note_store.dart';

/// REST API for notes — consumed by both the Flutter client and curl.
///
/// `@CrossOrigin(origins: ['*'])` lets the Flutter dev server
/// (chrome-extension / localhost) call the API during development.
/// In production, narrow the origins to your deployed frontend.
@RestController('/api/v1/notes')
@CrossOrigin(origins: ['*'])
class NotesController {
  final NoteStore _store;

  NotesController(this._store);

  @GetMapping()
  Map<String, Object?> list() => {
        'notes': _store.listAll().map((n) => n.toJson()).toList(),
        'server_time': DateTime.now().toUtc().toIso8601String(),
      };

  @GetMapping(path: '/{id}')
  ResponseBody<Map<String, Object?>> get(@PathVariable(value: 'id') String id) {
    final note = _store.findById(id);
    if (note == null) {
      return ResponseBody.of(HttpStatus.NOT_FOUND, {'error': 'Note not found', 'id': id});
    }
    return ResponseBody.of(HttpStatus.OK, note.toJson());
  }

  @PostMapping()
  ResponseBody<Map<String, Object?>> create(@RequestBody() Map<String, dynamic> body) {
    final title = body['title']?.toString().trim() ?? '';
    final text = body['body']?.toString() ?? '';
    if (title.isEmpty) {
      return ResponseBody.of(HttpStatus.BAD_REQUEST, {'error': 'Field "title" is required'});
    }
    final note = _store.create(
      title: title,
      body: text,
      pinned: (body['pinned'] as bool?) ?? false,
    );
    return ResponseBody.of(HttpStatus.CREATED, note.toJson());
  }

  @PutMapping(path: '/{id}')
  ResponseBody<Map<String, Object?>> update(
    @PathVariable(value: 'id') String id,
    @RequestBody() Map<String, dynamic> body,
  ) {
    final note = _store.update(
      id,
      title: body['title']?.toString(),
      body: body['body']?.toString(),
      pinned: body['pinned'] as bool?,
    );
    if (note == null) {
      return ResponseBody.of(HttpStatus.NOT_FOUND, {'error': 'Note not found', 'id': id});
    }
    return ResponseBody.of(HttpStatus.OK, note.toJson());
  }

  @DeleteMapping(path: '/{id}')
  ResponseBody<Map<String, Object?>> delete(@PathVariable(value: 'id') String id) {
    if (!_store.delete(id)) {
      return ResponseBody.of(HttpStatus.NOT_FOUND, {'error': 'Note not found', 'id': id});
    }
    return ResponseBody.of(HttpStatus.OK, {'deleted': id});
  }
}
