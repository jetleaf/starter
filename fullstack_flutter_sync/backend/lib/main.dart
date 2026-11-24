import 'package:jetleaf/jetleaf.dart';

import '_jetleaf/main.dart';

@JetleafApplicationStarter()
class FullstackSyncBackendApp {
  FullstackSyncBackendApp();
}

void main(List<String> args) async {
  await JetleafApplication.run(FullstackSyncBackendApp(), args, aotRegistrar: registerGeneratedArtifacts);
}
