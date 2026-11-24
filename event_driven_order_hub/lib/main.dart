import 'package:jetleaf/jetleaf.dart';

import '_jetleaf/main.dart';

@JetleafApplicationStarter()
class EventDrivenOrderHubApp {
  EventDrivenOrderHubApp();
}

void main(List<String> args) async {
  await JetleafApplication.run(EventDrivenOrderHubApp(), args, aotRegistrar: registerGeneratedArtifacts);
}
