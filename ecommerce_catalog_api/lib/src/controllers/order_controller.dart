import 'package:jetleaf_web/jetleaf_web.dart';

import '../dto/checkout_dto.dart';
import '../services/order_service.dart';

/// REST API controller managing order checkouts and status queries.
@RestController('/api/v1/orders')
class OrderController {
  final OrderService _orderService;

  OrderController(this._orderService);

  /// Places an order by checking out the current shopping cart.
  @PostMapping(path: '/checkout')
  ResponseBody<Map<String, dynamic>> checkout(
    @RequestBody() Map<String, dynamic> body,
    @RequestParam(value: 'cartId', defaultValue: 'default-cart') String cartId,
  ) {
    final dto = CheckoutDto.fromJson(body);
    final order = _orderService.checkout(cartId, dto);
    return ResponseBody.of(HttpStatus.CREATED, order.toJson());
  }

  /// Retrieves order details by order ID.
  @GetMapping(path: '/{id}')
  Map<String, dynamic> getOrder(
    @PathVariable(value: 'id') String id,
  ) {
    return _orderService.getById(id).toJson();
  }

  /// Lists all placed orders.
  @GetMapping()
  List<Map<String, dynamic>> listOrders() {
    return _orderService.getAll().map((o) => o.toJson()).toList();
  }
}
