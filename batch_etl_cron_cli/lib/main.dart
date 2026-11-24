import 'dart:io';

import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_scheduling/jetleaf_scheduling.dart';

import '_jetleaf/main.dart';
import 'src/runners/etl_command_runner.dart';

@EnableScheduling()
@JetleafApplicationStarter()
class BatchEtlCronCliApp {
  BatchEtlCronCliApp();
}

Future<int> main(List<String> args) async {
  final app = JetleafApplication(BatchEtlCronCliApp);
  app.setApplicationType(ApplicationType.NONE);
  app.setAotRegistrar(registerGeneratedArtifacts);

  // Watch mode stays alive for the scheduled task; otherwise run once and exit.
  final keepAlive = args.contains('--mode=watch');

  final context = await app.create(args, null);
  if (context == null) {
    stderr.writeln('Failed to start application context');
    return 1;
  }

  try {
    final runner = await context.getPod<EtlCommandRunner>('etlCommandRunner');

    if (keepAlive) {
      stdout.writeln('Watch mode: NightlyImportTask polls the inbox every 60s. Press Ctrl+C to stop.');
      // Keep the process alive; the @Scheduled task fires on the scheduler.
      await Future<void>.delayed(const Duration(days: 3650));
      return 0;
    }

    return runner.exitCode;
  } finally {
    await JetleafApplication.exit(context, const []);
  }
}
