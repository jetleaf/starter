/// Profile & follow-graph API — registration, profiles, avatars, follows.
library;

import 'package:jetleaf_web/jetleaf_web.dart';

import '../../service/post_service.dart';
import '../../service/user_service.dart';
import '../../exception/social_pulse_exception.dart';
import '../../util/page.dart';
import '../../web/dto/bean_validator.dart';
import '../../web/dto/requests.dart';

@RestController('/api/users')
class ProfileController {
  ProfileController(this._users, this._posts, this._validator);

  final UserService _users;
  final PostService _posts;
  final BeanValidator _validator;

  /// Register — public endpoint.
  @PostMapping()
    Future<ResponseBody<Map<String, dynamic>>> register(
    @RequestBody() Map<String, dynamic> body,
  ) async {
    final request = _validator.validateOrThrow(RegisterUserRequest.fromJson(body));
    final user = await _users.register(
      handle: request.handle,
      displayName: request.displayName,
      bio: request.bio,
    );
    return ResponseBody.of(HttpStatus.CREATED, {
      'user': user.toJson(),
      'message': 'Welcome to SocialPulse, ${user.displayName}!',
    });
  }

  /// Public profile by handle.
  @GetMapping(path: '/{handle}/profile')
  Future<Map<String, dynamic>> getProfile(@PathVariable(value: 'handle') String handle) async {
    final user = await _users.requireByHandle(handle);
    return user.toPublicJson();
  }

  /// Full profile (self/admin) — includes roles.
  @GetMapping(path: '/{handle}')
  Future<Map<String, dynamic>> getProfilePrivate(@PathVariable(value: 'handle') String handle) async {
    final user = await _users.requireByHandle(handle);
    return user.toJson();
  }

  /// Update displayName/bio — self only.
  @PatchMapping(path: '/{handle}')
    Future<Map<String, dynamic>> updateProfile(
    @PathVariable(value: 'handle') String handle,
    @RequestAttribute(value: 'actorHandle') String actor,
    @RequestBody() Map<String, dynamic> body,
  ) async {
    final request = _validator.validateOrThrow(UpdateProfileRequest.fromJson(body));
    if (actor != handle && actor != 'admin') {
      throw const ForbiddenActionException('you may only edit your own profile');
    }
    final updated = await _users.updateProfile(
      handle,
      displayName: request.displayName,
      bio: request.bio,
    );
    return updated.toJson();
  }

  @PostMapping(path: '/{handle}/follow')
  Future<Map<String, dynamic>> follow(
    @PathVariable(value: 'handle') String handle,
    @RequestAttribute(value: 'actorHandle') String actor,
  ) async {
    final created = await _users.follow(actor, handle);
    return {'following': created, 'follower': actor, 'followee': handle};
  }

  @DeleteMapping(path: '/{handle}/follow')
  Future<Map<String, dynamic>> unfollow(
    @PathVariable(value: 'handle') String handle,
    @RequestAttribute(value: 'actorHandle') String actor,
  ) async {
    final removed = await _users.unfollow(actor, handle);
    return {'following': !removed, 'follower': actor, 'followee': handle};
  }

  @GetMapping(path: '/{handle}/followers')
  Future<Map<String, dynamic>> followers(
    @PathVariable(value: 'handle') String handle,
    @RequestParam(value: 'page', required: false, defaultValue: '0') int page,
    @RequestParam(value: 'size', required: false, defaultValue: '20') int size,
  ) async {
    final result = await _users.followersOf(
        handle, PageRequest(page: page.clamp(0, 1000), size: size.clamp(1, 100)));
    return result.toJson((u) => u.toPublicJson());
  }

  @GetMapping(path: '/{handle}/following')
  Future<Map<String, dynamic>> following(
    @PathVariable(value: 'handle') String handle,
    @RequestParam(value: 'page', required: false, defaultValue: '0') int page,
    @RequestParam(value: 'size', required: false, defaultValue: '20') int size,
  ) async {
    final result = await _users.followingOf(
        handle, PageRequest(page: page.clamp(0, 1000), size: size.clamp(1, 100)));
    return result.toJson((u) => u.toPublicJson());
  }

  /// Accounts this viewer may want to follow.
  @GetMapping(path: '/suggestions/me')
  Future<List<Map<String, dynamic>>> suggestions(
    @RequestAttribute(value: 'actorHandle') String actor,
    @RequestParam(value: 'limit', required: false, defaultValue: '10') int limit,
  ) async =>
      [for (final u in await _users.suggestions(actor, limit: limit.clamp(1, 50))) u.toPublicJson()];

  /// Search accounts by handle/display name.
  @GetMapping(path: '/search')
  Future<List<Map<String, dynamic>>> search(
    @RequestParam(value: 'q') String query,
    @RequestParam(value: 'limit', required: false, defaultValue: '20') int limit,
  ) async =>
      [for (final u in await _users.search(query, limit: limit.clamp(1, 100))) u.toPublicJson()];

  /// Posts authored by a user — public timeline.
  @GetMapping(path: '/{handle}/posts')
  Future<Map<String, dynamic>> postsByAuthor(
    @PathVariable(value: 'handle') String handle,
    @RequestParam(value: 'page', required: false, defaultValue: '0') int page,
    @RequestParam(value: 'size', required: false, defaultValue: '20') int size,
  ) async {
    final user = await _users.requireByHandle(handle);
    final result = await _posts.postsByAuthor(
        user.id, PageRequest(page: page.clamp(0, 1000), size: size.clamp(1, 100)));
    return result.toJson((p) => p.toJson());
  }
}
