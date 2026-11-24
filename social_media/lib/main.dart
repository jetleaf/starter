import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_scheduling/jetleaf_scheduling.dart';

import '_jetleaf/main.dart';

/// SocialPulse — Jetleaf application starter.
///
/// Scheduled tasks (trending recalculation, nightly digest) are enabled with
/// `@EnableScheduling`; the web tier boots by default.
@EnableScheduling()
@JetleafApplicationStarter()
class SocialPulseApp {
  SocialPulseApp();
}

/// Boot the HTTP server (default).
void main(List<String> args) async {
  await JetleafApplication.run(SocialPulseApp(), args, aotRegistrar: registerGeneratedArtifacts);
}
