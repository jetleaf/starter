import 'package:jetleaf/jetleaf.dart';

import 'prototype_ticket.dart';

/// Hands out fresh prototype-scoped tickets from the container.
///
/// A plain singleton — the prototype boundary is the `getPod` call,
/// which every `@Scope('prototype')` lookup resolves to a brand-new pod.
@Service()
class TicketService {
  final ApplicationContext _context;

  TicketService(this._context);

  Future<PrototypeTicket> nextTicket() =>
      _context.getPod<PrototypeTicket>('prototypeTicket');
}
