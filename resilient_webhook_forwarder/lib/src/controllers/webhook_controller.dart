import 'package:jetleaf_web/jetleaf_web.dart';

import '../dto/webhook_dispatch_dto.dart';
import '../models/webhook_event.dart';
import '../services/dead_letter_service.dart';
import '../services/webhook_delivery_service.dart';

/// REST API controller exposing webhook dispatch operations.
@RestController('/api/v1/webhooks')
class WebhookController {
  final WebhookDeliveryService _delivery;
  final DeadLetterService _deadLetter;

  WebhookController(this._delivery, this._deadLetter);

  /// Dispatches a webhook payload to its configured target URL.
  @PostMapping(path: '/dispatch')
  Future<Map<String, dynamic>> dispatch(
    @RequestBody() Map<String, dynamic> body,
  ) async {
    final dto = WebhookDispatchDto.fromJson(body);
    final event = WebhookEvent(
      id: dto.deliveryId,
      type: dto.eventType,
      targetUrl: dto.targetUrl,
      payload: dto.body,
    );

    final result = await _delivery.dispatch(event);
    return result.toJson();
  }

  /// Lists all recorded dead-letter entries (for ops dashboards).
  @GetMapping(path: '/dead-letters')
  List<Map<String, dynamic>> listDeadLetters() => _deadLetter.listEntries();

  /// Returns dispatcher health information.
  @GetMapping(path: '/health')
  Map<String, dynamic> health() => {
        'status': 'UP',
        'deadLetterQueueSize': _deadLetter.size,
        'idempotencyCacheSize': _delivery.idempotencySize,
      };
}
