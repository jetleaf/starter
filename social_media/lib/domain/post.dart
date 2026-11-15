/// Post aggregate for SocialPulse.
library;

enum PostVisibility { publicPost, followers, unlisted }

class PostMedia {
  PostMedia({required this.url, this.altText, this.mimeType});

  final String url;
  final String? altText;
  final String? mimeType;

  Map<String, dynamic> toJson() => {
        'url': url,
        if (altText != null) 'altText': altText,
        if (mimeType != null) 'mimeType': mimeType,
      };

  static PostMedia fromJson(Map<String, dynamic> json) => PostMedia(
        url: json['url'] as String,
        altText: json['altText'] as String?,
        mimeType: json['mimeType'] as String?,
      );
}

class Post {
  Post({
    required this.id,
    required this.authorId,
    required this.authorHandle,
    required this.content,
    required this.createdAt,
    this.visibility = PostVisibility.publicPost,
    this.tags = const [],
    this.media = const [],
    this.likes = 0,
    this.comments = 0,
    this.reports = 0,
    this.deletedAt,
  });

  final String id;
  final String authorId;
  final String authorHandle;
  final String content;
  final DateTime createdAt;
  PostVisibility visibility;
  List<String> tags;
  List<PostMedia> media;
  int likes;
  int comments;
  int reports;
  DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;
  bool get isVisibleToPublic => !isDeleted && visibility == PostVisibility.publicPost;

  static final RegExp _tagPattern = RegExp(r'#([A-Za-z0-9_]{2,40})');

  static List<String> extractTags(String content) =>
      _tagPattern.allMatches(content).map((m) => m.group(1)!.toLowerCase()).toSet().toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'authorHandle': authorHandle,
        'content': content,
        'visibility': visibility.name,
        'tags': tags,
        'media': media.map((m) => m.toJson()).toList(),
        'likes': likes,
        'comments': comments,
        'reports': reports,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'isDeleted': isDeleted,
      };

  static Post fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as String,
        authorId: json['authorId'] as String,
        authorHandle: json['authorHandle'] as String,
        content: json['content'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
        visibility:
            PostVisibility.values.byName((json['visibility'] as String?) ?? 'publicPost'),
        tags: ((json['tags'] as List<dynamic>?) ?? const []).cast<String>(),
        media: ((json['media'] as List<dynamic>?) ?? const [])
            .map((m) => PostMedia.fromJson((m as Map).cast<String, dynamic>()))
            .toList(),
        likes: (json['likes'] as num?)?.toInt() ?? 0,
        comments: (json['comments'] as num?)?.toInt() ?? 0,
        reports: (json['reports'] as num?)?.toInt() ?? 0,
        deletedAt: json['deletedAt'] == null
            ? null
            : DateTime.parse(json['deletedAt'] as String).toUtc(),
      );

  Post copyWith({
    PostVisibility? visibility,
    List<String>? tags,
    List<PostMedia>? media,
    int? likes,
    int? comments,
    int? reports,
    DateTime? deletedAt,
  }) =>
      Post(
        id: id,
        authorId: authorId,
        authorHandle: authorHandle,
        content: content,
        createdAt: createdAt,
        visibility: visibility ?? this.visibility,
        tags: tags ?? List.of(this.tags),
        media: media ?? List.of(this.media),
        likes: likes ?? this.likes,
        comments: comments ?? this.comments,
        reports: reports ?? this.reports,
        deletedAt: deletedAt ?? this.deletedAt,
      );
}
