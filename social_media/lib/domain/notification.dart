/// Notification aggregate for SocialPulse.
library;

enum NotificationKind {
  like,
  comment,
  follow,
  mention,
  reportThreshold,
  system,
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.userId,
    required this.kind,
    required this.message,
    required this.createdAt,
    this.actorHandle,
    this.postId,
    this.read = false,
  });

  final String id;
  final String userId;
  final NotificationKind kind;
  final String message;
  final DateTime createdAt;
  final String? actorHandle;
  final String? postId;
  bool read;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'kind': kind.name,
        'message': message,
        if (actorHandle != null) 'actorHandle': actorHandle,
        if (postId != null) 'postId': postId,
        'read': read,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  static AppNotification fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        userId: json['userId'] as String,
        kind: NotificationKind.values.byName(json['kind'] as String),
        message: json['message'] as String,
        actorHandle: json['actorHandle'] as String?,
        postId: json['postId'] as String?,
        read: (json['read'] as bool?) ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      );
}
