/// Gateway exception advice.
library;

import 'package:jetleaf_web/jetleaf_web.dart';

@RestControllerAdvice()
class GatewayExceptionAdvice {
  @ExceptionHandler(Exception)
  ResponseBody<Map<String, dynamic>> other(Exception ex) => ResponseBody.of(
        HttpStatus.INTERNAL_SERVER_ERROR,
        {
          'type': 'https://docs.jetleaf.dev/problems/internal_error',
          'title': 'Gateway error',
          'status': 500,
          'detail': ex.toString(),
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
}
