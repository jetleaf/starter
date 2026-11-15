// Models a signed webhook event received by the dispatcher.
final class WebhookEvent {
  final String id;
  final String type;
  final String targetUrl;
  final Map<String, dynamic> payload;
  final DateTime receivedAt;

  WebhookEvent({
    required this.id,
    required this.type,
    required this.targetUrl,
    required this.payload,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'targetUrl': targetUrl,
        'payload': payload,
        'receivedAt': receivedAt.toIso8601String(),
      };
}
