/// Jetleaf user service application class.
///
/// Component scanning is scoped to this package only — this app is one of
/// four standalone services in the workspace and must not see its siblings'
/// controllers or indicators.
library;

import 'package:jetleaf/jetleaf.dart';

@ComponentScan(basePackages: ['user_service', 'microservices_common'])
@JetleafApplicationStarter()
class UserServiceApp {
  UserServiceApp();
}
