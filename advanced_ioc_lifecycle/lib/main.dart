import 'package:jetleaf/jetleaf.dart';

import '_jetleaf/main.dart';

@JetleafApplicationStarter()
class AdvancedIocLifecycleApp {
  AdvancedIocLifecycleApp();
}

void main(List<String> args) async {
  await JetleafApplication.run(AdvancedIocLifecycleApp(), args, aotRegistrar: registerGeneratedArtifacts);
}
