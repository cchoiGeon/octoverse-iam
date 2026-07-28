import 'package:json_annotation/json_annotation.dart';

import 'package:iam/data/enums/enums.dart';
import 'reference_model.dart';

part 'channel_model.g.dart';

/// 모임(채널) DTO (REST §5) — `IAM_web/src/types/api.ts` 이식.

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class Organizer {
  const Organizer({required this.id, required this.nickname, this.photoUrl});

  final String id;
  final String nickname;
  final String? photoUrl;

  factory Organizer.fromJson(Map<String, dynamic> json) =>
      _$OrganizerFromJson(json);
  Map<String, dynamic> toJson() => _$OrganizerToJson(this);
}

/// 목록 아이템 (GET /channels).
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class ChannelListItem {
  const ChannelListItem({
    required this.id,
    required this.slug,
    required this.title,
    required this.location,
    required this.category,
    required this.startAt,
    required this.endAt,
    required this.capacity,
    required this.acceptedCount,
    required this.status,
    required this.organizer,
    this.description,
    this.coverImageUrl,
    this.interests = const [],
  });

  final String id;

  /// 라우팅 키. id가 아니라 slug로 상세를 연다.
  final String slug;
  final String title;

  /// 목록 응답에도 설명이 온다(카드 2줄 미리보기). 구버전 대비 nullable.
  final String? description;
  final String location;
  final EventCategory category;

  /// ISO-8601 UTC ("…Z"). 표시는 KST로 변환한다(`DateTimeUtils`).
  final String startAt;
  final String endAt;
  final int capacity;
  final int acceptedCount;

  /// ⚠️ 서버 status는 자동 종료가 없어 신뢰할 수 없다.
  ///    화면 표시는 `ChannelUtils.phaseOf()` 결과를 쓴다.
  final ChannelStatus status;
  final String? coverImageUrl;
  final Organizer organizer;
  final List<InterestTag> interests;

  int get remainingSeats => (capacity - acceptedCount).clamp(0, capacity);
  bool get isFull => acceptedCount >= capacity;

  factory ChannelListItem.fromJson(Map<String, dynamic> json) =>
      _$ChannelListItemFromJson(json);
  Map<String, dynamic> toJson() => _$ChannelListItemToJson(this);
}

/// 상세 (GET /channels/{slug}).
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class ChannelDetail {
  const ChannelDetail({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.startAt,
    required this.endAt,
    required this.capacity,
    required this.acceptedCount,
    required this.status,
    required this.organizer,
    required this.isPublic,
    required this.createdAt,
    this.coverImageUrl,
    this.interests = const [],
    this.myParticipation,
  });

  final String id;
  final String slug;
  final String title;
  final String description;
  final String location;
  final EventCategory category;
  final String startAt;
  final String endAt;
  final int capacity;
  final int acceptedCount;
  final ChannelStatus status;
  final String? coverImageUrl;
  final Organizer organizer;
  final List<InterestTag> interests;
  final bool isPublic;

  /// null이면 미참가. CTA 분기의 핵심.
  final MyParticipationRef? myParticipation;
  final String createdAt;

  int get remainingSeats => (capacity - acceptedCount).clamp(0, capacity);
  bool get isFull => acceptedCount >= capacity;

  factory ChannelDetail.fromJson(Map<String, dynamic> json) =>
      _$ChannelDetailFromJson(json);
  Map<String, dynamic> toJson() => _$ChannelDetailToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MyParticipationRef {
  const MyParticipationRef({required this.status});

  final ParticipationStatus status;

  factory MyParticipationRef.fromJson(Map<String, dynamic> json) =>
      _$MyParticipationRefFromJson(json);
  Map<String, dynamic> toJson() => _$MyParticipationRefToJson(this);
}

/// 5.8 내가 참가한 모임 — my_participation이 항상 있다.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class JoinedChannelListItem {
  const JoinedChannelListItem({
    required this.id,
    required this.slug,
    required this.title,
    required this.location,
    required this.category,
    required this.startAt,
    required this.endAt,
    required this.capacity,
    required this.acceptedCount,
    required this.status,
    required this.organizer,
    required this.myParticipation,
    this.description,
    this.coverImageUrl,
    this.interests = const [],
  });

  final String id;
  final String slug;
  final String title;
  final String? description;
  final String location;
  final EventCategory category;
  final String startAt;
  final String endAt;
  final int capacity;
  final int acceptedCount;
  final ChannelStatus status;
  final String? coverImageUrl;
  final Organizer organizer;
  final List<InterestTag> interests;
  final MyParticipationRef myParticipation;

  factory JoinedChannelListItem.fromJson(Map<String, dynamic> json) =>
      _$JoinedChannelListItemFromJson(json);
  Map<String, dynamic> toJson() => _$JoinedChannelListItemToJson(this);
}

// ── 요청 DTO ─────────────────────────────────────────────────

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class ChannelCreateRequest {
  const ChannelCreateRequest({
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.startAt,
    required this.endAt,
    required this.capacity,
    required this.isPublic,
    this.coverImageUrl,
    this.interestTagIds = const [],
  });

  final String title;
  final String description;
  final String location;
  final EventCategory category;

  /// UTC ISO-8601. 입력값(KST)은 `DateTimeUtils.toUtcIso()`로 변환해 보낸다.
  final String startAt;

  /// ⚠️ 필수. 모임 상태 판정의 기준이라 비울 수 없다.
  final String endAt;
  final int capacity;
  final bool isPublic;
  final String? coverImageUrl;
  final List<int> interestTagIds;

  factory ChannelCreateRequest.fromJson(Map<String, dynamic> json) =>
      _$ChannelCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ChannelCreateRequestToJson(this);
}

/// 수정 — 보낸 필드만 반영된다(부분 수정).
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class ChannelUpdateRequest {
  const ChannelUpdateRequest({
    this.title,
    this.description,
    this.location,
    this.category,
    this.startAt,
    this.endAt,
    this.capacity,
    this.isPublic,
    this.coverImageUrl,
    this.interestTagIds,
  });

  final String? title;
  final String? description;
  final String? location;
  final EventCategory? category;
  final String? startAt;
  final String? endAt;

  /// 현재 승인 인원보다 적게 줄이면 `CAPACITY_BELOW_ACCEPTED`.
  final int? capacity;
  final bool? isPublic;
  final String? coverImageUrl;
  final List<int>? interestTagIds;

  factory ChannelUpdateRequest.fromJson(Map<String, dynamic> json) =>
      _$ChannelUpdateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ChannelUpdateRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CloseChannelResponse {
  const CloseChannelResponse({required this.slug, required this.status});

  final String slug;
  final ChannelStatus status;

  factory CloseChannelResponse.fromJson(Map<String, dynamic> json) =>
      _$CloseChannelResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CloseChannelResponseToJson(this);
}
