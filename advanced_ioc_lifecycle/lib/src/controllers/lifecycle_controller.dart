import 'package:jetleaf_web/jetleaf_web.dart';

import '../lifecycle/expensive_report_service.dart';
import '../lifecycle/lifecycle_log.dart';
import '../lifecycle/prototype_ticket.dart';
import '../lifecycle/store_catalog.dart';
import '../lifecycle/ticket_service.dart';

/// Exposes the IoC container's runtime behavior through a REST API.
@RestController('/api/v1/lifecycle')
class LifecycleController {
  final LifecycleLog _log;
  final SingletonTicket _singletonTicket;
  final StoreCatalog _catalog;
  final ExpensiveReportService _expensiveReport;
  final TicketService _ticketService;

  LifecycleController(
    this._log,
    this._singletonTicket,
    this._catalog,
    this._expensiveReport,
    this._ticketService,
  );

  /// Prototype pods produce a fresh identity per injection point;
  /// singletons are constant.
  @GetMapping(path: '/tickets')
  Future<Map<String, Object?>> tickets() async {
    final proto = await _ticketService.nextTicket();
    return {
      'singleton': _singletonTicket.describe(),
      'prototypeFromFactory': proto.describe(),
      'note': 'ObjectFactory.get() returns a NEW prototype pod per call; singletons are shared.',
    };
  }

  /// @Primary picks the default implementation; @Qualifier disambiguates.
  @GetMapping(path: '/stores')
  Map<String, Object?> stores() => {
        ..._catalog.describe(),
        'primaryNote': 'defaultStore is InMemoryDataStore via @Primary',
        'qualifierNote': 'fileStore is FileDataStore via @Service("fileStore") + @Qualifier("fileStore")',
      };

  /// Shows how many times the heavy pod was constructed.
  @GetMapping(path: '/lazy')
  Map<String, Object?> lazy() => {
        'expensiveReport': _expensiveReport.describe(),
        'note': 'The lazy pod is created on first use and reused afterwards.',
      };

  /// Lifecycle event log captured since boot.
  @GetMapping(path: '/log')
  Map<String, Object?> log() => {
        'entries': _log.entries,
      };

  /// Aggregate report.
  @GetMapping(path: '/report')
  Map<String, Object?> report() => {
        'lifecycleLog': _log.entries,
        'expensiveReport': _expensiveReport.describe(),
        'storeCatalog': _catalog.describe(),
        'singletonTicket': _singletonTicket.describe(),
      };
}
