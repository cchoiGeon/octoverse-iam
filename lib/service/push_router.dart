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
  final type = NotificationTypeParse.tryParse(data['type'] as String?);
  if (type == null) return AppRoutes.meNotifications;

  final slug = (data['channel_slug'] as String?)?.trim();

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

    NotificationType.cardExchangeRequested ||
    NotificationType.cardExchangeAccepted ||
    NotificationType.cardExchangeCancelled => AppRoutes.meCards,

    NotificationType.welcome => AppRoutes.meNotifications,
  };
}
