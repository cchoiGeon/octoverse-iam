import 'package:iam/core/route/app_pages.dart';
import 'package:iam/data/enums/enums.dart';

/// FCM `data` payload → 이동할 라우트.
///
/// `RemoteMessage` 를 받지 않는다. Firebase 없이 테스트할 수 있어야 하고,
/// 알림 타입이 늘 때 손댈 곳을 여기 하나로 묶어두기 위해서다.
///
/// 서버가 보내는 payload 규격은 `docs/server-requirements-fcm.md` §2 참고.
/// 값이 빠지거나 모르는 타입이 와도 **절대 던지지 않는다** — 푸시를 탭했는데
/// 앱이 죽는 것보다 알림함이 열리는 게 낫다.
String routeForPush(Map<String, dynamic> data) {
  // `as String?` 는 값이 있는데 String 이 아니면(e.g. `{'type': 123}`) 던진다.
  // FCM 프로토콜상 data 값은 전부 문자열이라 오늘은 안 일어나지만, 이
  // 함수의 계약("절대 던지지 않는다")은 입력 형태를 가리지 않는다.
  final rawType = data['type'];
  final type = NotificationTypeParse.tryParse(
    rawType is String ? rawType : null,
  );
  if (type == null) return AppRoutes.meNotifications;

  final rawSlug = data['channel_slug'];
  final slug = (rawSlug is String ? rawSlug : null)?.trim();

  // enum 위의 exhaustive switch — NotificationType 에 값이 추가되면
  // 여기서 컴파일 에러가 나서 라우트 결정을 강제한다.
  return switch (type) {
    NotificationType.participationAck ||
    NotificationType.reminder24h ||
    NotificationType.reminder1h ||
    NotificationType.channelUpdated ||
    NotificationType.channelCancelled =>
      (slug == null || slug.isEmpty)
          ? AppRoutes.meNotifications
          : AppRoutes.eventDetailOf(slug),

    // 주최자에게 가는 알림이다. 상세가 아니라 승인/거절을 할 수 있는
    // 참가자 관리로 보낸다 — 탭한 이유가 곧 처리이기 때문이다.
    NotificationType.participationRequested =>
      (slug == null || slug.isEmpty)
          ? AppRoutes.meNotifications
          : AppRoutes.eventManageOf(slug),

    // 누가 찜했는지는 모임이 아니라 찜 목록에서 본다.
    NotificationType.likeReceived => AppRoutes.meLikes,

    NotificationType.cardExchangeRequested ||
    NotificationType.cardExchangeAccepted ||
    NotificationType.cardExchangeCancelled => AppRoutes.meCards,

    // `unknown` 은 tryParse 가 null 로 걸러 여기까지 오지 않지만, switch 가
    // 총체적이어야 해서 둔다. 모르는 알림의 착지점은 알림함이다.
    NotificationType.welcome ||
    NotificationType.unknown => AppRoutes.meNotifications,
  };
}
