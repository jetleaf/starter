/// Gateway proxy routes — clients talk to one origin only.
///
/// Each route forwards to a downstream service and relays the status code +
/// body. The gateway's job: routing, not business logic.
library;

import 'dart:convert';

import 'package:jetleaf_web/jetleaf_web.dart';
import 'package:microservices_common/microservices_common.dart';

import 'gateway_properties.dart';

@RestController('/api')
class GatewayProxyController {
  GatewayProxyController(this._properties) : _http = {};
  final GatewayProperties _properties;

  /// HTTP clients keyed by service name, closed lazily at shutdown.
  final Map<String, ServiceHttpClient> _http;

  ServiceHttpClient _clientFor(String service) {
    return _http.putIfAbsent(service, () {
      return ServiceHttpClient(
        service: service,
        baseUrl: _properties.baseUrlFor(service),
        timeout: Duration(milliseconds: _properties.timeoutFor(service)),
        retryMaxAttempts: 2,
      );
    });
  }

  Map<String, dynamic>? _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map ? decoded.cast<String, dynamic>() : {'body': decoded};
    } catch (_) {
      return {'body': body};
    }
  }

  Future<ResponseBody<Map<String, dynamic>>> _relay(String service, String path) async {
    final client = _clientFor(service);
    final exchange = await client.get(path);
    final decoded = _decode(exchange.body);
    return ResponseBody(HttpStatus.fromCode(exchange.status), decoded ?? {'body': exchange.body});
  }

  // ------- users -------

  @GetMapping(path: '/users')
  Future<ResponseBody<Map<String, dynamic>>> listUsers() => _relay('user', '/users');

  @GetMapping(path: '/users/{id}')
  Future<ResponseBody<Map<String, dynamic>>> getUser(
    @PathVariable(value: 'id') String id,
  ) =>
      _relay('user', '/users/$id');

  @PostMapping(path: '/users', consumes: [MediaType.APPLICATION_JSON])
  Future<ResponseBody<Map<String, dynamic>>> createUser(
    @RequestBody() Map<String, dynamic> body,
  ) async {
    final client = _clientFor('user');
    final exchange = await client.post('/users', body);
    final decoded = _decode(exchange.body);
    return ResponseBody(HttpStatus.fromCode(exchange.status), decoded ?? {'body': exchange.body});
  }

  // ------- orders -------

  @GetMapping(path: '/orders')
  Future<ResponseBody<Map<String, dynamic>>> listOrders() => _relay('order', '/orders');

  @GetMapping(path: '/orders/{id}')
  Future<ResponseBody<Map<String, dynamic>>> getOrder(
    @PathVariable(value: 'id') String id,
  ) =>
      _relay('order', '/orders/$id');

  @PostMapping(path: '/orders', consumes: [MediaType.APPLICATION_JSON])
  Future<ResponseBody<Map<String, dynamic>>> createOrder(
    @RequestBody() Map<String, dynamic> body,
  ) async {
    final client = _clientFor('order');
    final exchange = await client.post('/orders', body);
    final decoded = _decode(exchange.body);
    return ResponseBody(HttpStatus.fromCode(exchange.status), decoded ?? {'body': exchange.body});
  }

  // ------- notifications -------

  @GetMapping(path: '/notifications')
  Future<ResponseBody<Map<String, dynamic>>> listNotifications(
    @RequestParam(value: 'customerId') String customerId,
    @RequestParam(value: 'limit', required: false, defaultValue: '20') int limit,
  ) =>
      _relay('notification', '/notifications?customerId=$customerId&limit=$limit');

  @GetMapping(path: '/notifications/unread-count')
  Future<ResponseBody<Map<String, dynamic>>> unreadCount(
    @RequestParam(value: 'customerId') String customerId,
  ) =>
      _relay('notification', '/notifications/unread-count?customerId=$customerId');

  @PostMapping(path: '/notifications/mark-all-read')
  Future<ResponseBody<Map<String, dynamic>>> markAllRead(
    @RequestParam(value: 'customerId') String customerId,
  ) async {
    final client = _clientFor('notification');
    final exchange = await client.post('/notifications/mark-all-read?customerId=$customerId', const {});
    final decoded = _decode(exchange.body);
    return ResponseBody(HttpStatus.fromCode(exchange.status), decoded ?? {'body': exchange.body});
  }
}
