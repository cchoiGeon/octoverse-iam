import 'package:json_annotation/json_annotation.dart';

import 'package:iam/data/enums/enums.dart';

part 'social_model.g.dart';

/// 찜 · 알림 · 명함교환 DTO (REST §7·§8 + Card Exchange API).

// ══════════════════════════════════════════════════════════════
// §7 Like (찜)
// ══════════════════════════════════════════════════════════════

@JsonSerializable(fieldRename: FieldRename.snake)
class LikeRow {
  const LikeRow({
    required this.id,
    required this.user,
    required this.createdAt,
  });

  final String id;
  final LikeUser user;
  final String createdAt;

  factory LikeRow.fromJson(Map<String, dynamic> json) =>
      _$LikeRowFromJson(json);
  Map<String, dynamic> toJson() => _$LikeRowToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class LikeUser {
  const LikeUser({required this.id, required this.nickname, this.photoUrl});

  final String id;
  final String nickname;
  final String? photoUrl;

  factory LikeUser.fromJson(Map<String, dynamic> json) =>
      _$LikeUserFromJson(json);
  Map<String, dynamic> toJson() => _$LikeUserToJson(this);
}

/// 7.5 찜 관리 화면 — 어느 모임에서 누구를 찜했는지 함께 온다.
@JsonSerializable(fieldRename: FieldRename.snake)
class MyLikeRow {
  const MyLikeRow({
    required this.id,
    required this.direction,
    required this.user,
    required this.channel,
    required this.createdAt,
  });

  final String id;
  final ExchangeDirection direction;
  final LikeUser user;
  final LikeChannelRef channel;
  final String createdAt;

  factory MyLikeRow.fromJson(Map<String, dynamic> json) =>
      _$MyLikeRowFromJson(json);
  Map<String, dynamic> toJson() => _$MyLikeRowToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class LikeChannelRef {
  const LikeChannelRef({required this.slug, required this.title});

  final String slug;
  final String title;

  factory LikeChannelRef.fromJson(Map<String, dynamic> json) =>
      _$LikeChannelRefFromJson(json);
  Map<String, dynamic> toJson() => _$LikeChannelRefToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class LikeCreateResponse {
  const LikeCreateResponse({
    required this.id,
    required this.toUserId,
    required this.channelId,
    required this.createdAt,
  });

  final String id;
  final String toUserId;
  final String channelId;
  final String createdAt;

  factory LikeCreateResponse.fromJson(Map<String, dynamic> json) =>
      _$LikeCreateResponseFromJson(json);
  Map<String, dynamic> toJson() => _$LikeCreateResponseToJson(this);
}

// ══════════════════════════════════════════════════════════════
// §8 Notification
// ══════════════════════════════════════════════════════════════

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class NotificationRow {
  const NotificationRow({
    required this.id,
    required this.type,
    required this.createdAt,
    this.channel,
    this.isRead = false,
    this.readAt,
  });

  final String id;

  /// 모르는 값이 와도 예외를 던지지 않고 `unknown` 으로 떨어진다.
  /// 이게 없으면 미지의 타입 한 건이 페이지 전체 파싱을 깨뜨린다
  /// (`social_enums.dart` 주석 참고).
  @JsonKey(unknownEnumValue: NotificationType.unknown)
  final NotificationType type;

  /// 모임과 무관한 알림(welcome 등)은 null.
  final LikeChannelRef? channel;

  /// ⚠️ 실서버 응답에 이 필드가 없다. 로컬 읽음 집합과 머지해서 채운다
  ///    (`NotificationService` — 서버 지원 시 제거).
  final bool isRead;
  final String? readAt;
  final String createdAt;

  NotificationRow copyWith({bool? isRead}) => NotificationRow(
    id: id,
    type: type,
    createdAt: createdAt,
    channel: channel,
    isRead: isRead ?? this.isRead,
    readAt: readAt,
  );

  factory NotificationRow.fromJson(Map<String, dynamic> json) =>
      _$NotificationRowFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationRowToJson(this);
}

// ══════════════════════════════════════════════════════════════
// Business Card & Exchange
// ══════════════════════════════════════════════════════════════

/// 내 명함 — owner당 1개인 단일 리소스.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class BusinessCard {
  const BusinessCard({
    required this.id,
    required this.frontImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.backImageUrl,
  });

  final String id;
  final String frontImageUrl;
  final String? backImageUrl;
  final String createdAt;
  final String updatedAt;

  bool get hasBack => backImageUrl != null;

  factory BusinessCard.fromJson(Map<String, dynamic> json) =>
      _$BusinessCardFromJson(json);
  Map<String, dynamic> toJson() => _$BusinessCardToJson(this);
}

/// 등록·수정 동일 (PUT upsert).
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class BusinessCardUpsertRequest {
  const BusinessCardUpsertRequest({
    required this.frontImageUrl,
    this.backImageUrl,
  });

  final String frontImageUrl;
  final String? backImageUrl;

  factory BusinessCardUpsertRequest.fromJson(Map<String, dynamic> json) =>
      _$BusinessCardUpsertRequestFromJson(json);
  Map<String, dynamic> toJson() => _$BusinessCardUpsertRequestToJson(this);
}

/// 요청·수락·거절 응답 — 관계 정보만 온다.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class CardExchangeResponse {
  const CardExchangeResponse({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  final CardExchangeStatus status;
  final String? respondedAt;
  final String createdAt;

  factory CardExchangeResponse.fromJson(Map<String, dynamic> json) =>
      _$CardExchangeResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CardExchangeResponseToJson(this);
}

/// 교환 목록 아이템 — 탭 렌더용.
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class CardExchangeListItem {
  const CardExchangeListItem({
    required this.id,
    required this.direction,
    required this.status,
    required this.user,
    required this.createdAt,
    this.card,
    this.respondedAt,
  });

  final String id;
  final ExchangeDirection direction;
  final CardExchangeStatus status;

  /// 조회자 기준 "상대".
  final ExchangeUser user;

  /// ⚠️ accepted일 때만 채워진다. pending/rejected면 null — 이게 게이트다.
  final ExchangeCard? card;
  final String? respondedAt;
  final String createdAt;

  factory CardExchangeListItem.fromJson(Map<String, dynamic> json) =>
      _$CardExchangeListItemFromJson(json);
  Map<String, dynamic> toJson() => _$CardExchangeListItemToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class ExchangeUser {
  const ExchangeUser({required this.id, this.nickname, this.photoUrl});

  final String id;
  final String? nickname;
  final String? photoUrl;

  factory ExchangeUser.fromJson(Map<String, dynamic> json) =>
      _$ExchangeUserFromJson(json);
  Map<String, dynamic> toJson() => _$ExchangeUserToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class ExchangeCard {
  const ExchangeCard({required this.frontImageUrl, this.backImageUrl});

  final String frontImageUrl;
  final String? backImageUrl;

  factory ExchangeCard.fromJson(Map<String, dynamic> json) =>
      _$ExchangeCardFromJson(json);
  Map<String, dynamic> toJson() => _$ExchangeCardToJson(this);
}

// ══════════════════════════════════════════════════════════════
// Device (FCM 푸시 토큰)
// ══════════════════════════════════════════════════════════════

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class DeviceRegisterRequest {
  const DeviceRegisterRequest({required this.token, this.platform = 'android'});

  /// FCM registration token. 기기·앱 설치 단위로 발급되고 재발급될 수 있다.
  final String token;

  /// 지금은 Android 만 지원한다. iOS 를 붙일 때 'ios' 가 추가된다.
  final String platform;

  factory DeviceRegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$DeviceRegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceRegisterRequestToJson(this);
}
