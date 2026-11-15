import 'package:test/test.dart';

import 'package:advanced_ioc_lifecycle/src/lifecycle/prototype_ticket.dart';

void main() {
  group('PrototypeTicket', () {
    test('each instance gets a unique id', () {
      final a = PrototypeTicket();
      final b = PrototypeTicket();
      expect(a.id, isNot(b.id));
    });

    test('ids use zero-padded sequential numbers', () {
      expect(PrototypeTicket().id, matches(RegExp(r'^ticket-\d{4}$')));
    });
  });

  group('SingletonTicket', () {
    test('describe exposes id and createdAt', () {
      final ticket = SingletonTicket();
      expect(ticket.describe()['id'], startsWith('singleton-'));
      expect(ticket.describe()['createdAt'], isNotEmpty);
    });
  });
}
