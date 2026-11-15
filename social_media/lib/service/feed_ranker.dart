/// Home timeline ranking for SocialPulse.
///
/// Hacker-news style decay: engagement / ageHours^1.5.
/// Pure computation — no framework types — so it stays trivially testable.
library;

import 'dart:math' as math;

import 'package:jetleaf/jetleaf.dart';

import '../domain/post.dart';
import '../util/page.dart';

class FeedEntry {
  const FeedEntry({required this.post, required this.score});

  final Post post;
  final double score;
}

@Component()
class FeedRanker {
  const FeedRanker();

  double scoreOf(Post post, DateTime now) {
    final minutes = now.difference(post.createdAt).inMinutes.clamp(1, 60 * 24 * 365);
    final ageHours = minutes / 60.0;
    final engagement = post.likes + 2.0 * post.comments + 1.0;
    return engagement / math.pow(ageHours, 1.5).toDouble();
  }

  /// Ranks [posts] by score and returns the requested page.
  Page<Post> rank(Iterable<Post> posts, PageRequest page, DateTime now) {
    final ranked = posts
        .map((p) => FeedEntry(post: p, score: scoreOf(p, now)))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return Page(
      content: ranked.skip(page.offset).take(page.size).map((e) => e.post).toList(),
      totalElements: ranked.length,
      page: page.page,
      size: page.size,
    );
  }
}
