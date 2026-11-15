/// Request DTOs for SocialPulse API — annotated with constraint validation.
library;

import 'package:jetleaf_validation/jetleaf_validation.dart';

final class RegisterUserRequest {
  @NotBlank(message: 'handle must not be blank')
  @Size(min: 4, max: 31, message: 'handle must be 4-31 characters')
  @Pattern(r'^[a-z0-9][a-z0-9_.]{2,29}[a-z0-9]$', message: 'handle may only contain a-z, 0-9, "." or "_"')
  final String handle;

  @NotBlank(message: 'displayName must not be blank')
  @Size(min: 2, max: 80, message: 'displayName must be 2-80 characters')
  final String displayName;

  @Size(max: 280, message: 'bio must be at most 280 characters')
  final String bio;

  const RegisterUserRequest(this.handle, this.displayName, this.bio);

  factory RegisterUserRequest.fromJson(Map<String, dynamic> json) => RegisterUserRequest(
        (json['handle'] as String?)?.trim() ?? '',
        (json['displayName'] as String?)?.trim() ?? '',
        (json['bio'] as String?)?.trim() ?? '',
      );
}

final class UpdateProfileRequest {
  @Size(min: 2, max: 80)
  final String? displayName;

  @Size(max: 280)
  final String? bio;

  const UpdateProfileRequest({this.displayName, this.bio});

  factory UpdateProfileRequest.fromJson(Map<String, dynamic> json) => UpdateProfileRequest(
        displayName: (json['displayName'] as String?)?.trim(),
        bio: (json['bio'] as String?)?.trim(),
      );
}

final class CreatePostRequest {
  @Size(max: 500, message: 'posts are limited to 500 characters')
  final String content;

  @NotBlank(message: 'visibility must be one of: public, followers, unlisted')
  final String visibility;

  @Size(max: 10, message: 'at most 10 media items per post')
  final List<String> mediaUrls;

  const CreatePostRequest(this.content, this.visibility, this.mediaUrls);

  factory CreatePostRequest.fromJson(Map<String, dynamic> json) => CreatePostRequest(
        (json['content'] as String?)?.trim() ?? '',
        (json['visibility'] as String?)?.trim() ?? 'public',
        ((json['mediaUrls'] as List<dynamic>?) ?? const []).cast<String>(),
      );
}

final class CreateCommentRequest {
  @NotBlank(message: 'comment content must not be blank')
  @Size(max: 1000, message: 'comments are limited to 1000 characters')
  final String content;

  const CreateCommentRequest(this.content);

  factory CreateCommentRequest.fromJson(Map<String, dynamic> json) =>
      CreateCommentRequest((json['content'] as String?)?.trim() ?? '');
}

final class ReportPostRequest {
  @NotBlank(message: 'reason must not be blank')
  @Size(min: 3, max: 500)
  final String reason;

  const ReportPostRequest(this.reason);

  factory ReportPostRequest.fromJson(Map<String, dynamic> json) =>
      ReportPostRequest((json['reason'] as String?)?.trim() ?? '');
}
