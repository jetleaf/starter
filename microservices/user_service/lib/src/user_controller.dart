/// Customer REST API.
library;

import 'package:jetleaf_web/jetleaf_web.dart';

import 'customer.dart';
import 'exception.dart';
import 'user_store.dart';

@RestController('/users')
class UserController {
  UserController(this._users);

  final UserStore _users;

  static final RegExp _handlePattern = RegExp(r'^[a-z0-9][a-z0-9_]{1,31}$');
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// `GET /users` — full directory.
  @GetMapping()
  Map<String, dynamic> listUsers() => {
        'count': _users.count,
        'customers': [for (final c in _users.findAll()) c.toJson()],
      };

  /// `GET /users/{id}` — single customer or 404.
  @GetMapping(path: '/{id}')
  Map<String, dynamic> getUser(@PathVariable(value: 'id') String id) {
    final customer = _users.findById(id);
    if (customer == null) {
      throw UserNotFoundException(id);
    }
    return customer.toJson();
  }

  /// `POST /users` — register a customer.
  @PostMapping()
  Future<ResponseBody<Map<String, dynamic>>> createUser(
    @RequestBody() Map<String, dynamic> body,
  ) async {
    final handle = (body['handle'] as String?)?.trim() ?? '';
    final displayName = (body['displayName'] as String?)?.trim() ?? '';
    final email = (body['email'] as String?)?.trim() ?? '';
    final tier = (body['tier'] as String?) ?? 'standard';

    if (!_handlePattern.hasMatch(handle)) {
      throw const InvalidCustomerException('handle must be 2-32 chars of a-z, 0-9 or "_"');
    }
    if (displayName.length < 2 || displayName.length > 120) {
      throw const InvalidCustomerException('displayName must be 2-120 characters');
    }
    if (!_emailPattern.hasMatch(email)) {
      throw const InvalidCustomerException('email must be a valid address');
    }

    final id = 'cus_${handle}_${DateTime.now().toUtc().millisecondsSinceEpoch}';
    final customer = Customer(
      id: id,
      handle: handle,
      displayName: displayName,
      email: email,
      tier: CustomerTier.values.byName(tier),
    );
    await _users.save(customer);
    return ResponseBody.of(HttpStatus.CREATED, customer.toJson());
  }
}
