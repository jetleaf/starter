/// Cross-cutting HTTP filters for SocialPulse.
///
/// Ordering is declared with `@Order` — the lowest value runs first.
library;

import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

@Order(1)
@Component()
class RequestLoggingFilter extends OncePerRequestFilter {
  static final Log _logger = LogFactory.getLog(RequestLoggingFilter);

  @override
  List<Object?> equalizedProperties() => const [];

  @override
  Future<void> doFilterInternal(
    ServerHttpRequest request,
    ServerHttpResponse response,
    FilterChain chain,
  ) async {
    final stopwatch = Stopwatch()..start();
    final method = request.getMethod();
    final uri = request.getRequestURI();
    _logger.info('→ $method $uri');
    await chain.next(request, response);
    _logger.info('← $method $uri status=${response.getStatus()} ${stopwatch.elapsedMilliseconds}ms');
  }
}

/// Gatekeeper for `/api/**` and `/api/admin/**`.
///
/// Policy (honest about what Jetleaf does today — no jetleaf_security yet):
///  * `/api/feed/global`, `/api/users` (register), portal pages → public
///  * other `/api/**` → requires `X-User: <handle>` (identity established upstream)
///  * `/api/admin/**` → additionally requires `X-Admin-Key` matching config
///
/// On failure the chain is short-circuited with 401/403 — no handler executes.
@Order(2)
@Component()
class SecurityFilter extends OncePerRequestFilter {
  SecurityFilter();

  @override
  List<Object?> equalizedProperties() => [adminKey];

  @Value('#{social.admin.key:dev-admin-key}')
  late String adminKey;

  static const _publicExact = {
    '/api/feed/global',
    '/api/users',
    '/actuator/health',
  };

  bool _isPublic(String method, String path) {
    if (method == 'GET' && path.startsWith('/portal')) return true;
    if (method == 'GET' && path.startsWith('/api/posts/tag/')) return true;
    if (method == 'GET' && path.startsWith('/api/feed/trending')) return true;
    if (method == 'GET' && path.startsWith('/api/posts/trending')) return true;
    if (method == 'GET' && RegExp(r'^/api/users/[^/]+/(posts|profile)$').hasMatch(path)) {
      return true;
    }
    if (method == 'POST' && path == '/api/users') return true;
    return _publicExact.contains(path);
  }

  @override
  Future<void> doFilterInternal(
    ServerHttpRequest request,
    ServerHttpResponse response,
    FilterChain chain,
  ) async {
    final path = request.getRequestURI().path;
    final method = request.getMethod().toString();

    if (!path.startsWith('/api')) {
      await chain.next(request, response);
      return;
    }

    if (_isPublic(method, path)) {
      await chain.next(request, response);
      return;
    }

    final actor = request.getHeaders().getFirst('X-User');
    if (actor == null || actor.trim().isEmpty || actor.length > 64) {
      response.setStatus(HttpStatus.UNAUTHORIZED);
      await response
          .getBody()
          .writeString('{"error":"unauthenticated","message":"X-User header required"}');
      return;
    }

    if (path.startsWith('/api/admin') && request.getHeaders().getFirst('X-Admin-Key') != adminKey) {
      response.setStatus(HttpStatus.FORBIDDEN);
      await response
          .getBody()
          .writeString('{"error":"forbidden","message":"admin key required"}');
      return;
    }

    request.setAttribute('actorHandle', actor.trim().toLowerCase());
    await chain.next(request, response);
  }
}

/// In-memory token bucket, 600 requests/minute/actor by default.
@Order(3)
@Component()
class RateLimitFilter extends OncePerRequestFilter {
  RateLimitFilter();

  @override
  List<Object?> equalizedProperties() => const [];

  @Value('#{social.rate-limit.requestsPerMinute:600}')
  late int requestsPerMinute;

  final Map<String, _TokenBucket> _buckets = {};

  @override
  Future<void> doFilterInternal(
    ServerHttpRequest request,
    ServerHttpResponse response,
    FilterChain chain,
  ) async {
    final path = request.getRequestURI().path;
    if (!path.startsWith('/api')) {
      await chain.next(request, response);
      return;
    }

    final key = request.getHeaders().getFirst('X-User') ??
        request.getHeaders().getFirst('X-Forwarded-For') ??
        'anonymous';
    final bucket = _buckets.putIfAbsent(
      key,
      () => _TokenBucket(capacity: requestsPerMinute),
    );

    if (!bucket.tryConsume()) {
      response.setStatus(HttpStatus.TOO_MANY_REQUESTS);
      await response.getBody().writeString(
            '{"error":"rate_limited","message":"too many requests — slow down","retryAfterSeconds":60}',
          );
      return;
    }

    await chain.next(request, response);
  }
}

class _TokenBucket {
  _TokenBucket({required this.capacity}) : tokens = capacity;

  final int capacity;
  int tokens;
  DateTime _windowStart = DateTime.now().toUtc();

  bool tryConsume() {
    final now = DateTime.now().toUtc();
    if (now.difference(_windowStart).inSeconds >= 60) {
      _windowStart = now;
      tokens = capacity;
    }
    if (tokens <= 0) return false;
    tokens--;
    return true;
  }
}
