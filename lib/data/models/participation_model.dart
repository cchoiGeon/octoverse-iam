import 'package:json_annotation/json_annotation.dart';

import 'package:iam/data/enums/enums.dart';
import 'reference_model.dart';

part 'participation_model.g.dart';

/// 참가 · 체크인 DTO (REST §6 + check-in api-contract).

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class ParticipationUser {
  const ParticipationUser({
    required this.id,
    this.nickname,
    this.oneLiner,
    this.photoUrl,
    this.interests,
  });

  final String id;

  /// 프로필 미완성 상태로 참가한 유저는 null로 온다 → "익명"으로 표시.
  final String? nickname;
  final String? oneLiner;
  final String? photoUrl;

  /// 서버 목록 응답이 생략할 수 있다 → 소비처는 `?? []`로 방어한다.
  final List<InterestTag>? interests;

  factory ParticipationUser.fromJson(Map<String, dynamic> json) =>
      _$ParticipationUserFromJson(json);
  Map<String, dynamic> toJson() => _$ParticipationUserToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class ParticipationRow {
  const ParticipationRow({
    required this.id,
    required this.user,
    required this.status,
    required this.joinedAt,
    this.checkedInAt,
  });

  final String id;
  final ParticipationUser user;
  final ParticipationStatus status;
  final String joinedAt;

  /// 참석(체크인) 시각. null = 미참석.
  /// 실 dev 서버가 체크인 엔드포인트를 아직 안 주면 필드 자체가 생략된다.
  /// 판정은 `checkedInAt != null`로만 한다(시각 정밀도는 서버 정책).
  final String? checkedInAt;

  bool get attended => checkedInAt != null;

  factory ParticipationRow.fromJson(Map<String, dynamic> json) =>
      _$ParticipationRowFromJson(json);
  Map<String, dynamic> toJson() => _$ParticipationRowToJson(this);
}

/// 6.5 내 신청 목록 아이템.
@JsonSerializable(fieldRename: FieldRename.snake)
class MyParticipation {
  const MyParticipation({
    required this.id,
    required this.status,
    required this.joinedAt,
    required this.channel,
  });

  final String id;
  final ParticipationStatus status;
  final String joinedAt;
  final MyParticipationChannel channel;

  factory MyParticipation.fromJson(Map<String, dynamic> json) =>
      _$MyParticipationFromJson(json);
  Map<String, dynamic> toJson() => _$MyParticipationToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MyParticipationChannel {
  const MyParticipationChannel({
    required this.slug,
    required this.title,
    required this.startAt,
    required this.status,
  });

  final String slug;
  final String title;
  final String startAt;
  final ChannelStatus status;

  factory MyParticipationChannel.fromJson(Map<String, dynamic> json) =>
      _$MyParticipationChannelFromJson(json);
  Map<String, dynamic> toJson() => _$MyParticipationChannelToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ParticipationCreateResponse {
  const ParticipationCreateResponse({
    required this.id,
    required this.channelId,
    required this.status,
    required this.joinedAt,
  });

  final String id;
  final String channelId;
  final ParticipationStatus status;
  final String joinedAt;

  factory ParticipationCreateResponse.fromJson(Map<String, dynamic> json) =>
      _$ParticipationCreateResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ParticipationCreateResponseToJson(this);
}

// ══════════════════════════════════════════════════════════════
// 체크인 (check-in api-contract C.1·C.2)
// ══════════════════════════════════════════════════════════════

/// C.1 주최자 체크인 화면(S1)용 정보.
@JsonSerializable(fieldRename: FieldRename.snake)
class CheckInInfo {
  const CheckInInfo({
    required this.code,
    required this.serverTime,
    required this.window,
    required this.checkedIn,
    required this.total,
  });

  /// 6자리 숫자 문자열. 채널당 고정(서버가 서명키+channel_id로 파생).
  final String code;

  /// 서버 시각(ISO-8601 UTC). 클라 시계 보정용 — 창 판정의 권위는 서버다.
  final String serverTime;

  /// 체크인 창 = start_at - 1h ~ end_at.
  final CheckInWindow window;
  final int checkedIn;
  final int total;

  factory CheckInInfo.fromJson(Map<String, dynamic> json) =>
      _$CheckInInfoFromJson(json);
  Map<String, dynamic> toJson() => _$CheckInInfoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CheckInWindow {
  const CheckInWindow({required this.opensAt, required this.closesAt});

  final String opensAt;
  final String closesAt;

  factory CheckInWindow.fromJson(Map<String, dynamic> json) =>
      _$CheckInWindowFromJson(json);
  Map<String, dynamic> toJson() => _$CheckInWindowToJson(this);
}

/// C.2 체크인 실행 결과(S3).
@JsonSerializable(fieldRename: FieldRename.snake)
class CheckInResult {
  const CheckInResult({
    required this.checkedInAt,
    required this.already,
    required this.checkedInCount,
    required this.totalCount,
  });

  final String checkedInAt;

  /// true = 이미 참석 처리돼 있던 중복 제출(멱등).
  final bool already;
  final int checkedInCount;
  final int totalCount;

  factory CheckInResult.fromJson(Map<String, dynamic> json) =>
      _$CheckInResultFromJson(json);
  Map<String, dynamic> toJson() => _$CheckInResultToJson(this);
}
