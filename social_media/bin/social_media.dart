import 'package:social_media/main.dart' as app;
import 'package:social_media/_jetleaf/main.dart';
import 'package:jetleaf/jetleaf.dart';

/// Entry point for the SocialPulse HTTP server.
///
/// Usage:
///   dart run bin/social_media.dart [--jetleaf.profiles.active=dev|prod]
///   jl run bin/social_media.dart   (warm VM, hot reload — preferred for dev)
void main(List<String> args) async {
  try {
    final context = await JetleafApplication.run(app.SocialPulseApp(), args, aotRegistrar: registerGeneratedArtifacts);
    if (context != null) {
      // The server blocks; this line is reached only on shutdown.
      print('SocialPulse shutdown complete.');
    }
  } catch (e, st) {
    print('Fatal: $e\n$st');
    rethrow;
  }
}
