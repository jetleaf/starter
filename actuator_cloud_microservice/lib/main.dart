import 'package:jetleaf/jetleaf.dart';
import '_jetleaf/aot_registry.g.dart';

@JetleafApplicationStarter()
class ActuatorCloudApp {
  // Configure startup pods and application callbacks here.
}

void main(List<String> args) async {
  await JetleafApplication.run(ActuatorCloudApp(), args, null, registerJetleafAot);
}
