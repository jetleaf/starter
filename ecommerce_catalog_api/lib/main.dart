import 'package:jetleaf/jetleaf.dart';

import '_jetleaf/aot_registry.g.dart';

/// E-Commerce Catalog & Checkout REST Application Starter.
@JetleafApplicationStarter()
class EcommerceCatalogApp {
  // Application startup hooks or configuration pods can be placed here.
}

/// Main entrypoint. Boots Jetleaf application context and Web server.
void main(List<String> args) async {
  await JetleafApplication.run(EcommerceCatalogApp(), args, null, registerJetleafAot);
}
