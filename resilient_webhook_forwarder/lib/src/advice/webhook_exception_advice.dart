import 'package:jetleaf_web/jetleaf_web.dart';

import '../exceptions/webhook_exceptions.dart';

/// Maps domain exceptions to structured JSON error responses.
@RestControllerAdvice()
class WebhookExceptionAdvice {
  /// Duplicate delivery appears as 409 Conflict.
  @ExceptionHandler(DuplicateWebhookException)
  ResponseBody<Map<String, dynamic>> onDuplicate(DuplicateWebhookException e) {
    return ResponseBody.of(
      HttpStatus.CONFLICT,
      {'error': 'DuplicateWebhookException', 'message': e.message},
    );
  }

  /// Payload validation failures appear as 400 Bad Request.
  @ExceptionHandler(InvalidWebhookPayloadException)
  ResponseBody<Map<String, dynamic>> onInvalidPayload(InvalidWebhookPayloadException e) {
    return ResponseBody.of(
      HttpStatus.BAD_REQUEST,
      {'error': 'InvalidWebhookPayloadException', 'message': e.message},
    );
  }

  /// Delivery failures appear as 502 Bad Gateway.
  @ExceptionHandler(WebhookDeliveryFailedException)
  ResponseBody<Map<String, dynamic>> onDeliveryFailure(WebhookDeliveryFailedException e) {
    return ResponseBody.of(
      HttpStatus.BAD_GATEWAY,
      {
        'error': 'WebhookDeliveryFailedException',
        'message': e.message,
        'deliveryId': e.deliveryId,
        'attempts': e.attempts,
      },
    );
  }
}
