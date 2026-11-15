/// Gateway ops routes — BFF aggregate and cluster health.
library;

import 'dart:convert';

import 'package:jetleaf_web/jetleaf_web.dart';
import 'package:microservices_common/microservices_common.dart';

import 'gateway_properties.dart';

@RestController('/api')
class GatewayOpsController {
  GatewayOpsController(this._properties);
  final GatewayProperties _properties;

  final Map<String, ServiceHttpClient> _http = {};

  ServiceHttpClient _clientFor(String service) {
    return _http.putIfAbsent(service, () {
      return ServiceHttpClient(
        service: service,
        baseUrl: _properties.baseUrlFor(service),
        timeout: Duration(milliseconds: _properties.timeoutFor(service)),
        retryMaxAttempts: 1,
      );
    });
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map ? decoded.cast<String, dynamic>() : {'body': decoded};
    } catch (_) {
      return {'body': body};
    }
  }

  /// `GET /api/aggregate/orders/{id}` — BFF-style composite response.
  ///
  /// Order is required; customer and notifications are best-effort and
  /// flagged `degraded` when the owning service did not answer.
  @GetMapping(path: '/aggregate/orders/{id}')
  Future<ResponseBody<Map<String, dynamic>>> aggregateOrder(
    @PathVariable(value: 'id') String id,
  ) async {
    final orderClient = _clientFor('order');
    final orderExchange = await orderClient.get('/orders/$id');

    if (orderExchange.status == 404) {
      return ResponseBody.of(HttpStatus.NOT_FOUND, {
        'error': 'order_not_found',
        'orderId': id,
      });
    }

    final order = _decode(orderExchange.body);
    // jetson serialises map keys as snake_case on the wire — tolerate both.
    final customerId = (order['customer_id'] ?? order['customerId']) as String?;

    // Customer + notifications are optional — fetch concurrently, degrade if they fail.
    final customerFuture = customerId == null
        ? Future<Map<String, dynamic>?>.value(null)
        : () async {
            final exchange = await _clientFor('user').get('/users/$customerId');
            return exchange.status == 200 ? _decode(exchange.body) : null;
          }();

    final notificationsFuture = (customerId == null || !_properties.notificationsEnabled)
        ? Future<Map<String, dynamic>>.value(const <String, dynamic>{})
        : () async {
            final exchange = await _clientFor('notification')
                .get('/notifications?customerId=$customerId&limit=10');
            return exchange.status == 200 ? _decode(exchange.body) : const <String, dynamic>{};
          }();

    final customer = await customerFuture;
    final notifications = await notificationsFuture;

    return ResponseBody.of(HttpStatus.OK, {
      'order': order,
      'customer': customer,
      'notifications': notifications['notifications'],
      'unreadNotifications': notifications['unread'],
      'degraded': {
        'customer': customerId != null && customer == null,
        'notifications': customerId != null && notifications.isEmpty,
      },
    });
  }

  /// `GET /api/health/cluster` — fan out to every service's actuator.
  @GetMapping(path: '/health/cluster')
  Future<ResponseBody<Map<String, dynamic>>> clusterHealth() async {
    Future<Map<String, dynamic>> probe(MapEntry<String, String> entry) async {
      final client = _clientFor(entry.key);
      final started = DateTime.now().toUtc();
      final exchange = await client.get('/actuator/health');
      final latency = DateTime.now().toUtc().difference(started).inMilliseconds;
      final decoded = _decode(exchange.body);
      return {
        'status': (decoded['status'] as String?) ?? (exchange.status == 200 ? 'UP' : 'DOWN'),
        'httpStatus': exchange.status,
        'latencyMs': latency,
      };
    }

    final services = _properties.services.entries.toList();
    final results = await Future.wait(services.map(probe));
    final overall = results.every((r) => r['status'] == 'UP') ? 'UP' : 'DEGRADED';

    return ResponseBody.of(HttpStatus.OK, {
      'status': overall,
      'services': {for (var i = 0; i < services.length; i++) services[i].key: results[i]},
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
