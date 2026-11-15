/// Follow relationship aggregate for SocialPulse.
library;

class Follow {
  Follow({required this.followerId, required this.followeeId, required this.createdAt});

  final String followerId;
  final String followeeId;
  final DateTime createdAt;

  String get key => '$followerId::$followeeId';

  Map<String, dynamic> toJson() => {
        'followerId': followerId,
        'followeeId': followeeId,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };
}
