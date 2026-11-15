import 'package:jetleaf/jetleaf.dart';

import '_jetleaf/aot_registry.g.dart';

@JetleafApplicationStarter()
class AdvancedIocLifecycleApp {
  AdvancedIocLifecycleApp();
}

void main(List<String> args) async {
  await JetleafApplication.run(AdvancedIocLifecycleApp(), args, null, registerJetleafAot);
}
