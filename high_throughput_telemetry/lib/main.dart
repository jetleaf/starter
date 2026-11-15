import 'package:jetleaf/jetleaf.dart';

import '_jetleaf/aot_registry.g.dart';

@JetleafApplicationStarter()
class HighThroughputTelemetryApp {
  HighThroughputTelemetryApp();
}

void main(List<String> args) async {
  await JetleafApplication.run(HighThroughputTelemetryApp(), args, null, registerJetleafAot);
}
