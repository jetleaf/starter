/// Outbound HTTP client shared by the cluster's services.
///
/// Uses the programmatic `RetryExecutor`. Jetleaf's annotation-level
/// `@Retryable` does work — but only for pod-managed classes, which get
/// substituted by a generated `$$JLInterfaced$$` proxy at post-processing
/// time. This client is a plain helper constructed at call sites (not a
/// pod), so annotation interception would never reach it. One retry with a
/// short backoff is enough to ride out a service restart without amplifying
/// load; 4xx responses are never retried (deterministic answers).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_retry/jetleaf_retry.dart';

final class ServiceExchange {
  const ServiceExchange({required this.status, required this.body});

  final int status;
  final String body;

  Map<String, dynamic>? decodeJsonObject() {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map ? decoded.cast<String, dynamic>() : null;
    } catch (_) {
      return null;
    }
  }
}

final class ServiceUnavailableException implements Exception {
  const ServiceUnavailableException(this.service);

  final String service;

  @override
  String toString() => 'ServiceUnavailableException($service)';
}

class ServiceHttpClient {
  ServiceHttpClient({
    required this.service,
    required this.baseUrl,
    this.timeout = const Duration(seconds: 2),
    this.retryMaxAttempts = 2,
  }) : _executor = DefaultRetryExecutor()
          ..withRetryPolicy(SimpleRetryPolicy()
            ..retryable(Retryable(
              maxAttempts: retryMaxAttempts,
              retryFor: const [ClassType<Exception>()],
            )))
          ..withBackoffPolicy(FixedBackoffPolicy()..backoff(const Backoff(delay: 40)))
          ..withStatistics(InMemoryStatistics());

  final String service;
  final String baseUrl;
  final Duration timeout;
  final int retryMaxAttempts;

  final RetryExecutor _executor;
  final HttpClient _http = HttpClient();

  Future<ServiceExchange> get(String path) async {
    final result = await _executor.execute<ServiceExchange>(
      _ServiceRequest(
        service: service,
        baseUrl: baseUrl,
        timeout: timeout,
        method: 'GET',
        path: path,
        http: _http,
      ),
      _UnavailableFallback(service),
      SimpleRetryContext(),
    );
    return result;
  }

  Future<ServiceExchange> post(String path, Map<String, dynamic> body) async {
    final result = await _executor.execute<ServiceExchange>(
      _ServiceRequest(
        service: service,
        baseUrl: baseUrl,
        timeout: timeout,
        method: 'POST',
        path: path,
        body: jsonEncode(body),
        http: _http,
      ),
      _UnavailableFallback(service),
      SimpleRetryContext(),
    );
    return result;
  }

  Future<void> close() async => _http.close(force: true);
}

class _ServiceRequest implements RetryCallback<ServiceExchange> {
  _ServiceRequest({
    required this.service,
    required this.baseUrl,
    required this.timeout,
    required this.method,
    required this.path,
    required this.http,
    this.body,
  });

  final String service;
  final String baseUrl;
  final Duration timeout;
  final String method;
  final String path;
  final HttpClient http;
  final String? body;

  @override
  void setApplicationEventBus(ApplicationEventBus? applicationEventBus) {}

  @override
  FutureOr<ServiceExchange> execute(RetryContext context) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = method == 'POST'
        ? await http.postUrl(uri).timeout(timeout)
        : await http.getUrl(uri).timeout(timeout);

    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(body);
    }

    // HttpClientRequest.done only resolves after close() — call it always.
    await request.close();

    final response = await request.done.timeout(timeout);
    final responseBody = await response.transform(utf8.decoder).join().timeout(timeout);

    if (response.statusCode >= 500) {
      throw ServiceUnavailableException('$service:${response.statusCode}');
    }
    return ServiceExchange(status: response.statusCode, body: responseBody);
  }
}

class _UnavailableFallback implements RecoveryCallback<ServiceExchange> {
  const _UnavailableFallback(this.service);

  final String service;

  @override
  FutureOr<ServiceExchange> recover(RetryContext context) {
    return ServiceExchange(
      status: 503,
      body: jsonEncode({
        'error': 'service_unavailable',
        'service': service,
        'message': 'Downstream service "$service" did not respond after retries.',
      }),
    );
  }
}
