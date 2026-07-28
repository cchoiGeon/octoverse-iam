import 'package:flutter_test/flutter_test.dart';

import 'package:iam/common/utils/channel_utils.dart';
import 'package:iam/data/enums/enums.dart';

/// 모임 생애주기 판정 테스트.
///
/// 이 로직이 이 앱에서 가장 미묘하다 — **서버 status를 믿지 않고** 시각·정원으로
/// 다시 계산하기 때문이다(서버에 자동 종료 배치가 없다). 웹
/// `IAM_web/src/lib/format/channel.ts`와 규칙이 어긋나면 같은 모임이 웹과 앱에서
/// 다른 상태로 보인다.
void main() {
  // 기준 시각을 고정해 테스트가 시계에 흔들리지 않게 한다.
  final now = DateTime.utc(2026, 7, 28, 12, 0);
  String iso(Duration offset) => now.add(offset).toIso8601String();

  ChannelPhase phase({
    ChannelStatus status = ChannelStatus.open,
    Duration start = const Duration(hours: 5),
    Duration end = const Duration(hours: 8),
    int capacity = 30,
    int accepted = 10,
  }) => ChannelUtils.phaseOf(
    status: status,
    startAt: iso(start),
    endAt: iso(end),
    capacity: capacity,
    acceptedCount: accepted,
    now: now,
  );

  group('phaseOf — 생애주기', () {
    test('주최자가 수동 종료하면 시각과 무관하게 past', () {
      expect(
        phase(status: ChannelStatus.closed, start: const Duration(days: 3)),
        ChannelPhase.past,
      );
    });

    test('종료 시각이 지나면 past — 서버 status가 open이어도', () {
      expect(
        phase(start: const Duration(hours: -5), end: const Duration(hours: -1)),
        ChannelPhase.past,
      );
    });

    test('시작~종료 사이면 live', () {
      expect(
        phase(start: const Duration(hours: -1), end: const Duration(hours: 2)),
        ChannelPhase.live,
      );
    });

    test('시작 전 · 자리 여유면 open', () {
      expect(phase(capacity: 30, accepted: 10), ChannelPhase.open);
    });

    test('시작 전 · 잔여 0이면 full', () {
      expect(phase(capacity: 30, accepted: 30), ChannelPhase.full);
    });

    test('시작 전 · 잔여가 정원의 15% 이하면 soon', () {
      // 30 * 0.15 = 4.5 → ceil 5. 잔여 5 → soon
      expect(phase(capacity: 30, accepted: 25), ChannelPhase.soon);
      // 잔여 6 → 아직 open
      expect(phase(capacity: 30, accepted: 24), ChannelPhase.open);
    });

    test('작은 정원은 최소 2석을 임계값으로 쓴다', () {
      // 5 * 0.15 = 0.75 → ceil 1 이지만 하한 2가 적용된다. 잔여 2 → soon
      expect(phase(capacity: 5, accepted: 3), ChannelPhase.soon);
    });

    test('진행 중이면 정원이 차 있어도 live가 우선한다', () {
      expect(
        phase(
          start: const Duration(hours: -1),
          end: const Duration(hours: 2),
          capacity: 30,
          accepted: 30,
        ),
        ChannelPhase.live,
      );
    });

    test('시각을 파싱할 수 없으면 past로 단정하지 않는다', () {
      // 멀쩡한 모임을 "지난 모임"으로 잘못 잠그는 쪽이 더 나쁘다.
      final result = ChannelUtils.phaseOf(
        status: ChannelStatus.open,
        startAt: 'not-a-date',
        endAt: 'not-a-date',
        capacity: 30,
        acceptedCount: 10,
        now: now,
      );
      expect(result, isNot(ChannelPhase.past));
    });
  });

  group('checkinWindow — 체크인 창', () {
    test('시작 1시간 전에 열린다', () {
      final w = ChannelUtils.checkinWindow(
        iso(const Duration(minutes: 59)),
        iso(const Duration(hours: 3)),
        now: now,
      );
      expect(w.isOpen, isTrue);
    });

    test('시작 1시간 이전에는 닫혀 있다', () {
      final w = ChannelUtils.checkinWindow(
        iso(const Duration(minutes: 61)),
        iso(const Duration(hours: 3)),
        now: now,
      );
      expect(w.isOpen, isFalse);
      expect(w.isBefore(now), isTrue);
    });

    test('종료 시각을 넘기면 닫힌다', () {
      final w = ChannelUtils.checkinWindow(
        iso(const Duration(hours: -5)),
        iso(const Duration(minutes: -1)),
        now: now,
      );
      expect(w.isOpen, isFalse);
    });

    test('시각을 파싱할 수 없으면 창을 닫힌 것으로 본다', () {
      // FAB를 잘못 띄우지 않는 쪽이 안전하다.
      final w = ChannelUtils.checkinWindow('x', 'y', now: now);
      expect(w.isOpen, isFalse);
      expect(w.opensAt, isNull);
    });
  });
}
