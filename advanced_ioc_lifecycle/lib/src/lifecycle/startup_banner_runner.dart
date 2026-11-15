import 'package:jetleaf/jetleaf.dart';

import 'lifecycle_log.dart';

/// First startup runner — prints the banner order slot 1.
@Component()
@Order(1)
class StartupBannerRunner implements CommandLineRunner {
  static final Log _logger = LogFactory.getLog(StartupBannerRunner);

  final LifecycleLog _log;

  StartupBannerRunner(this._log);

  @override
  int getOrder() => 1;

  @override
  Future<void> run(List<String> args) async {
    _log.record('StartupBannerRunner executed (order 1)');
    _logger.info('🍃 Advanced IoC & Lifecycle — started');
  }
}

/// Second startup runner — warms the cache order slot 2.
@Component()
@Order(2)
class WarmupCacheRunner implements CommandLineRunner {
  static final Log _logger = LogFactory.getLog(WarmupCacheRunner);

  final LifecycleLog _log;

  WarmupCacheRunner(this._log);

  @override
  int getOrder() => 2;

  @override
  Future<void> run(List<String> args) async {
    _log.record('WarmupCacheRunner executed (order 2)');
    _logger.info('WarmupCacheRunner: cache warmed');
  }
}
