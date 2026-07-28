import 'package:iam/common/constants/defines.dart';
import 'package:iam/data/data_manager.dart';

/// 모임 생애주기 · CTA · 체크인 창 판정.
/// `IAM_web/src/lib/format/channel.ts` 이식 — 앱에서도 규칙이 같아야 한다.
abstract final class ChannelUtils {
  /// 모임 phase 판정.
  ///
  /// **서버 status를 그대로 믿지 않는다.** 서버에 자동 종료 배치가 없어
  /// 이미 끝난 모임도 `open`으로 남는다. 주최자의 수동 종료(`closed`)만
  /// 조기 종료로 존중하고, 나머지는 시각·정원으로 계산한다.
  ///
  /// [now]를 주입 가능하게 둔 이유는 테스트 때문이다.
  static ChannelPhase phaseOf({
    required ChannelStatus status,
    required String startAt,
    required String endAt,
    required int capacity,
    required int acceptedCount,
    DateTime? now,
  }) {
    final at = (now ?? DateTime.now()).toUtc();

    if (status == ChannelStatus.closed) return ChannelPhase.past;

    // ⚠️ 파싱 실패 시 "끝났다"고 단정하지 않는다.
    //    멀쩡한 모임을 지난 모임으로 잘못 잠그는 쪽이 더 나쁘다.
    final end = DateTime.tryParse(endAt)?.toUtc();
    if (end != null && !at.isBefore(end)) return ChannelPhase.past;

    final start = DateTime.tryParse(startAt)?.toUtc();
    if (start != null && !at.isBefore(start)) return ChannelPhase.live;

    final remaining = capacity - acceptedCount;
    if (remaining <= 0) return ChannelPhase.full;

    // 잔여 15% 이하(최소 2석)면 마감임박.
    final threshold = (capacity * 0.15).ceil();
    if (remaining <= (threshold < 2 ? 2 : threshold)) return ChannelPhase.soon;

    return ChannelPhase.open;
  }

  /// 목록 아이템용 축약.
  static ChannelPhase phaseOfListItem(ChannelListItem c, {DateTime? now}) =>
      phaseOf(
        status: c.status,
        startAt: c.startAt,
        endAt: c.endAt,
        capacity: c.capacity,
        acceptedCount: c.acceptedCount,
        now: now,
      );

  /// 상세용 축약.
  static ChannelPhase phaseOfDetail(ChannelDetail c, {DateTime? now}) =>
      phaseOf(
        status: c.status,
        startAt: c.startAt,
        endAt: c.endAt,
        capacity: c.capacity,
        acceptedCount: c.acceptedCount,
        now: now,
      );

  /// 상세 화면 하단 CTA 상태.
  ///
  /// [isAuthenticated]가 false면 `guest`(카카오로 시작).
  static ChannelCta ctaOf(
    ChannelDetail c, {
    required bool isOrganizer,
    required bool isAuthenticated,
    DateTime? now,
  }) {
    if (!isAuthenticated) return ChannelCta.guest;
    if (isOrganizer) return ChannelCta.organizer;

    // 지난 모임이어도 참가 확정자는 참가자 목록(명함·찜)에 계속 들어갈 수 있어야 한다.
    if (c.myParticipation?.status == ParticipationStatus.accepted) {
      return ChannelCta.joined;
    }

    final phase = phaseOfDetail(c, now: now);
    if (phase == ChannelPhase.past) return ChannelCta.closed;
    if (c.myParticipation?.status == ParticipationStatus.pending) {
      return ChannelCta.pending;
    }
    if (phase == ChannelPhase.full) return ChannelCta.full;
    return ChannelCta.join;
  }

  /// 체크인 창 = start_at - 1시간 ~ end_at.
  ///
  /// ⚠️ 이 계산은 **진입점(FAB·배너) 노출용일 뿐**이다. 최종 판정은 전적으로
  ///    서버가 한다(클라 시계는 조작 가능). 서버가 거부하면 체크인 화면이
  ///    실패 상태를 띄운다.
  static CheckinWindowInfo checkinWindow(
    String startAt,
    String endAt, {
    DateTime? now,
  }) {
    final at = (now ?? DateTime.now()).toUtc();
    final start = DateTime.tryParse(startAt)?.toUtc();
    final end = DateTime.tryParse(endAt)?.toUtc();

    if (start == null || end == null) {
      // 시각을 못 읽으면 창을 닫힌 것으로 본다(FAB를 잘못 띄우지 않는다).
      return const CheckinWindowInfo(
        opensAt: null,
        closesAt: null,
        isOpen: false,
      );
    }

    final opensAt = start.subtract(kCheckinLead);
    final isOpen = !at.isBefore(opensAt) && !at.isAfter(end);
    return CheckinWindowInfo(opensAt: opensAt, closesAt: end, isOpen: isOpen);
  }
}

class CheckinWindowInfo {
  const CheckinWindowInfo({
    required this.opensAt,
    required this.closesAt,
    required this.isOpen,
  });

  final DateTime? opensAt;
  final DateTime? closesAt;
  final bool isOpen;

  /// 아직 열리기 전인지.
  bool isBefore(DateTime now) =>
      opensAt != null && now.toUtc().isBefore(opensAt!);
}
