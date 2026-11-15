/// Handler interceptor — audit trail and per-request timing for mutating routes.
library;

import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

import '../../service/analytics_service.dart';

@Component()
class AuditHandlerInterceptor extends HandlerInterceptor {
  AuditHandlerInterceptor(this._analytics);

  static final Log _logger = LogFactory.getLog(AuditHandlerInterceptor);

  final AnalyticsService _analytics;
  final Map<int, DateTime> _inflight = {};

  @override
  Future<bool> preHandle(
    ServerHttpRequest request,
    ServerHttpResponse response,
    HandlerMethod handler,
  ) async {
    _inflight[handler.hashCode] = DateTime.now().toUtc();
    final actor = request.getHeaders().getFirst('X-User') ?? 'anonymous';
    if (request.getMethod().toString() != 'GET') {
      _analytics.track('http.${request.getMethod().toString()} ${request.getRequestURI().path} by $actor');
    }
    return true;
  }

  @override
  Future<void> postHandle(
    ServerHttpRequest request,
    ServerHttpResponse response,
    HandlerMethod handler,
  ) async {
    _analytics.increment('http.requests.total');
  }

  @override
  Future<void> afterCompletion(
    ServerHttpRequest request,
    ServerHttpResponse response,
    HandlerMethod handler,
  ) async {
    final started = _inflight.remove(handler.hashCode);
    if (started != null) {
      final elapsed = DateTime.now().toUtc().difference(started).inMilliseconds;
      if (elapsed > 500) {
        _logger.warn('slow request: ${request.getMethod().toString()} ${request.getRequestURI().path} took ${elapsed}ms');
      }
      _analytics.increment('http.slow_requests', elapsed > 500 ? 1 : 0);
    }
  }
}
