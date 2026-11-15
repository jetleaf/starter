/// Notification-store health indicator — reports inbox state.
library;

import 'package:jetleaf/jetleaf.dart';
import 'package:microservices_common/microservices_common.dart';

import 'notification_store.dart';

@Service()
class NotificationStoreHealthIndicator {
  NotificationStoreHealthIndicator(this._notifications);

  final NotificationStore _notifications;

  String get name => 'notification-store';

  Future<IndicatorResult> check() async {
    final stopwatch = Stopwatch()..start();
    final count = _notifications.count;
    stopwatch.stop();
    return IndicatorResult(
      status: 'UP',
      duration: stopwatch.elapsed,
      details: {'notifications': count, 'backend': 'in-memory'},
    );
  }
}
