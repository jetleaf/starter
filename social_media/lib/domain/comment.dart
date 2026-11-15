/// Comment and like aggregates for SocialPulse.
library;

class Comment {
  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorHandle,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String authorId;
  final String authorHandle;
  final String content;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'authorId': authorId,
        'authorHandle': authorHandle,
        'content': content,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  static Comment fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'] as String,
        postId: json['postId'] as String,
        authorId: json['authorId'] as String,
        authorHandle: json['authorHandle'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      );
}

class Like {
  Like({required this.postId, required this.userId, required this.createdAt});

  final String postId;
  final String userId;
  final DateTime createdAt;

  String get key => '$postId::$userId';

  Map<String, dynamic> toJson() => {
        'postId': postId,
        'userId': userId,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };
}
