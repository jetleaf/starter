/// User persistence contract + in-memory implementation.
///
/// The contract is deliberately storage-agnostic so a `jetleaf_data`
/// (JPA/SQL) implementation can drop in later without touching services.
library;

import 'package:jetleaf/jetleaf.dart';

import '../domain/user.dart';
import '../util/page.dart';

abstract class UserRepository {
  Future<UserProfile?> findById(String id);
  Future<UserProfile?> findByHandle(String handle);
  Future<bool> existsByHandle(String handle);
  Future<List<UserProfile>> findByIds(Iterable<String> ids);
  Future<List<UserProfile>> search(String query, {int limit = 20});
  Future<UserProfile> save(UserProfile profile);
  Future<UserProfile> update(UserProfile profile);
  Future<List<UserProfile>> findAll({PageRequest page = const PageRequest()});
  Future<int> count();
}

@Repository()
class InMemoryUserRepository implements UserRepository {
  final Map<String, UserProfile> _byId = {};
  final Map<String, String> _idByHandle = {};

  @override
  Future<UserProfile?> findById(String id) async => _byId[id];

  @override
  Future<UserProfile?> findByHandle(String handle) async {
    final id = _idByHandle[handle.toLowerCase()];
    return id == null ? null : _byId[id];
  }

  @override
  Future<bool> existsByHandle(String handle) async =>
      _idByHandle.containsKey(handle.toLowerCase());

  @override
  Future<List<UserProfile>> findByIds(Iterable<String> ids) async =>
      [for (final id in ids) if (_byId[id] != null) _byId[id]!];

  @override
  Future<List<UserProfile>> search(String query, {int limit = 20}) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _byId.values
        .where((u) =>
            u.handle.toLowerCase().contains(q) ||
            u.displayName.toLowerCase().contains(q))
        .take(limit)
        .toList(growable: false);
  }

  @override
  Future<UserProfile> save(UserProfile profile) async {
    _byId[profile.id] = profile;
    _idByHandle[profile.handle.toLowerCase()] = profile.id;
    return profile;
  }

  @override
  Future<UserProfile> update(UserProfile profile) async {
    if (!_byId.containsKey(profile.id)) {
      throw IllegalStateException('Cannot update missing profile ${profile.id}');
    }
    _byId[profile.id] = profile;
    _idByHandle[profile.handle.toLowerCase()] = profile.id;
    return profile;
  }

  @override
  Future<List<UserProfile>> findAll({PageRequest page = const PageRequest()}) async {
    final all = _byId.values.toList(growable: false);
    final sorted = [...all]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted.skip(page.offset).take(page.size).toList(growable: false);
  }

  @override
  Future<int> count() async => _byId.length;
}
