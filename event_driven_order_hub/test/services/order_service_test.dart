import 'package:jetleaf_core/context.dart';
import 'package:test/test.dart';

import 'package:event_driven_order_hub/src/services/order_service.dart';

void main() {
  group('OrderService', () {
    late AnnotationConfigApplicationContext context;
    late OrderService service;

    setUp(() {
      context = AnnotationConfigApplicationContext();
      service = OrderService(context);
    });

    test('seeds demo orders on construction', () {
      final orders = service.listOrders();
      expect(orders, isNotEmpty);
      expect(orders.first.containsKey('id'), isTrue);
    });

    test('listOrders returns an unmodifiable snapshot', () {
      final orders = service.listOrders();
      expect(() => orders.add({}), throwsUnsupportedError);
    });

    test('placeOrder creates an order with PROCESSING status and sequential id', () async {
      final order = await service.placeOrder(
        customerId: 'cus-test',
        total: 99.50,
        items: ['Mechanical Keyboard'],
      );

      expect(order['id'], matches(RegExp(r'^order-\d{3}$')));
      expect(order['status'], 'PROCESSING');
      expect(order['customerId'], 'cus-test');
      expect(order['total'], 99.50);
    });

    test('processOrder transitions to PROCESSED and stamps the order', () async {
      final placed = await service.placeOrder(
        customerId: 'cus-test',
        total: 120.00,
        items: ['Ultra-Wide Monitor'],
      );

      final processed = await service.processOrder(placed['id']! as String);
      expect(processed, isNotNull);
      expect(processed!['status'], 'PROCESSED');
    });

    test('processOrder returns null for unknown id', () async {
      final processed = await service.processOrder('order-999');
      expect(processed, isNull);
    });

    test('notifyOrder stamps notifiedAt', () async {
      final placed = await service.placeOrder(
        customerId: 'cus-test',
        total: 15.00,
        items: ['Sticker Pack'],
      );

      final notified = await service.notifyOrder(placed['id']! as String);
      expect(notified, isNotNull);
      expect(notified!.containsKey('notifiedAt'), isTrue);
    });

    test('findById returns a copy, not a live reference', () async {
      final id = (await service.placeOrder(
        customerId: 'cus-test',
        total: 10.00,
        items: ['Mouse'],
      ))['id']! as String;

      final found = service.findById(id);
      expect(found, isNotNull);
      found!['status'] = 'TAMPERED';

      final reloaded = service.findById(id);
      expect(reloaded!['status'], 'PROCESSING');
    });
  });
}
