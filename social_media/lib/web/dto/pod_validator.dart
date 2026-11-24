/// Thin wrapper over the Jetleaf validation engine.
///
/// Centralises pod validation so controllers get a single, consistent
/// `validateOrThrow` entrypoint instead of sprinkling reflection calls.
library;

import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_validation/jetleaf_validation.dart';

import '../../exception/social_pulse_exception.dart';

@Component()
class PodValidator {
  PodValidator(this._factory);

  final ValidationFactory _factory;

  /// Throws [ContentRejectedException] with all violation messages when invalid.
  T validateOrThrow<T>(T pod) {
    final report = _factory.validate(pod as Object, null);
    if (!report.isValid()) {
      final violations = report
          .getViolations()
          .map((v) => '${v.getPropertyPath()}: ${v.getMessage()}')
          .toList()
        ..sort();
      throw ContentRejectedException(violations.join('; '));
    }
    return pod;
  }
}
