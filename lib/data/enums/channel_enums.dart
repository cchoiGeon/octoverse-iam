import 'package:json_annotation/json_annotation.dart';

/// 모임 관련 enum — `IAM_web/src/types/api.ts` + `lib/enums/labels.ts` 이식.
/// UI는 raw enum 값을 절대 그리지 않는다. 반드시 `.label`을 쓴다.

// ── 모임 상태 (서버가 내려주는 값) ────────────────────────────
enum ChannelStatus {
  @JsonValue('open')
  open,
  @JsonValue('closed')
  closed;

  String get label => switch (this) {
    ChannelStatus.open => '모집중',
    ChannelStatus.closed => '종료',
  };
}

/// 모임 생애주기 — **서버 status가 아니라 시각·정원으로 계산한 값**.
///
/// 서버에 자동 종료 배치가 없어 이미 끝난 모임도 `status="open"`으로 남는다.
/// 주최자의 수동 종료(`closed`)만 조기 종료로 존중한다.
/// 계산은 `ChannelUtils.phaseOf()` 참고.
enum ChannelPhase {
  /// 모집중 — 시작 전, 자리 여유
  open,

  /// 마감임박 — 시작 전, 잔여석 15% 이하
  soon,

  /// 정원 마감 — 시작 전, 잔여석 0
  full,

  /// 진행 중 — start_at ≤ now < end_at
  live,

  /// 지난 모임 — end_at ≤ now, 또는 주최자 수동 종료
  past;

  /// 배지 라벨. 마감임박일 때만 남은 자리를 덧붙여 긴급성을 준다.
  String label({int joined = 0, int capacity = 0}) => switch (this) {
    ChannelPhase.past => '지난 모임',
    ChannelPhase.live => '진행 중',
    ChannelPhase.full => '정원 마감',
    ChannelPhase.soon => '마감임박 · ${(capacity - joined).clamp(0, capacity)}자리',
    ChannelPhase.open => '모집중',
  };

  /// 커버 스크림 — 더 이상 신청을 받지 않는 상태. 진행 중은 오히려 강조한다.
  bool get isDimmed => this == ChannelPhase.full || this == ChannelPhase.past;
}

/// 상세 화면 하단 CTA 상태. `ChannelUtils.ctaOf()`가 계산한다.
enum ChannelCta {
  /// 신청 가능
  join,

  /// 참가 확정 → 참가자 보기
  joined,

  /// 승인 대기
  pending,

  /// 정원 마감
  full,

  /// 종료
  closed,

  /// 내가 주최
  organizer,

  /// 비로그인 — 카카오로 시작
  guest,
}

// ── 참가 상태 ────────────────────────────────────────────────
enum ParticipationStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('accepted')
  accepted,
  @JsonValue('rejected')
  rejected;

  String get label => switch (this) {
    ParticipationStatus.pending => '승인 대기',
    ParticipationStatus.accepted => '참가 확정',
    ParticipationStatus.rejected => '거절됨',
  };
}

// ── 모임 카테고리 ────────────────────────────────────────────
enum EventCategory {
  @JsonValue('social_networking')
  socialNetworking,
  @JsonValue('conference_seminar')
  conferenceSeminar,
  @JsonValue('workshop_study')
  workshopStudy,
  @JsonValue('expo_exhibition')
  expoExhibition,
  @JsonValue('orientation')
  orientation,
  @JsonValue('meetup_lounge')
  meetupLounge,
  @JsonValue('project_matching')
  projectMatching,
  @JsonValue('etc')
  etc;

  String get label => switch (this) {
    EventCategory.socialNetworking => '소셜 네트워킹',
    EventCategory.conferenceSeminar => '컨퍼런스·세미나',
    EventCategory.workshopStudy => '워크숍·스터디',
    EventCategory.expoExhibition => '박람회·전시',
    EventCategory.orientation => '오리엔테이션',
    EventCategory.meetupLounge => '밋업·라운지',
    EventCategory.projectMatching => '프로젝트 매칭',
    EventCategory.etc => '기타',
  };
}

// ── 관심사 (16종) ────────────────────────────────────────────
enum Interest {
  @JsonValue('startup')
  startup,
  @JsonValue('investment')
  investment,
  @JsonValue('development')
  development,
  @JsonValue('design')
  design,
  @JsonValue('marketing')
  marketing,
  @JsonValue('sales')
  sales,
  @JsonValue('ai_ml')
  aiMl,
  @JsonValue('blockchain_web3')
  blockchainWeb3,
  @JsonValue('content_media')
  contentMedia,
  @JsonValue('education')
  education,
  @JsonValue('health_wellbeing')
  healthWellbeing,
  @JsonValue('travel_lifestyle')
  travelLifestyle,
  @JsonValue('art_performance')
  artPerformance,
  @JsonValue('gaming')
  gaming,
  @JsonValue('music')
  music,
  @JsonValue('leadership_hr')
  leadershipHr;

  String get label => switch (this) {
    Interest.startup => '창업',
    Interest.investment => '투자',
    Interest.development => '개발',
    Interest.design => '디자인',
    Interest.marketing => '마케팅',
    Interest.sales => '세일즈',
    Interest.aiMl => 'AI·머신러닝',
    Interest.blockchainWeb3 => '블록체인·웹3',
    Interest.contentMedia => '콘텐츠·미디어',
    Interest.education => '교육',
    Interest.healthWellbeing => '헬스·웰빙',
    Interest.travelLifestyle => '여행·라이프',
    Interest.artPerformance => '예술·공연',
    Interest.gaming => '게임',
    Interest.music => '음악',
    Interest.leadershipHr => '리더십·HR',
  };
}
