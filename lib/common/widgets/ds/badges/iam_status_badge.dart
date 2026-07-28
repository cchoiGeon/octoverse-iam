import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/data/enums/channel_enums.dart';

/// 상태 배지 톤 — 의미 매핑.
enum IamStatusTone {
  /// 모집중
  open,

  /// 마감임박
  soon,

  /// 진행 중
  live,

  /// 마감 · 지난 모임
  closed,

  neutral,
  info;

  /// 모임 phase → 배지 톤. `IAM_web/src/components/ds/events/status.ts` 대응.
  /// full(정원 마감)과 past(지난 모임)는 같은 회색 톤을 쓴다.
  static IamStatusTone fromPhase(ChannelPhase phase) => switch (phase) {
    ChannelPhase.open => IamStatusTone.open,
    ChannelPhase.soon => IamStatusTone.soon,
    ChannelPhase.live => IamStatusTone.live,
    ChannelPhase.full || ChannelPhase.past => IamStatusTone.closed,
  };
}

enum IamStatusBadgeSize { sm, md }

/// IamStatusBadge — IAM DS · badges
///
/// 모임 생애주기·정원 등의 상태 배지. **항상 텍스트를 동반한다**
/// (색만으로 의미를 전달하지 않는다 — 접근성).
///
/// `IAM_web/src/components/ds/badges/StatusBadge.tsx` 이식.
class IamStatusBadge extends StatelessWidget {
  const IamStatusBadge(
    this.label, {
    super.key,
    this.tone = IamStatusTone.neutral,
    this.dot = true,
    this.size = IamStatusBadgeSize.md,
  });

  /// phase에서 라벨·톤을 한 번에 만든다. 카드·상세 헤더가 주로 쓴다.
  factory IamStatusBadge.fromPhase(
    ChannelPhase phase, {
    Key? key,
    int joined = 0,
    int capacity = 0,
    bool dot = true,
    IamStatusBadgeSize size = IamStatusBadgeSize.md,
  }) => IamStatusBadge(
    phase.label(joined: joined, capacity: capacity),
    key: key,
    tone: IamStatusTone.fromPhase(phase),
    dot: dot,
    size: size,
  );

  final String label;
  final IamStatusTone tone;

  /// 앞쪽 상태 점.
  final bool dot;
  final IamStatusBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final sm = size == IamStatusBadgeSize.sm;
    final (bg, fg, dotColor) = switch (tone) {
      IamStatusTone.open => (
        AppColors.statusOpenBg,
        AppColors.statusOpenFg,
        AppColors.success600,
      ),
      IamStatusTone.soon => (
        AppColors.statusSoonBg,
        AppColors.statusSoonFg,
        AppColors.warning600,
      ),
      IamStatusTone.live => (
        AppColors.statusLiveBg,
        AppColors.statusLiveFg,
        AppColors.info600,
      ),
      IamStatusTone.closed => (
        AppColors.statusClosedBg,
        AppColors.statusClosedFg,
        AppColors.gray400,
      ),
      IamStatusTone.neutral => (
        AppColors.surfaceSunken,
        AppColors.textSecondary,
        AppColors.gray400,
      ),
      IamStatusTone.info => (
        AppColors.info50,
        AppColors.info700,
        AppColors.info600,
      ),
    };

    return Container(
      height: sm ? 22 : 26,
      padding: EdgeInsets.symmetric(horizontal: sm ? 8 : 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: sm ? 5 : 6),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: (sm ? AppTypography.label : AppTypography.caption).copyWith(
              height: 1,
              fontWeight: AppTypography.semibold,
              letterSpacing: (sm ? 12 : 13) * -0.01,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
