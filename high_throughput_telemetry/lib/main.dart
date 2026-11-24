import 'package:jetleaf/jetleaf.dart';

import '_jetleaf/main.dart';

@JetleafApplicationStarter()
class HighThroughputTelemetryApp {
  HighThroughputTelemetryApp();
}

void main(List<String> args) async {
  await JetleafApplication.run(HighThroughputTelemetryApp(), args, aotRegistrar: registerGeneratedArtifacts);
}
