import 'package:jetleaf/jetleaf.dart';

/// Demonstrates scalar [@Value] binding of nested configuration values.
@Service()
class BrandingService {
  @Value('#{app.name}')
  late String appName;

  @Value('#{app.region}')
  late String region;

  Map<String, Object?> describe() => {
        'app': appName,
        'region': region,
      };
}
