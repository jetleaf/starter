/// Custom stereotype + annotation-based extensibility demos.
library;

import 'package:jetleaf/jetleaf.dart';

/// Custom stereotype for the moderation subsystem — behaves exactly like
/// `@Service` (is meta-annotated with it) with a domain-specific name.
class CommunityModerator extends Service {
  const CommunityModerator([super.value]);
}
