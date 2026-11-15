import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

/// Registers the CORS policy for every `/api/**` route.
///
/// Development convenience: allows any origin. In production, narrow the
/// origins to the deployed Flutter web frontend.
@Component()
class ApiCorsRegistrar implements CorsConfigurationRegistrar {
  @override
  void register(CorsConfigurationRegistry registry) {
    registry.configureFor(
      '/api/**',
      const CorsConfiguration(
        allowedOrigins: ['*'],
        allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
        allowedHeaders: ['*'],
        exposedHeaders: ['Content-Type'],
        maxAgeSeconds: 3600,
      ),
    );
  }
}
