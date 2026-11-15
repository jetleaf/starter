/// Global REST exception advice — every domain exception maps to an
/// RFC 7807 problem-details document with `application/problem+json`.
library;

import 'package:jetleaf/jetleaf.dart' hide ExceptionHandler;
import 'package:jetleaf_web/jetleaf_web.dart';
import 'package:jetleaf_validation/jetleaf_validation.dart';

import '../../exception/social_pulse_exception.dart';

@RestControllerAdvice()
class SocialPulseExceptionAdvice {
  static final Log _logger = LogFactory.getLog(SocialPulseExceptionAdvice);

  Map<String, dynamic> _problem(String code, String title, String detail, int status,
          {Map<String, Object?>? extensions}) =>
      {
        'type': 'https://docs.socialpulse.dev/problems/$code',
        'title': title,
        'status': status,
        'detail': detail,
        ...?extensions,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };

  @ExceptionHandler(SocialPulseException)
  ResponseBody<Map<String, dynamic>> handleDomain(SocialPulseException ex) {
    return ResponseBody.of(
      HttpStatus.fromCode(ex.status),
      _problem(ex.code, ex.message, ex.detail ?? ex.message, ex.status),
    );
  }

  @ExceptionHandler(MaxUploadSizePerFileExceededException)
  ResponseBody<Map<String, dynamic>> handleMaxUploadSize(MaxUploadSizePerFileExceededException ex) {
    return ResponseBody.of(
      HttpStatus.fromCode(413),
      _problem(
        'payload_too_large',
        'Upload too large',
        ex.message,
        413,
        extensions: {'maxUploadSizePerFile': ex.maxUploadSizePerFile, 'actualSize': ex.actualSize, 'fileName': ex.fileName},
      ),
    );
  }

  @ExceptionHandler(ConstraintViolationException)
  ResponseBody<Map<String, dynamic>> handleConstraintViolation(ConstraintViolationException ex) {
    final violations = ex.report
        .getViolations()
        .map((v) => {
              'path': v.getPropertyPath(),
              'message': v.getMessage(),
              'invalidValue': v.getInvalidValue()?.toString(),
            })
        .toList();
    return ResponseBody.of(
      HttpStatus.UNPROCESSABLE_ENTITY,
      _problem(
        'validation_failed',
        'Constraint violations',
        'One or more fields failed validation.',
        422,
        extensions: {'violations': violations},
      ),
    );
  }

  @ExceptionHandler(FormatException)
  ResponseBody<Map<String, dynamic>> handleFormat(FormatException ex) {
    return ResponseBody.of(
      HttpStatus.BAD_REQUEST,
      _problem('malformed_request', 'Malformed request', ex.message, 400),
    );
  }

  @ExceptionHandler(IllegalStateException)
  ResponseBody<Map<String, dynamic>> handleIllegalState(IllegalStateException ex) {
    return ResponseBody.of(
      HttpStatus.CONFLICT,
      _problem('illegal_state', 'Illegal state', ex.message, 409),
    );
  }

  @ExceptionHandler(Exception)
  ResponseBody<Map<String, dynamic>> handleGeneral(Exception ex) {
    _logger.error('unhandled exception', error: ex);
    return ResponseBody.of(
      HttpStatus.INTERNAL_SERVER_ERROR,
      _problem('internal_error', 'Internal server error', 'An unexpected error occurred.', 500),
    );
  }
}
