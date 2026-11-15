import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fullstack_sync_shared/fullstack_sync_shared.dart';

/// Base URL of the Jetleaf notes API.
///
/// Override at build time with:
///   flutter run --dart-define=API_BASE_URL=http://localhost:8080
/// or at runtime by calling [NotesApi.baseUrl].
const String _defaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080',
);

/// Thin client for the Jetleaf notes sync API.
class NotesApi {
  final String baseUrl;
  final http.Client client;

  NotesApi({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? _defaultApiBaseUrl,
        client = client ?? http.Client();

  Uri _uri(String path) => Uri.parse('$baseUrl/api/v1/notes$path');

  Future<List<Note>> fetchNotes() async {
    final response = await client.get(_uri(''));
    _ensureOk(response, 'list notes');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = (data['notes'] as List?) ?? const [];
    return raw
        .map((e) => Note.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<Note> createNote({required String title, required String body}) async {
    final response = await client.post(
      _uri(''),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'body': body}),
    );
    _ensureOk(response, 'create note');
    return Note.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteNote(String id) async {
    final response = await client.delete(_uri('/$id'));
    _ensureOk(response, 'delete note');
  }

  Future<void> togglePinned(String id, bool pinned) async {
    final response = await client.put(
      _uri('/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'pinned': pinned}),
    );
    _ensureOk(response, 'pin note');
  }

  void _ensureOk(http.Response response, String action) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw StateError('Failed to $action: HTTP ${response.statusCode} — ${response.body}');
  }
}

void main() {
  runApp(const FullstackSyncApp());
}

class FullstackSyncApp extends StatelessWidget {
  const FullstackSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Full-Stack Sync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      home: const NotesScreen(),
    );
  }
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NotesApi _api = NotesApi();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  List<Note> _notes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final notes = await _api.fetchNotes();
      if (mounted) {
        setState(() => _notes = notes);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _addNote() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    try {
      await _api.createNote(title: title, body: _bodyController.text.trim());
      _titleController.clear();
      _bodyController.clear();
      await _refresh();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  Future<void> _deleteNote(String id) async {
    try {
      await _api.deleteNote(id);
      await _refresh();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  Future<void> _togglePinned(Note note) async {
    try {
      await _api.togglePinned(note.id!, !note.pinned);
      await _refresh();
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pinned = _notes.where((n) => n.pinned).toList();
    final others = _notes.where((n) => !n.pinned).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Full-Stack Sync 🍃'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh from API',
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Could not reach the Jetleaf API.\n$_error\n\nStart it with: dart run lib/main.dart (in ../backend)',
                    style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bodyController,
                      decoration: const InputDecoration(
                        labelText: 'Body',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 2,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _addNote,
                      icon: const Icon(Icons.note_add),
                      label: const Text('Add note'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_notes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No notes yet.')),
              )
            else ...[
              if (pinned.isNotEmpty) ...[
                const Text('Pinned', style: TextStyle(fontWeight: FontWeight.bold)),
                ...pinned.map(_buildNoteTile),
                const SizedBox(height: 8),
              ],
              if (others.isNotEmpty) ...[
                const Text('All notes', style: TextStyle(fontWeight: FontWeight.bold)),
                ...others.map(_buildNoteTile),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoteTile(Note note) {
    return Card(
      child: ListTile(
        title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(note.body),
        leading: IconButton(
          icon: Icon(note.pinned ? Icons.push_pin : Icons.push_pin_outlined),
          onPressed: () => _togglePinned(note),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _deleteNote(note.id!),
        ),
      ),
    );
  }
}
