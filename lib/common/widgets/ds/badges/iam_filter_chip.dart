import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';

enum IamFilterChipSize { sm, md }

/// IamFilterChip — IAM DS · badges
///
/// 토글되는 필터·선택 칩. 색과 아이콘 **둘 다**로 선택을 알린다(접근성).
/// `IAM_web/src/components/ds/badges/FilterChip.tsx` 이식.
///
/// `IamTagSelect`가 다중 선택 묶음이라면 이건 낱개 칩이다 —
/// 단일 선택 그룹(직무·링크 유형 등)이나 필터 시트에서 쓴다.
class IamFilterChip extends StatelessWidget {
  const IamFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.enabled = true,
    this.count,
    this.removable = false,
    this.indicator = true,
    this.size = IamFilterChipSize.md,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;

  /// 우측 카운트.
  final int? count;

  /// 활성 필터 제거형 — 우측에 X.
  final bool removable;

  /// 리딩 ＋↔✓ 슬롯. 정렬처럼 자체 아이콘을 쓰는 칩은 false.
  final bool indicator;

  final IamFilterChipSize size;

  @override
  Widget build(BuildContext context) {
    final sm = size == IamFilterChipSize.sm;
    final disabled = !enabled || onTap == null;
    final fg = selected ? AppColors.onPrimary : AppColors.textSecondary;

    return Semantics(
      checked: selected,
      enabled: !disabled,
      label: label,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Opacity(
          opacity: disabled ? 0.4 : 1,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            height: sm ? 32 : 38,
            padding: EdgeInsets.symmetric(horizontal: sm ? 12 : 14),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppDimens.radiusPill),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.borderStrong,
                width: AppDimens.borderWidthStrong,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 리딩 슬롯 고정 — 선택/해제로 칩 너비가 흔들리지 않게.
                if (indicator && !removable) ...[
                  SizedBox(
                    width: sm ? 14 : 16,
                    child: Center(
                      child: IamIcon(
                        selected ? IamIconName.check : IamIconName.plus,
                        size: sm ? 14 : 16,
                        strokeWidth: 2.6,
                        color: selected ? fg : fg.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: (sm ? AppTypography.bodyS : AppTypography.body)
                      .copyWith(
                        height: 1,
                        fontWeight: AppTypography.semibold,
                        letterSpacing: (sm ? 14 : 15) * -0.01,
                        color: fg,
                      ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 5),
                  Text(
                    '$count',
                    style: (sm ? AppTypography.bodyS : AppTypography.body)
                        .copyWith(
                          height: 1,
                          fontWeight: AppTypography.medium,
                          color: fg.withValues(alpha: 0.7),
                        ),
                  ),
                ],
                if (removable) ...[
                  const SizedBox(width: 5),
                  IamIcon(
                    IamIconName.close,
                    size: sm ? 14 : 15,
                    strokeWidth: 2.4,
                    color: fg.withValues(alpha: 0.8),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
