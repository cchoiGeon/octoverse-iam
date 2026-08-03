import 'package:json_annotation/json_annotation.dart';

part 'auth_model.g.dart';

/// 인증 DTO (REST §1) — `IAM_web/src/types/api.ts` 이식.

// ── 요청 ─────────────────────────────────────────────────────

/// 1.1 소셜 로그인. 프로바이더 SDK로 받은 OIDC id_token을 보낸다.
/// `email`은 id_token에 이메일이 없을 때 보완용(선택).
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class OAuthLoginRequest {
  const OAuthLoginRequest({required this.idToken, this.email});

  final String idToken;
  final String? email;

  factory OAuthLoginRequest.fromJson(Map<String, dynamic> json) =>
      _$OAuthLoginRequestFromJson(json);
  Map<String, dynamic> toJson() => _$OAuthLoginRequestToJson(this);
}

/// 1.2 약관 동의 · 가입 완료.
@JsonSerializable(fieldRename: FieldRename.snake)
class SignupRequest {
  const SignupRequest({
    required this.termsAgreed,
    required this.privacyAgreed,
    required this.emailNotificationEnabled,
  });

  final bool termsAgreed;
  final bool privacyAgreed;
  final bool emailNotificationEnabled;

  factory SignupRequest.fromJson(Map<String, dynamic> json) =>
      _$SignupRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SignupRequestToJson(this);
}

// ── 응답 ─────────────────────────────────────────────────────

@JsonSerializable(fieldRename: FieldRename.snake)
class OAuthLoginResponse {
  const OAuthLoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.isNewUser,
    required this.user,
    this.tokenType = 'Bearer',
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  /// 신규 가입 여부 — true면 온보딩으로 보낸다.
  final bool isNewUser;
  final AuthUser user;

  factory OAuthLoginResponse.fromJson(Map<String, dynamic> json) =>
      _$OAuthLoginResponseFromJson(json);
  Map<String, dynamic> toJson() => _$OAuthLoginResponseToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.hasProfile,
  });

  final String id;
  final String email;

  /// false면 온보딩 미완료 → `/onboarding`으로 보낸다.
  final bool hasProfile;

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      _$AuthUserFromJson(json);
  Map<String, dynamic> toJson() => _$AuthUserToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RefreshResponse {
  const RefreshResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.tokenType = 'Bearer',
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  factory RefreshResponse.fromJson(Map<String, dynamic> json) =>
      _$RefreshResponseFromJson(json);
  Map<String, dynamic> toJson() => _$RefreshResponseToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SignupResponse {
  const SignupResponse({required this.userId, required this.settings});

  final String userId;
  final SignupSettings settings;

  factory SignupResponse.fromJson(Map<String, dynamic> json) =>
      _$SignupResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SignupResponseToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SignupSettings {
  const SignupSettings({
    required this.emailNotificationEnabled,
    required this.termsAgreedAt,
    required this.privacyAgreedAt,
  });

  final bool emailNotificationEnabled;
  final String termsAgreedAt;
  final String privacyAgreedAt;

  factory SignupSettings.fromJson(Map<String, dynamic> json) =>
      _$SignupSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$SignupSettingsToJson(this);
}
