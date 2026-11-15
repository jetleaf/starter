import 'package:resilient_webhook_forwarder/main.dart' as app;
import 'package:jetleaf/jetleaf.dart';

void main(List<String> args) async {
  try {
    final context = await JetleafApplication.run(app.ResilientWebhookForwarderApp(), args);
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
