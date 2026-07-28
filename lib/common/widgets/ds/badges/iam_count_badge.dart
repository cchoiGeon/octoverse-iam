import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';

/// IamCountBadge — IAM DS · badges
///
/// 숫자 배지(알림 종 등). 코랄 pill + 흰 테두리로 배경과 분리한다.
/// Figma NotificationBell(node 166:41) 스펙: 16px · 8px Bold · 1.5px 흰 테두리.
///
/// `IAM_web/src/components/ds/badges/CountBadge.tsx` 이식.
class IamCountBadge extends StatelessWidget {
  const IamCountBadge({super.key, required this.count, this.max = 99});

  /// 0 이하면 아무것도 그리지 않는다.
  final int count;

  /// 초과하면 "99+" 형태로 줄인다.
  final int max;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final text = count > max ? '$max+' : '$count';

    return Container(
      constraints: const BoxConstraints(minWidth: 16),
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        border: Border.all(color: AppColors.surfaceCard, width: 1.5),
      ),
      child: Text(
        text,
        style: AppTypography.label.copyWith(
          fontSize: 8,
          height: 1,
          fontWeight: AppTypography.bold,
          letterSpacing: -0.08,
          color: AppColors.textOnPrimary,
        ),
      ),
    );
  }
}
