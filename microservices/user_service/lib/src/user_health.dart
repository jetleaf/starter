/// User-store health indicator — reports customer store state.
library;

import 'package:jetleaf/jetleaf.dart';
import 'package:microservices_common/microservices_common.dart';

import 'user_store.dart';

@Service()
class UserStoreHealthIndicator {
  UserStoreHealthIndicator(this._users);

  final UserStore _users;

  String get name => 'user-store';

  Future<IndicatorResult> check() async {
    final stopwatch = Stopwatch()..start();
    final count = _users.count;
    stopwatch.stop();
    return IndicatorResult(
      status: count > 0 ? 'UP' : 'DEGRADED',
      duration: stopwatch.elapsed,
      details: {'customers': count, 'backend': 'in-memory'},
    );
  }
}
