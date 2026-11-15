/// Avatar upload — multipart/form-data with part constraints.
library;

import 'dart:typed_data';

import 'package:jetleaf_web/jetleaf_web.dart';

import '../../exception/social_pulse_exception.dart';
import '../../service/user_service.dart';

@RestController('/api/users')
class AvatarController {
  AvatarController(this._users);

  final UserService _users;

  static const int _maxBytes = 5 * 1024 * 1024; // 5 MiB

  /// `POST /api/users/{handle}/avatar`
  /// Content-Type: multipart/form-data with part `avatar` (image/*)
  /// and optional part `caption` (application/json or text/plain).
  @PostMapping(path: '/{handle}/avatar', consumes: [MediaType.MULTIPART_FORM_DATA])
  Future<ResponseBody<Map<String, dynamic>>> uploadAvatar(
    @PathVariable(value: 'handle') String handle,
    @RequestAttribute(value: 'actorHandle') String actor,
    @RequestPart(value: 'avatar', contentType: 'image/png', maxSize: _maxBytes) Uint8List avatar,
    @RequestPart(value: 'caption', required: false) String? caption,
  ) async {
    if (actor != handle) {
      throw const ForbiddenActionException('you may only upload your own avatar');
    }
    if (avatar.length > _maxBytes) {
      throw const InvalidMediaException('avatar exceeds the 5 MiB limit');
    }

    // Detect actual format from magic bytes — never trust the declared type.
    final detected = _sniffImageType(avatar);
    if (detected == null) {
      throw const InvalidMediaException('unsupported or corrupt image payload');
    }

    // Production: stream to object storage; here we persist an in-memory avatar ref.
    final avatarUrl = 'memory://avatars/$handle.${detected.replaceFirst('image/', '')}';
    await _users.requireActiveByHandle(handle);
    await _users.updateProfile(handle, avatarUrl: avatarUrl);

    return ResponseBody.of(HttpStatus.CREATED, {
      'handle': handle,
      'avatarUrl': avatarUrl,
      'detectedContentType': detected,
      'bytes': avatar.length,
      'caption': ?caption,
    });
  }

  static String? _sniffImageType(Uint8List bytes) {
    if (bytes.length < 12) return null;
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4e && bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes[0] == 0xff && bytes[1] == 0xd8 && bytes[2] == 0xff) return 'image/jpeg';
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return 'image/gif';
    if (bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }
}
