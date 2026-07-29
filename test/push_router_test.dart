import 'package:flutter_test/flutter_test.dart';

import 'package:iam/core/route/app_pages.dart';
import 'package:iam/service/push_router.dart';

/// FCM data payload → 이동할 화면.
///
/// 서버가 보내는 값을 앱이 그대로 믿고 라우팅하는 지점이라, 값이 빠지거나
/// 모르는 타입이 와도 크래시 없이 알림함으로 떨어져야 한다.
void main() {
  group('모임 관련 알림 → 모임 상세', () {
    for (final type in [
      'participation_ack',
      'reminder_24h',
      'reminder_1h',
      'channel_updated',
      'channel_cancelled',
    ]) {
      test('$type 은 slug 로 모임 상세를 연다', () {
        expect(
          routeForPush({'type': type, 'channel_slug': 'ai-meetup'}),
          '/event/ai-meetup',
        );
      });
    }
  });

  group('명함 교환 알림 → 명함함', () {
    for (final type in [
      'card_exchange_requested',
      'card_exchange_accepted',
      'card_exchange_cancelled',
    ]) {
      test('$type 은 명함함을 연다', () {
        expect(routeForPush({'type': type}), AppRoutes.meCards);
      });
    }
  });

  test('welcome 은 알림함을 연다', () {
    expect(routeForPush({'type': 'welcome'}), AppRoutes.meNotifications);
  });

  group('망가진 payload 는 알림함으로 떨어진다', () {
    test('모임 알림인데 channel_slug 가 없으면', () {
      expect(routeForPush({'type': 'reminder_24h'}), AppRoutes.meNotifications);
    });

    test('channel_slug 가 빈 문자열이면', () {
      expect(
        routeForPush({'type': 'reminder_24h', 'channel_slug': '  '}),
        AppRoutes.meNotifications,
      );
    });

    test('서버가 새 타입을 추가해 앱이 모르는 값이 오면', () {
      expect(
        routeForPush({'type': 'someday_new_type'}),
        AppRoutes.meNotifications,
      );
    });

    test('type 자체가 없으면', () {
      expect(routeForPush({}), AppRoutes.meNotifications);
    });
  });
}
