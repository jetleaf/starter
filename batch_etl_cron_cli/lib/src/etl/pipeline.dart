import 'dart:io';

import 'models.dart';

/// Pure ETL pipeline — parse, validate, transform, dedupe, summarize.
///
/// Deliberately free of framework dependencies so it can be unit-tested
/// in isolation. The [EtlCommandRunner] wires it into the Jetleaf lifecycle.
class EtlPipeline {
  static const _emailPattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
  static final _emailRegex = RegExp(_emailPattern);

  /// Parses the raw CSV content into `(id, email, name, plan)` tuples.
  /// Missing columns yield empty strings; extra columns are ignored.
  List<Map<String, String>> parse(String csv) {
    final rows = <Map<String, String>>[];
    final lines = csv.split('\n');

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final cells = line.split(',').map((c) => c.trim()).toList();
      rows.add({
        'id': cells.isNotEmpty ? cells[0] : '',
        'email': cells.length > 1 ? cells[1] : '',
        'name': cells.length > 2 ? cells[2] : '',
        'plan': cells.length > 3 ? cells[3].toLowerCase() : '',
      });
    }

    return rows;
  }

  /// Validates raw rows, collecting every problem found.
  /// Returns cleaned (trimmed, lower-cased) tuples alongside the errors.
  List<ValidationError> validate(List<Map<String, String>> rawRows) {
    final errors = <ValidationError>[];

    for (var i = 0; i < rawRows.length; i++) {
      final row = rawRows[i];
      final line = i + 2; // 1-based CSV line (header is line 1)

      if ((row['id'] ?? '').isEmpty) {
        errors.add(ValidationError(row: line, field: 'id', reason: 'id is required'));
      }
      if ((row['email'] ?? '').isEmpty) {
        errors.add(ValidationError(row: line, field: 'email', reason: 'email is required'));
      } else if (!_emailRegex.hasMatch(row['email']!)) {
        errors.add(ValidationError(row: line, field: 'email', reason: 'email "${row['email']}" is malformed'));
      }
      if ((row['name'] ?? '').isEmpty) {
        errors.add(ValidationError(row: line, field: 'name', reason: 'name is required'));
      }
      const plans = {'free', 'pro', 'enterprise'};
      final plan = (row['plan'] ?? '').toLowerCase();
      if (!plans.contains(plan)) {
        errors.add(ValidationError(row: line, field: 'plan', reason: 'plan "$plan" is not one of ${plans.toList()..sort()}'));
      }
    }

    return errors;
  }

  /// Normalizes a row: trims and lowercases email/plan, title-cases name.
  CustomerRecord transform(Map<String, String> row) {
    return CustomerRecord(
      id: row['id']!.trim(),
      email: row['email']!.trim().toLowerCase(),
      name: _titleCase(row['name']!.trim().replaceAll(RegExp(r'\s+'), ' ')),
      plan: (row['plan'] ?? 'free').trim().toLowerCase(),
    );
  }

  /// Runs the full pipeline over [csvContent], returning the summary.
  EtlSummary run(String csvContent) {
    final rawRows = parse(csvContent);
    final errors = validate(rawRows);
    final invalidRows = errors.map((e) => e.row - 2).toSet();

    final seen = <String>{};
    var duplicates = 0;
    final records = <CustomerRecord>[];

    for (var i = 0; i < rawRows.length; i++) {
      if (invalidRows.contains(i)) continue;

      final transformed = transform(rawRows[i]);
      if (!seen.add(transformed.email)) {
        duplicates++;
        continue;
      }

      records.add(transformed);
    }

    final byPlan = <String, int>{};
    for (final record in records) {
      byPlan[record.plan] = (byPlan[record.plan] ?? 0) + 1;
    }

    return EtlSummary(
      totalRows: rawRows.length,
      validRows: records.length,
      duplicatesSkipped: duplicates,
      errors: errors,
      records: records,
      byPlan: byPlan,
    );
  }

  /// Convenience: read + run from disk.
  Future<EtlSummary> runFile(File file) async {
    final content = await file.readAsString();
    return run(content);
  }

  static String _titleCase(String input) {
    if (input.isEmpty) return input;
    return input
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.length > 1 ? w.substring(1).toLowerCase() : ''}')
        .join(' ');
  }
}
