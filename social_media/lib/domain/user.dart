/// User aggregate for SocialPulse.
library;

enum UserStatus { active, suspended, deleted }

enum UserRole { member, moderator, admin }

class UserProfile {
  UserProfile({
    required this.id,
    required this.handle,
    required this.displayName,
    required this.createdAt,
    this.bio = '',
    this.avatarUrl,
    this.roles = const [UserRole.member],
    this.status = UserStatus.active,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
  });

  final String id;
  final String handle;
  final String displayName;
  final DateTime createdAt;
  String bio;
  String? avatarUrl;
  List<UserRole> roles;
  UserStatus status;
  int followersCount;
  int followingCount;
  int postsCount;

  bool get isSuspended => status == UserStatus.suspended;
  bool get isAdmin => roles.contains(UserRole.admin);
  bool get isModerator => isAdmin || roles.contains(UserRole.moderator);

  Map<String, dynamic> toJson() => {
        'id': id,
        'handle': handle,
        'displayName': displayName,
        'bio': bio,
        'avatarUrl': avatarUrl,
        'roles': roles.map((r) => r.name).toList(),
        'status': status.name,
        'followersCount': followersCount,
        'followingCount': followingCount,
        'postsCount': postsCount,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  Map<String, dynamic> toPublicJson() => {
        'id': id,
        'handle': handle,
        'displayName': displayName,
        'bio': bio,
        'avatarUrl': avatarUrl,
        'followersCount': followersCount,
        'followingCount': followingCount,
        'postsCount': postsCount,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  static UserProfile fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        handle: json['handle'] as String,
        displayName: json['displayName'] as String,
        bio: (json['bio'] as String?) ?? '',
        avatarUrl: json['avatarUrl'] as String?,
        roles: ((json['roles'] as List<dynamic>?) ?? const ['member'])
            .map((r) => UserRole.values.byName(r as String))
            .toList(),
        status: UserStatus.values.byName((json['status'] as String?) ?? 'active'),
        followersCount: (json['followersCount'] as num?)?.toInt() ?? 0,
        followingCount: (json['followingCount'] as num?)?.toInt() ?? 0,
        postsCount: (json['postsCount'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      );

  UserProfile copyWith({
    String? displayName,
    String? bio,
    String? avatarUrl,
    UserStatus? status,
    List<UserRole>? roles,
    int? followersCount,
    int? followingCount,
    int? postsCount,
  }) =>
      UserProfile(
        id: id,
        handle: handle,
        displayName: displayName ?? this.displayName,
        bio: bio ?? this.bio,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        roles: roles ?? List.of(this.roles),
        status: status ?? this.status,
        followersCount: followersCount ?? this.followersCount,
        followingCount: followingCount ?? this.followingCount,
        postsCount: postsCount ?? this.postsCount,
        createdAt: createdAt,
      );
}
