import 'package:jetleaf/jetleaf.dart';

import '_jetleaf/aot_registry.g.dart';

@JetleafApplicationStarter()
class MultienvSaasConfigApp {
  MultienvSaasConfigApp();
}

void main(List<String> args) async {
  await JetleafApplication.run(MultienvSaasConfigApp(), args, null, registerJetleafAot);
}
