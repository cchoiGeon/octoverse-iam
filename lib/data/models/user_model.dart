import 'package:json_annotation/json_annotation.dart';

import 'package:iam/data/enums/enums.dart';
import 'reference_model.dart';

part 'user_model.g.dart';

/// 유저 · 프로필 DTO (REST §3·§4, profile v3).
///
/// **서버 계약**: 경력·학력·자격·수상·어학·링크·스킬은 전부 프로필에 **임베드**된다.
/// 별도 careers/records/links 엔드포인트는 없다 — 수정은 프로필 PATCH 하나로 한다.
///
/// ⚠️ PATCH는 **전체 교체**다. 배열을 보내면 통째로 갈아치우고, null이면 삭제,
///    생략하면 변경 없음. 그래서 "경력 한 줄 추가" 화면도 기존 배열 전체를
///    실어 보내야 한다(웹의 `useProfileFormGate`가 막던 유실 사고).

// ══════════════════════════════════════════════════════════════
// 임베드 항목 (서버 DTO 1:1)
// ══════════════════════════════════════════════════════════════

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class CareerItem {
  const CareerItem({
    required this.company,
    required this.startYearMonth,
    required this.isCurrent,
    this.title,
    this.endYearMonth,
    this.description,
    this.jobCategory,
  });

  final String company;
  final String? title;

  /// "YYYY-MM"
  final String startYearMonth;
  final String? endYearMonth;
  final bool isCurrent;
  final String? description;
  final JobCategory? jobCategory;

  /// 표시용 기간 문자열 — "2023.01 – 현재"
  String get period {
    if (isCurrent) return '$startYearMonth – 현재';
    return endYearMonth != null
        ? '$startYearMonth – $endYearMonth'
        : startYearMonth;
  }

  factory CareerItem.fromJson(Map<String, dynamic> json) =>
      _$CareerItemFromJson(json);
  Map<String, dynamic> toJson() => _$CareerItemToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class EducationItem {
  const EducationItem({
    this.school,
    this.major,
    this.degree,
    this.startYearMonth,
    this.endYearMonth,
  });

  final String? school;
  final String? major;
  final String? degree;
  final String? startYearMonth;
  final String? endYearMonth;

  factory EducationItem.fromJson(Map<String, dynamic> json) =>
      _$EducationItemFromJson(json);
  Map<String, dynamic> toJson() => _$EducationItemToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class CertificationItem {
  const CertificationItem({required this.name, this.issuer, this.acquiredDate});

  final String name;
  final String? issuer;
  final String? acquiredDate;

  factory CertificationItem.fromJson(Map<String, dynamic> json) =>
      _$CertificationItemFromJson(json);
  Map<String, dynamic> toJson() => _$CertificationItemToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class AwardItem {
  const AwardItem({
    required this.name,
    this.organization,
    this.awardedDate,
    this.description,
  });

  final String name;
  final String? organization;
  final String? awardedDate;
  final String? description;

  factory AwardItem.fromJson(Map<String, dynamic> json) =>
      _$AwardItemFromJson(json);
  Map<String, dynamic> toJson() => _$AwardItemToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class LanguageItem {
  const LanguageItem({required this.language, this.level, this.score});

  final String language;
  final LanguageLevel? level;

  /// "TOEIC 900" · "JLPT N1" 등 자유 입력.
  final String? score;

  factory LanguageItem.fromJson(Map<String, dynamic> json) =>
      _$LanguageItemFromJson(json);
  Map<String, dynamic> toJson() => _$LanguageItemToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class LinkItem {
  const LinkItem({required this.type, required this.url, this.label});

  final LinkType type;
  final String url;
  final String? label;

  factory LinkItem.fromJson(Map<String, dynamic> json) =>
      _$LinkItemFromJson(json);
  Map<String, dynamic> toJson() => _$LinkItemToJson(this);
}

// ══════════════════════════════════════════════════════════════
// 프로필 · 계정
// ══════════════════════════════════════════════════════════════

/// 프로필 응답. **모든 배열 필드가 nullable** — null/생략은 "미설정"이다.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class Profile {
  const Profile({
    required this.nickname,
    this.oneLiner,
    this.introduction,
    this.photoUrl,
    this.skills,
    this.careers,
    this.educations,
    this.certifications,
    this.awards,
    this.languages,
    this.links,
  });

  final String nickname;
  final String? oneLiner;

  /// 자기소개 (기존 bio 대체). 최대 1500자.
  final String? introduction;
  final String? photoUrl;

  /// Skill enum "이름 문자열" 배열 (id가 아니다).
  final List<String>? skills;
  final List<CareerItem>? careers;
  final List<EducationItem>? educations;
  final List<CertificationItem>? certifications;
  final List<AwardItem>? awards;
  final List<LanguageItem>? languages;
  final List<LinkItem>? links;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileToJson(this);
}

/// 내 계정 (GET /users/me). 세션 확인도 겸한다.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class Me {
  const Me({
    required this.id,
    required this.email,
    required this.createdAt,
    this.profile,
    this.interests = const [],
    this.settings,
  });

  final String id;
  final String email;

  /// null이면 온보딩 미완료 → `/onboarding`으로 보낸다.
  final Profile? profile;
  final List<InterestTag> interests;
  final MeSettings? settings;
  final String createdAt;

  factory Me.fromJson(Map<String, dynamic> json) => _$MeFromJson(json);
  Map<String, dynamic> toJson() => _$MeToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MeSettings {
  const MeSettings({required this.emailNotificationEnabled});

  final bool emailNotificationEnabled;

  factory MeSettings.fromJson(Map<String, dynamic> json) =>
      _$MeSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$MeSettingsToJson(this);
}

/// 타 유저 공개 프로필 (GET /users/{id}).
/// 서버가 profile 필드를 **평탄화**해서 내려주고 id·interests를 얹는다.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class PublicUser {
  const PublicUser({
    required this.id,
    required this.nickname,
    this.oneLiner,
    this.introduction,
    this.photoUrl,
    this.skills,
    this.careers,
    this.educations,
    this.certifications,
    this.awards,
    this.languages,
    this.links,
    this.interests = const [],
  });

  final String id;
  final String nickname;
  final String? oneLiner;
  final String? introduction;
  final String? photoUrl;
  final List<String>? skills;
  final List<CareerItem>? careers;
  final List<EducationItem>? educations;
  final List<CertificationItem>? certifications;
  final List<AwardItem>? awards;
  final List<LanguageItem>? languages;
  final List<LinkItem>? links;
  final List<InterestTag> interests;

  factory PublicUser.fromJson(Map<String, dynamic> json) =>
      _$PublicUserFromJson(json);
  Map<String, dynamic> toJson() => _$PublicUserToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class UserSettings {
  const UserSettings({
    required this.emailNotificationEnabled,
    this.termsAgreedAt,
    this.privacyAgreedAt,
  });

  final bool emailNotificationEnabled;
  final String? termsAgreedAt;
  final String? privacyAgreedAt;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$UserSettingsToJson(this);
}

// ══════════════════════════════════════════════════════════════
// 요청 DTO
// ══════════════════════════════════════════════════════════════

/// 3.2 프로필 생성 (온보딩).
/// ⚠️ 이 DTO에는 `interest_tag_ids`가 없다 — 관심사는 생성 직후
///    `ProfileUpdateRequest`로 한 번 더 PATCH해야 한다(웹과 동일한 2단계).
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class ProfileCreateRequest {
  const ProfileCreateRequest({
    required this.nickname,
    this.oneLiner,
    this.introduction,
    this.photoUrl,
    this.skills,
    this.careers,
    this.educations,
    this.certifications,
    this.awards,
    this.languages,
    this.links,
  });

  final String nickname;
  final String? oneLiner;
  final String? introduction;
  final String? photoUrl;
  final List<String>? skills;
  final List<CareerItem>? careers;
  final List<EducationItem>? educations;
  final List<CertificationItem>? certifications;
  final List<AwardItem>? awards;
  final List<LanguageItem>? languages;
  final List<LinkItem>? links;

  factory ProfileCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$ProfileCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileCreateRequestToJson(this);
}

/// 3.3 프로필 수정 — **전체 교체**.
/// 관심사도 여기서 `interestTagIds`로 갱신한다.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class ProfileUpdateRequest {
  const ProfileUpdateRequest({
    this.nickname,
    this.oneLiner,
    this.introduction,
    this.photoUrl,
    this.skills,
    this.careers,
    this.educations,
    this.certifications,
    this.awards,
    this.languages,
    this.links,
    this.interestTagIds,
  });

  final String? nickname;
  final String? oneLiner;
  final String? introduction;
  final String? photoUrl;
  final List<String>? skills;
  final List<CareerItem>? careers;
  final List<EducationItem>? educations;
  final List<CertificationItem>? certifications;
  final List<AwardItem>? awards;
  final List<LanguageItem>? languages;
  final List<LinkItem>? links;

  /// 최대 5개 (`TOO_MANY_INTERESTS`).
  final List<int>? interestTagIds;

  factory ProfileUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$ProfileUpdateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileUpdateRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SettingsUpdateRequest {
  const SettingsUpdateRequest({required this.emailNotificationEnabled});

  final bool emailNotificationEnabled;

  factory SettingsUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$SettingsUpdateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SettingsUpdateRequestToJson(this);
}
