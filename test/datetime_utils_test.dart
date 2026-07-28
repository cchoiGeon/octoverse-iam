import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:iam/common/utils/datetime_utils.dart';

/// 날짜·시간 표시 테스트.
///
/// 서버는 UTC ISO-8601로 주고 화면은 KST로 보여준다. 이 변환이 어긋나면
/// 모임 시각이 9시간 밀린다.
void main() {
  setUpAll(() => initializeDateFormatting('ko_KR'));

  // 2026-06-23T10:18:00Z == KST 2026-06-23 19:18 (화)
  const eveningUtc = '2026-06-23T10:18:00.000Z';

  group('KST 변환', () {
    test('UTC → KST 로 +9시간 보정한다', () {
      expect(DateTimeUtils.toKst(eveningUtc).hour, 19);
    });

    test('날짜 경계를 넘겨도 KST 날짜로 표시한다', () {
      // UTC 2026-06-23 16:00 == KST 2026-06-24 01:00
      expect(DateTimeUtils.eventDate('2026-06-23T16:00:00.000Z'), '6월 24일 (수)');
    });
  });

  group('시간 표기 — 오전/오후', () {
    // ⚠️ intl 0.20의 ko 로케일은 AM/PM을 "AM"/"PM"으로 준다(CLDR 42 변경).
    //    웹·Figma는 "오후"라서 직접 조립한다. 이 테스트가 그 계약을 지킨다.
    test('오후를 한국어로 쓴다', () {
      expect(DateTimeUtils.time(eveningUtc), '오후 7:18');
    });

    test('오전을 한국어로 쓴다', () {
      // UTC 2026-06-23 00:30 == KST 09:30
      expect(DateTimeUtils.time('2026-06-23T00:30:00.000Z'), '오전 9:30');
    });

    test('정오는 오후 12시', () {
      // UTC 03:00 == KST 12:00
      expect(DateTimeUtils.time('2026-06-23T03:00:00.000Z'), '오후 12:00');
    });

    test('자정은 오전 12시', () {
      // UTC 15:00 == KST 익일 00:00
      expect(DateTimeUtils.time('2026-06-23T15:00:00.000Z'), '오전 12:00');
    });

    test('분은 두 자리로 채운다', () {
      expect(DateTimeUtils.time('2026-06-23T10:05:00.000Z'), '오후 7:05');
    });
  });

  group('eventRange — 목록·상세의 일시 한 줄', () {
    test('같은 날이면 날짜를 한 번만 쓴다', () {
      final s = DateTimeUtils.eventRange(
        '2026-06-23T10:00:00.000Z', // KST 19:00
        '2026-06-23T12:00:00.000Z', // KST 21:00
      );
      expect(s, '6월 23일 (화) · 오후 7:00–오후 9:00');
    });

    test('날짜를 넘기면 종료 날짜까지 쓴다', () {
      final s = DateTimeUtils.eventRange(
        '2026-06-23T10:00:00.000Z', // KST 6/23 19:00
        '2026-06-26T10:00:00.000Z', // KST 6/26 19:00
      );
      expect(s, contains('6월 26일 (금)'));
    });
  });

  group('toUtcIso — 입력 폼 → 서버', () {
    test('KST 입력을 UTC로 되돌린다 (왕복 일치)', () {
      final kst = DateTimeUtils.toKst(eveningUtc);
      expect(DateTimeUtils.toUtcIso(kst), eveningUtc);
    });
  });
}
