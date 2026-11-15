library;

import 'package:jetleaf/jetleaf.dart';
import 'package:user_service/user_service.dart';
import 'package:user_service/_jetleaf/aot_registry.g.dart';

/// Entry for the user service. Runs standalone on port 8081 by default.
///
/// Usage:  dart run bin/user_service.dart
///         jl run bin/user_service.dart
@JetleafEntry()
void main(List<String> args) async {
  final argv = args.isEmpty ? ['--server.port=8081'] : args;
  try {
    await JetleafApplication.run(UserServiceApp(), argv, null, registerJetleafAot);
  } catch (e, st) {
    print('user-service failed: $e\n$st');
    rethrow;
  }
}
