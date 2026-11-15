// Request payload for dispatching a webhook to a target URL.
final class WebhookDispatchDto {
  final String deliveryId;
  final String targetUrl;
  final String eventType;
  final Map<String, dynamic> body;

  const WebhookDispatchDto({
    required this.deliveryId,
    required this.targetUrl,
    required this.eventType,
    required this.body,
  });

  WebhookDispatchDto.fromJson(Map<String, dynamic> json)
      : deliveryId = json['deliveryId'] as String,
        targetUrl = json['targetUrl'] as String,
        eventType = json['eventType'] as String,
        body = Map<String, dynamic>.from(json['body'] as Map);

  Map<String, dynamic> toJson() => {
        'deliveryId': deliveryId,
        'targetUrl': targetUrl,
        'eventType': eventType,
        'body': body,
      };
}
