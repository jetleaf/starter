import 'dart:io';

import 'package:test/test.dart';

import 'package:batch_etl_cron_cli/src/etl/pipeline.dart';

const _csv = '''id,email,name,plan
1, ada@example.com ,Ada Lovelace,pro
2,BOB@EXAMPLE.COM,Bob the Builder,free
3,,Charlie Missing,free
4,not-an-email,Dana Invalid,enterprise
5,ada@example.com,Ada Duplicate,pro
6,GRACE@EXAMPLE.COM,Grace Hopper,enterprise
''';

void main() {
  late EtlPipeline pipeline;

  setUp(() => pipeline = EtlPipeline());

  group('parse', () {
    test('skips header and blank lines', () {
      final rows = pipeline.parse(_csv);
      expect(rows.length, 6);
      expect(rows.first['id'], '1');
    });

    test('handles empty cells', () {
      final rows = pipeline.parse(_csv);
      expect(rows[2]['email'], isEmpty);
    });
  });

  group('validate', () {
    test('flags missing email, malformed email and bad plan', () {
      final rows = pipeline.parse(_csv);
      final errors = pipeline.validate(rows);

      expect(errors.where((e) => e.field == 'email').length, 2);
      expect(errors.where((e) => e.field == 'plan'), isEmpty);
      expect(errors.map((e) => e.row), containsAll([4, 5]));
    });

    test('flags an unknown plan', () {
      final rows = pipeline.parse('id,email,name,plan\n1,a@b.co,A,gold\n');
      final errors = pipeline.validate(rows);
      expect(errors.single.field, 'plan');
    });
  });

  group('run', () {
    test('normalizes, dedupes and summarizes', () {
      final summary = pipeline.run(_csv);

      expect(summary.totalRows, 6);
      expect(summary.validRows, 3);
      expect(summary.duplicatesSkipped, 1);
      expect(summary.records.map((r) => r.email),
          containsAll(['ada@example.com', 'bob@example.com', 'grace@example.com']));
      expect(summary.records.first.name, 'Ada Lovelace');
      expect(summary.byPlan['pro'], 1);
      expect(summary.byPlan['free'], 1);
      expect(summary.byPlan['enterprise'], 1);
      expect(summary.hasFailures, isTrue);
    });

    test('valid csv produces zero errors', () {
      final summary = pipeline.run('id,email,name,plan\n1,ada@example.com,Ada,pro\n');
      expect(summary.hasFailures, isFalse);
      expect(summary.validRows, 1);
    });
  });

  group('runFile', () {
    test('reads and processes a CSV file', () async {
      final tmp = await Directory.systemTemp.createTemp('etl_test');
      try {
        final file = File('${tmp.path}/customers.csv');
        await file.writeAsString(_csv);
        final summary = await pipeline.runFile(file);
        expect(summary.validRows, 3);
      } finally {
        await tmp.delete(recursive: true);
      }
    });
  });
}
