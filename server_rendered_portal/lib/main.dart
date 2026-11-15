import 'package:jetleaf/jetleaf.dart';

import '_jetleaf/aot_registry.g.dart';

@JetleafApplicationStarter()
class ServerRenderedPortalApp {
  ServerRenderedPortalApp();
}

void main(List<String> args) async {
  await JetleafApplication.run(ServerRenderedPortalApp(), args, null, registerJetleafAot);
}
