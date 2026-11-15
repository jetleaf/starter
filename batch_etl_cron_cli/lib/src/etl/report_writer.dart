import 'dart:convert';
import 'dart:io';

import 'models.dart';

/// Persists ETL summaries as JSON files on disk.
class ReportWriter {
  final Directory outputDir;

  ReportWriter([Directory? outputDir])
      : outputDir = outputDir ?? Directory('build/reports');

  /// Writes the summary JSON and returns the file path.
  Future<File> write(EtlSummary summary) async {
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final file = File('${outputDir.path}/summary-$timestamp.json');
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(summary.toJson()));
    return file;
  }
}
