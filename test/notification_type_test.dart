import 'package:flutter_test/flutter_test.dart';

import 'package:iam/data/enums/social_enums.dart';
import 'package:iam/data/models/social_model.dart';

/// 알림 타입 역직렬화.
///
/// 실제로 터졌던 버그를 고정한다 — 서버가 보내는 `like_received` 와
/// `participation_requested` 가 enum 에 없어서 `$enumDecode` 가 예외를 던졌고,
/// `NotificationService.load()` 의 `catch` 가 그걸 삼켜 **알림 목록 전체가**
/// 빈 배열이 됐다. 알림 5건 중 1건만 미지의 타입이어도 나머지 4건이 사라진다.
void main() {
  Map<String, dynamic> row(String type) => {
    'id': 'n1',
    'type': type,
    'created_at': '2026-08-03T05:07:30.775Z',
  };

  group('NotificationRow.fromJson', () {
    test('서버가 쓰는 타입 11종을 모두 디코드한다', () {
      const cases = {
        'welcome': NotificationType.welcome,
        'participation_ack': NotificationType.participationAck,
        'participation_requested': NotificationType.participationRequested,
        'like_received': NotificationType.likeReceived,
        'reminder_24h': NotificationType.reminder24h,
        'reminder_1h': NotificationType.reminder1h,
        'channel_updated': NotificationType.channelUpdated,
        'channel_cancelled': NotificationType.channelCancelled,
        'card_exchange_requested': NotificationType.cardExchangeRequested,
        'card_exchange_accepted': NotificationType.cardExchangeAccepted,
        'card_exchange_cancelled': NotificationType.cardExchangeCancelled,
      };

      for (final e in cases.entries) {
        expect(
          NotificationRow.fromJson(row(e.key)).type,
          e.value,
          reason: '${e.key} 가 매핑되지 않았다',
        );
      }
    });

    test('모르는 타입이 와도 예외를 던지지 않고 unknown 으로 떨어진다', () {
      expect(
        NotificationRow.fromJson(row('some_future_type')).type,
        NotificationType.unknown,
      );
    });

    test('모르는 타입 한 건이 나머지 목록을 죽이지 않는다', () {
      final rows = [
        row('welcome'),
        row('some_future_type'),
        row('like_received'),
      ].map(NotificationRow.fromJson).toList();

      expect(rows.length, 3);
      expect(
        rows.where((n) => n.type != NotificationType.unknown).length,
        2,
        reason: '미지의 타입만 걸러지고 나머지는 살아남아야 한다',
      );
    });
  });

  group('NotificationTypeParse.tryParse — FCM data payload', () {
    test('새 타입 두 종을 파싱한다', () {
      expect(
        NotificationTypeParse.tryParse('like_received'),
        NotificationType.likeReceived,
      );
      expect(
        NotificationTypeParse.tryParse('participation_requested'),
        NotificationType.participationRequested,
      );
    });

    test('모르는 값과 null 은 null 이다', () {
      expect(NotificationTypeParse.tryParse('some_future_type'), isNull);
      expect(NotificationTypeParse.tryParse(null), isNull);
    });
  });
}
