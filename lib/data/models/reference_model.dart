import 'package:json_annotation/json_annotation.dart';

import 'package:iam/data/enums/enums.dart';

part 'reference_model.g.dart';

/// 참조 데이터 DTO (REST §9).
///
/// 관심사·카테고리·스킬은 거의 바뀌지 않으므로 `version` 기준으로 캐시한다:
/// 캐시에서 시드 → 백그라운드 재조회 → 버전이 다를 때만 교체.
/// (`ReferenceService` 참고 — 웹 `lib/services/reference.tsx` 대응)

@JsonSerializable()
class InterestTag {
  const InterestTag({required this.id, required this.name});

  final int id;
  final Interest name;

  /// 한국어 표시값.
  String get label => name.label;

  factory InterestTag.fromJson(Map<String, dynamic> json) =>
      _$InterestTagFromJson(json);
  Map<String, dynamic> toJson() => _$InterestTagToJson(this);
}

@JsonSerializable()
class InterestTagsResponse {
  const InterestTagsResponse({
    required this.version,
    this.interests = const [],
  });

  final String version;
  final List<InterestTag> interests;

  factory InterestTagsResponse.fromJson(Map<String, dynamic> json) =>
      _$InterestTagsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$InterestTagsResponseToJson(this);
}

@JsonSerializable()
class CategoryOption {
  const CategoryOption({required this.value, required this.label});

  final EventCategory value;

  /// 서버가 주는 라벨. 없으면 `value.label`로 폴백한다.
  final String label;

  factory CategoryOption.fromJson(Map<String, dynamic> json) =>
      _$CategoryOptionFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryOptionToJson(this);
}

@JsonSerializable()
class EventCategoriesResponse {
  const EventCategoriesResponse({
    required this.version,
    this.categories = const [],
  });

  final String version;
  final List<CategoryOption> categories;

  factory EventCategoriesResponse.fromJson(Map<String, dynamic> json) =>
      _$EventCategoriesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$EventCategoriesResponseToJson(this);
}

/// 스킬 태그 (GET /skill-tags).
/// ⚠️ 프로필의 `skills`는 id가 아니라 **이름 문자열 배열**로 보낸다.
@JsonSerializable()
class SkillTag {
  const SkillTag({required this.id, required this.name});

  final int id;
  final String name;

  factory SkillTag.fromJson(Map<String, dynamic> json) =>
      _$SkillTagFromJson(json);
  Map<String, dynamic> toJson() => _$SkillTagToJson(this);
}

@JsonSerializable()
class SkillTagsResponse {
  const SkillTagsResponse({required this.version, this.skills = const []});

  final String version;
  final List<SkillTag> skills;

  factory SkillTagsResponse.fromJson(Map<String, dynamic> json) =>
      _$SkillTagsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SkillTagsResponseToJson(this);
}

/// 관심사 갱신 응답 (`InterestsResponse`).
@JsonSerializable()
class InterestsResponse {
  const InterestsResponse({this.interests = const []});

  final List<InterestTag> interests;

  factory InterestsResponse.fromJson(Map<String, dynamic> json) =>
      _$InterestsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$InterestsResponseToJson(this);
}
