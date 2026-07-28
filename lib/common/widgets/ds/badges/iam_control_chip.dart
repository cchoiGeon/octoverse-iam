import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';

/// IamControlChip — IAM DS · badges
///
/// 홈 상단의 필터·정렬 트리거 칩. 탭하면 바텀시트가 열린다.
/// 적용되면 인디고로 채워지고 적용값을 라벨 옆에 인라인 표시한다.
///
/// `IAM_web/src/components/ds/badges/ControlChip.tsx` 이식 (Figma 295:978).
class IamControlChip extends StatelessWidget {
  const IamControlChip({
    super.key,
    required this.label,
    this.icon,
    this.value,
    this.extraCount,
    this.active = false,
    this.expandable = false,
    this.onTap,
    this.enabled = true,
    this.semanticLabel,
  });

  /// 기본 라벨 — "필터" · "정렬".
  final String label;

  /// 리딩 아이콘 — sliders(필터) · sort(정렬).
  final IamIconName? icon;

  /// 적용된 값. 있으면 "라벨 · 값"으로 표시한다.
  final String? value;

  /// 값 외 추가 적용 개수 — 있으면 값 뒤에 "+N".
  final int? extraCount;

  /// 적용됨 → 인디고 채움. 미적용은 아웃라인.
  final bool active;

  /// 우측 펼침 표시(▾).
  final bool expandable;

  final VoidCallback? onTap;
  final bool enabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final disabled = !enabled || onTap == null;
    final fg = active ? AppColors.onPrimary : AppColors.textSecondary;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: semanticLabel ?? label,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Opacity(
          opacity: disabled ? 0.4 : 1,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.space4),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppDimens.radiusPill),
              border: Border.all(
                color: active ? AppColors.primary : AppColors.borderDefault,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  IamIcon(icon!, size: 16, color: fg),
                  const SizedBox(width: 5),
                ],
                Text(label, style: _text(fg)),
                if (value != null) ...[
                  const SizedBox(width: 5),
                  Text('·', style: _text(fg.withValues(alpha: 0.5))),
                  const SizedBox(width: 5),
                  Text(
                    extraCount != null && extraCount! > 0
                        ? '$value +$extraCount'
                        : value!,
                    style: _text(fg),
                  ),
                ],
                if (expandable) ...[
                  const SizedBox(width: 3),
                  IamIcon(
                    IamIconName.chevronDown,
                    size: 14,
                    color: fg.withValues(alpha: active ? 0.9 : 0.7),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _text(Color color) => AppTypography.bodyS.copyWith(
    height: 1,
    letterSpacing: -0.14,
    color: color,
  );
}
