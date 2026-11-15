/// A single note. Serialized as JSON on the wire.
class Note {
  /// Server-assigned unique identifier (`null` while pending creation client-side).
  final String? id;
  final String title;
  final String body;
  final bool pinned;
  final DateTime updatedAt;

  const Note({
    this.id,
    required this.title,
    required this.body,
    this.pinned = false,
    required this.updatedAt,
  });

  Note copyWith({
    String? id,
    String? title,
    String? body,
    bool? pinned,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      pinned: pinned ?? this.pinned,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'pinned': pinned,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id']?.toString(),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      pinned: (json['pinned'] as bool?) ?? false,
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '')?.toUtc() ?? DateTime.now().toUtc(),
    );
  }

  @override
  String toString() => 'Note(id: $id, title: $title, pinned: $pinned)';
}

/// Envelope for a sync pull response.
class SyncPullResponse {
  final List<Note> notes;
  final DateTime serverTime;

  SyncPullResponse({required this.notes, required this.serverTime});

  factory SyncPullResponse.fromJson(Map<String, dynamic> json) {
    return SyncPullResponse(
      notes: (json['notes'] as List?)?.map((e) => Note.fromJson((e as Map).cast<String, dynamic>())).toList() ?? [],
      serverTime: DateTime.tryParse(json['server_time']?.toString() ?? '')?.toUtc() ?? DateTime.now().toUtc(),
    );
  }
}
