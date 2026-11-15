import 'package:jetleaf/jetleaf.dart';

import '_jetleaf/aot_registry.g.dart';

@JetleafApplicationStarter()
class EventDrivenOrderHubApp {
  EventDrivenOrderHubApp();
}

void main(List<String> args) async {
  await JetleafApplication.run(EventDrivenOrderHubApp(), args, null, registerJetleafAot);
}
