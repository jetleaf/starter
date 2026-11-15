/// A normalized customer record extracted from the raw CSV feed.
class CustomerRecord {
  final String id;
  final String email;
  final String name;
  final String plan;

  CustomerRecord({
    required this.id,
    required this.email,
    required this.name,
    required this.plan,
  });

  Map<String, Object?> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'plan': plan,
      };
}

/// A single validation failure attached to a raw row.
class ValidationError {
  final int row;
  final String field;
  final String reason;

  ValidationError({required this.row, required this.field, required this.reason});

  Map<String, Object?> toJson() => {
        'row': row,
        'field': field,
        'reason': reason,
      };
}

/// Aggregate outcome of one ETL pass.
class EtlSummary {
  final int totalRows;
  final int validRows;
  final int duplicatesSkipped;
  final List<ValidationError> errors;
  final List<CustomerRecord> records;
  final Map<String, int> byPlan;

  EtlSummary({
    required this.totalRows,
    required this.validRows,
    required this.duplicatesSkipped,
    required this.errors,
    required this.records,
    required this.byPlan,
  });

  bool get hasFailures => errors.isNotEmpty;

  Map<String, Object?> toJson() => {
        'totalRows': totalRows,
        'validRows': validRows,
        'duplicatesSkipped': duplicatesSkipped,
        'errorCount': errors.length,
        'errors': errors.map((e) => e.toJson()).toList(),
        'byPlan': byPlan,
        'generatedAt': DateTime.now().toUtc().toIso8601String(),
      };
}
