import 'package:json_annotation/json_annotation.dart';

/// 알림 · 명함교환 · 찜 관련 enum — `IAM_web/src/types/api.ts` 이식.

// ── 알림 종류 ────────────────────────────────────────────────
enum NotificationType {
  @JsonValue('welcome')
  welcome,
  @JsonValue('participation_ack')
  participationAck,
  @JsonValue('reminder_24h')
  reminder24h,
  @JsonValue('reminder_1h')
  reminder1h,
  @JsonValue('channel_updated')
  channelUpdated,
  @JsonValue('channel_cancelled')
  channelCancelled,
  @JsonValue('card_exchange_requested')
  cardExchangeRequested,
  @JsonValue('card_exchange_accepted')
  cardExchangeAccepted,
  @JsonValue('card_exchange_cancelled')
  cardExchangeCancelled;

  String get label => switch (this) {
    NotificationType.welcome => '환영합니다',
    NotificationType.participationAck => '참가 신청이 접수됐어요',
    NotificationType.reminder24h => '모임 24시간 전이에요',
    NotificationType.reminder1h => '모임 1시간 전이에요',
    NotificationType.channelUpdated => '모임 정보가 변경됐어요',
    NotificationType.channelCancelled => '모임이 취소됐어요',
    NotificationType.cardExchangeRequested => '명함 교환 요청이 도착했어요',
    NotificationType.cardExchangeAccepted => '명함 교환이 수락됐어요',
    NotificationType.cardExchangeCancelled => '명함 교환 요청이 취소됐어요',
  };
}

/// FCM data payload 의 문자열 → enum.
///
/// `@JsonValue` 와 값이 같아야 해서 바로 아래에 둔다 — 떨어뜨려 놓으면 한쪽만
/// 고치고 지나가기 쉽다. json_serializable 의 역직렬화는 모르는 값에 예외를
/// 던지지만, 푸시는 서버가 새 타입을 추가해도 앱이 죽으면 안 되므로 null 을 준다.
extension NotificationTypeParse on NotificationType {
  static NotificationType? tryParse(String? raw) => switch (raw) {
    'welcome' => NotificationType.welcome,
    'participation_ack' => NotificationType.participationAck,
    'reminder_24h' => NotificationType.reminder24h,
    'reminder_1h' => NotificationType.reminder1h,
    'channel_updated' => NotificationType.channelUpdated,
    'channel_cancelled' => NotificationType.channelCancelled,
    'card_exchange_requested' => NotificationType.cardExchangeRequested,
    'card_exchange_accepted' => NotificationType.cardExchangeAccepted,
    'card_exchange_cancelled' => NotificationType.cardExchangeCancelled,
    _ => null,
  };
}

// ── 명함 교환 상태 ───────────────────────────────────────────
enum CardExchangeStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('accepted')
  accepted,
  @JsonValue('rejected')
  rejected;

  String get label => switch (this) {
    CardExchangeStatus.pending => '대기중',
    CardExchangeStatus.accepted => '교환 완료',
    CardExchangeStatus.rejected => '거절됨',
  };
}

// ── 방향 (교환 · 찜 공용) ────────────────────────────────────
enum ExchangeDirection {
  @JsonValue('sent')
  sent,
  @JsonValue('received')
  received;

  String get label => switch (this) {
    ExchangeDirection.sent => '보낸 요청',
    ExchangeDirection.received => '받은 요청',
  };

  /// 쿼리 파라미터로 보낼 값.
  String get value => name;
}

/// 프로필 상세의 "명함 교환" 버튼 상태 (UI 전용 파생값).
///
/// 웹보다 한 가지가 많다 — `incoming`.
/// 상대가 이미 나에게 요청을 보낸 상태에서 "대기중"을 띄우면 양쪽 다
/// 무한정 기다리게 되므로, 내가 수락할 수 있음을 알려준다.
enum CardExchangeCta {
  /// 요청 가능
  active,

  /// 목록 조회 중 — 확정 전에 "요청 가능"을 보이면 중복 요청이 나간다
  loading,

  /// 내 명함 미등록 → 먼저 등록 유도
  noOwnCard,

  /// 내가 보냈고 상대 수락 대기
  pending,

  /// 상대가 나에게 보냄 → 내가 수락
  incoming,

  /// 교환 완료
  done,
}

// ── 소셜 로그인 제공자 ───────────────────────────────────────
enum AuthProvider {
  kakao,
  google,
  apple;

  /// `POST /auth/oauth/{provider}` 의 경로 조각.
  String get path => name;

  String get label => switch (this) {
    AuthProvider.kakao => '카카오',
    AuthProvider.google => '구글',
    AuthProvider.apple => '애플',
  };
}
