import 'package:jetleaf/jetleaf.dart';

import '_jetleaf/main.dart';

@JetleafApplicationStarter()
class ServerRenderedPortalApp {
  ServerRenderedPortalApp();
}

void main(List<String> args) async {
  await JetleafApplication.run(ServerRenderedPortalApp(), args, aotRegistrar: registerGeneratedArtifacts);
}
