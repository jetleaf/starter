import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:jetleaf/jetleaf.dart';

import '../etl/models.dart';
import '../etl/pipeline.dart';
import '../etl/report_writer.dart';

/// Invocation modes for the ETL CLI.
enum EtlMode { import, report, watch }

/// Parsed CLI options.
class EtlOptions {
  EtlOptions({
    required this.mode,
    required this.file,
    required this.outDir,
    required this.dryRun,
    required this.verbose,
  });

  final EtlMode mode;
  final File file;
  final Directory outDir;
  final bool dryRun;
  final bool verbose;

  static const usage = '''
batch_etl_cron_cli — headless ETL batch processor

Usage:
  dart run bin/batch_etl_cron_cli.dart [options]

Options:
  --mode=import|report|watch   Operation mode (default: import)
  --file=<path>                CSV input file (default: resources/data/customers.csv)
  --out=<dir>                  Report output directory (default: build/reports)
  --dry-run                    Validate + print summary, write no files
  --verbose                    Print every rejected row
  --help                       Show this help
''';

  static EtlOptions parse(List<String> args) {
    var mode = EtlMode.import;
    var file = 'resources/data/customers.csv';
    var outDir = 'build/reports';
    var dryRun = false;
    var verbose = false;

    for (final arg in args) {
      if (arg == '--help' || arg == '-h') {
        stdout.write(usage);
        exit(0);
      } else if (arg == '--dry-run') {
        dryRun = true;
      } else if (arg == '--verbose') {
        verbose = true;
      } else if (arg.startsWith('--mode=')) {
        final value = arg.substring('--mode='.length).trim().toLowerCase();
        mode = switch (value) {
          'import' => EtlMode.import,
          'report' => EtlMode.report,
          'watch' => EtlMode.watch,
          _ => throw ArgumentError('Unknown --mode "$value" (expected import|report|watch)'),
        };
      } else if (arg.startsWith('--file=')) {
        file = arg.substring('--file='.length);
      } else if (arg.startsWith('--out=')) {
        outDir = arg.substring('--out='.length);
      } else if (arg.startsWith('--')) {
        throw ArgumentError('Unknown option "$arg"');
      } else {
        file = arg; // positional CSV path
      }
    }

    return EtlOptions(
      mode: mode,
      file: File(file),
      outDir: Directory(outDir),
      dryRun: dryRun,
      verbose: verbose,
    );
  }
}

/// Runs the ETL pipeline as a Jetleaf command-line task.
@Component()
class EtlCommandRunner implements CommandLineRunner {
  static final Log _logger = LogFactory.getLog(EtlCommandRunner);

  /// Last exit code from an ETL pass (consumed by the entrypoint).
  int exitCode = 0;

  final EtlPipeline _pipeline = EtlPipeline();

  @override
  int getOrder() => 0;

  @override
  Future<void> run(List<String> args) async {
    final options = EtlOptions.parse(args);

    if (!options.file.existsSync()) {
      _logger.error('Input file not found: ${options.file.path}');
      exitCode = 1;
      return;
    }

    _logger.info('ETL pass started (mode=${options.mode.name}, file=${options.file.path})');
    final summary = await _pipeline.runFile(options.file);

    if (options.verbose) {
      for (final error in summary.errors) {
        _logger.warn('  row ${error.row}: [${error.field}] ${error.reason}');
      }
    }

    _printSummary(summary, dryRun: options.dryRun);

    if (!options.dryRun) {
      final file = await ReportWriter(options.outDir).write(summary);
      _logger.info('Report written to ${file.path}');
    }

    exitCode = summary.hasFailures ? 2 : 0;
  }

  void _printSummary(EtlSummary summary, {required bool dryRun}) {
    const encoder = JsonEncoder.withIndent('  ');
    stdout.writeln(encoder.convert(summary.toJson()));
    stdout.writeln(dryRun
        ? 'DRY-RUN: validation complete, no files written.'
        : 'Validated ${summary.totalRows} rows: ${summary.validRows} valid, '
            '${summary.errors.length} rejected, ${summary.duplicatesSkipped} duplicates skipped.');
  }
}
