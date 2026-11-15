import '../config/saas_properties.dart';

/// Computes tenant request quotas from the rate-limit configuration.
///
/// Pure decision logic — no I/O — so it stays trivially unit-testable.
class QuotaService {
  final RateLimitProperties _rateLimit;

  QuotaService(this._rateLimit);

  /// Returns the remaining budget for [usedRequests] within the current window.
  int remainingBudget(int usedRequests) {
    final remaining = _rateLimit.maxRequests - usedRequests;
    return remaining < 0 ? 0 : remaining;
  }

  /// True when the tenant has exhausted the configured per-minute budget.
  bool isExhausted(int usedRequests) => usedRequests >= _rateLimit.maxRequests;

  Map<String, Object?> describe({required String tenant, required int usedRequests}) {
    return {
      'tenant': tenant,
      'maxRequestsPerMinute': _rateLimit.maxRequests,
      'usedRequests': usedRequests,
      'remainingRequests': remainingBudget(usedRequests),
      'exhausted': isExhausted(usedRequests),
    };
  }
}
