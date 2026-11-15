/// Thin wrapper over the Jetleaf validation engine.
///
/// Centralises bean validation so controllers get a single, consistent
/// `validateOrThrow` entrypoint instead of sprinkling reflection calls.
library;

import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_validation/jetleaf_validation.dart';

import '../../exception/social_pulse_exception.dart';

@Component()
class BeanValidator {
  BeanValidator(this._factory);

  final ValidationFactory _factory;

  /// Throws [ContentRejectedException] with all violation messages when invalid.
  T validateOrThrow<T>(T bean) {
    final report = _factory.validate(bean as Object, null);
    if (!report.isValid()) {
      final violations = report
          .getViolations()
          .map((v) => '${v.getPropertyPath()}: ${v.getMessage()}')
          .toList()
        ..sort();
      throw ContentRejectedException(violations.join('; '));
    }
    return bean;
  }
}
