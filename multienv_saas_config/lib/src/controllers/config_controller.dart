import 'package:jetleaf_web/jetleaf_web.dart';

import '../config/saas_properties.dart';
import '../diagnostics/diagnostics_provider.dart';
import '../services/branding_service.dart';
import '../services/quota_service.dart';

/// Exposes the effective configuration and profile wiring.
@RestController('/api/v1/config')
class ConfigController {
  final SaasProperties _saas;
  final RateLimitProperties _rateLimit;
  final FeatureProperties _features;
  final BrandingService _branding;
  final DiagnosticsProvider _diagnostics;
  final QuotaService _quota;

  ConfigController(
    this._saas,
    this._rateLimit,
    this._features,
    this._branding,
    this._diagnostics,
  ) : _quota = QuotaService(_rateLimit);

  /// Effective, fully-resolved configuration for this process.
  @GetMapping(path: '/status')
  Map<String, Object?> status() => {
        'app': _saas.name,
        'region': _saas.region,
        'branding': _branding.describe(),
        'rateLimit': {'maxRequests': _rateLimit.maxRequests},
        'features': {
          'auditLog': _features.auditLog,
          'betaDashboard': _features.betaDashboard,
        },
        'diagnostics': _diagnostics.describe(),
      };

  /// Quota budget for a tenant given the configured limit.
  @GetMapping(path: '/tenants/{tenant}/quota')
  Map<String, Object?> tenantQuota(
    @PathVariable(value: 'tenant') String tenant,
    @RequestParam(value: 'used', required: false) String? used,
  ) {
    final usedRequests = int.tryParse(used ?? '0') ?? 0;
    return _quota.describe(tenant: tenant, usedRequests: usedRequests);
  }
}
