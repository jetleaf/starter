import 'dart:io';

import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_scheduling/jetleaf_scheduling.dart';

import '../etl/pipeline.dart';
import '../etl/report_writer.dart';

/// Scheduled task that re-imports any CSV files dropped into the inbox
/// directory. Active only when the app stays alive (`--mode=watch`).
///
/// Mirrors how an ETL job would run on a nightly cron: new files appear in
/// the inbox, they get processed, and a summary report is emitted.
@Service()
class NightlyImportTask {
  static final Log _logger = LogFactory.getLog(NightlyImportTask);

  static const inboxDir = 'resources/data/inbox';
  static const processedDir = 'resources/data/processed';

  final EtlPipeline _pipeline = EtlPipeline();

  @Scheduled(fixedRate: Duration(seconds: 60))
  Future<void> importInbox() async {
    final inbox = Directory(inboxDir);
    if (!inbox.existsSync()) return;

    final pending = inbox
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.csv'))
        .toList();

    if (pending.isEmpty) {
      _logger.debug('NightlyImportTask: inbox is empty, skipping run');
      return;
    }

    for (final file in pending) {
      _logger.info('NightlyImportTask: importing ${file.path}');
      final summary = await _pipeline.runFile(file);
      final report = await ReportWriter(Directory('build/reports')).write(summary);
      _logger.info('NightlyImportTask: processed ${summary.validRows} rows, report at ${report.path}');

      final processed = Directory(processedDir);
      if (!processed.existsSync()) processed.createSync(recursive: true);
      await file.rename('${processed.path}/${file.uri.pathSegments.last}');
    }
  }
}
