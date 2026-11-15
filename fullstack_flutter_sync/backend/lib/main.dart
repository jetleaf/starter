import 'package:jetleaf/jetleaf.dart';

import '_jetleaf/aot_registry.g.dart';

@JetleafApplicationStarter()
class FullstackSyncBackendApp {
  FullstackSyncBackendApp();
}

void main(List<String> args) async {
  await JetleafApplication.run(FullstackSyncBackendApp(), args, null, registerJetleafAot);
}
