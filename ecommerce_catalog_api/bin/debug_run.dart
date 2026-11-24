import 'package:ecommerce_catalog_api/main.dart' as app;
import 'package:jetleaf/jetleaf.dart';

import 'package:ecommerce_catalog_api/_jetleaf/main.dart';

/// Hand-authored debugging entry. Boots the app the same way `lib/main.dart`
/// does, prints every registered pod definition, then shuts down.
///
/// Usage:  dart run bin/debug_run.dart
void main(List<String> args) async {
  try {
    final context = await JetleafApplication.run(app.EcommerceCatalogApp(), args, aotRegistrar: registerGeneratedArtifacts);
    if (context != null) {
      print('==================== ALL DEFINITIONS ====================');
      for (final name in context.getDefinitionNames()) {
        final def = context.getDefinition(name);
        print('Pod: $name -> Type: ${def.type.getQualifiedName()}');
      }
      print('==========================================================');
    }
  } catch (e, st) {
    print('Error: $e\n$st');
  }
}
