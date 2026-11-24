import 'package:jetleaf/jetleaf.dart';
import '_jetleaf/main.dart';

@JetleafApplicationStarter()
class ActuatorCloudApp {
  // Configure startup pods and application callbacks here.
}

void main(List<String> args) async {
  await JetleafApplication.run(ActuatorCloudApp(), args, aotRegistrar: registerGeneratedArtifacts);
}
