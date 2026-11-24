library;

import 'package:jetleaf/jetleaf.dart';
import 'package:order_service/order_service.dart';
import 'package:order_service/_jetleaf/main.dart';

/// Entry for the order service. Runs standalone on port 8082 by default.
///
/// Usage:  dart run bin/order_service.dart
///         jl run bin/order_service.dart
@JetleafEntry()
void main(List<String> args) async {
  final argv = args.isEmpty ? ['--server.port=8082'] : args;
  try {
    await JetleafApplication.run(OrderServiceApp(), argv, aotRegistrar: registerGeneratedArtifacts);
  } catch (e, st) {
    print('order-service failed: $e\n$st');
    rethrow;
  }
}
