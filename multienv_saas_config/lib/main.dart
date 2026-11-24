import 'package:jetleaf/jetleaf.dart';

import '_jetleaf/main.dart';

@JetleafApplicationStarter()
class MultienvSaasConfigApp {
  MultienvSaasConfigApp();
}

void main(List<String> args) async {
  await JetleafApplication.run(MultienvSaasConfigApp(), args, aotRegistrar: registerGeneratedArtifacts);
}
