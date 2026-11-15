import 'dart:io';

import 'package:batch_etl_cron_cli/main.dart' as app;

Future<void> main(List<String> arguments) async {
  final code = await app.main(arguments);
  exit(code);
}
