library;

import 'package:jetleaf/jetleaf.dart';
import 'package:notification_service/notification_service.dart';
import 'package:notification_service/_jetleaf/aot_registry.g.dart';

/// Entry for the notification service. Runs standalone on port 8083.
///
/// Usage:  dart run bin/notification_service.dart
///         jl run bin/notification_service.dart
@JetleafEntry()
void main(List<String> args) async {
  final argv = args.isEmpty ? ['--server.port=8083'] : args;
  try {
    await JetleafApplication.run(NotificationServiceApp(), argv, null, registerJetleafAot);
  } catch (e, st) {
    print('notification-service failed: $e\n$st');
    rethrow;
  }
}
