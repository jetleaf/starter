library;

import 'package:jetleaf/jetleaf.dart';
import 'package:gateway/gateway.dart';
import 'package:gateway/_jetleaf/aot_registry.g.dart';

/// Entry for the API gateway. Runs on port 8080.
///
/// Usage:  dart run bin/gateway.dart
///         jl run bin/gateway.dart
@JetleafEntry()
void main(List<String> args) async {
  final argv = args.isEmpty ? ['--server.port=8080'] : args;
  try {
    await JetleafApplication.run(GatewayApp(), argv, null, registerJetleafAot);
  } catch (e, st) {
    print('gateway failed: $e\n$st');
    rethrow;
  }
}
