import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';

/// IamCheckbox — IAM DS · forms
///
/// 원형 24px. 체크되면 인디고 채움 + 흰 체크.
/// `IAM_web/src/components/ds/forms/Checkbox.tsx` 이식 (Figma 194:15).
class IamCheckbox extends StatelessWidget {
  const IamCheckbox({
    super.key,
    required this.checked,
    this.onChanged,
    this.enabled = true,
    this.presentational = false,
    this.semanticLabel,
  });

  final bool checked;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  /// 표현 전용 — 부모 행이 탭을 담당할 때 시각만 그린다.
  /// (약관 동의 행처럼 행 전체가 하나의 인터랙티브 요소인 경우)
  final bool presentational;

  final String? semanticLabel;

  static const _size = 24.0;

  @override
  Widget build(BuildContext context) {
    final disabled = !enabled || (!presentational && onChanged == null);

    final box = Opacity(
      opacity: disabled ? 0.5 : 1,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: checked ? AppColors.primary : AppColors.surfaceSunken,
          borderRadius: BorderRadius.circular(AppDimens.radiusPill),
          border: checked ? null : Border.all(color: AppColors.borderDefault),
        ),
        alignment: Alignment.center,
        child: checked
            ? const IamIcon(
                IamIconName.check,
                size: 16,
                strokeWidth: 3,
                color: AppColors.gray0,
              )
            : null,
      ),
    );

    if (presentational) return ExcludeSemantics(child: box);

    return Semantics(
      checked: checked,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled ? null : () => onChanged!(!checked),
        // 시각은 24px 이지만 터치는 44px — 모바일 최소 타깃.
        child: SizedBox(
          width: AppDimens.touchMin,
          height: AppDimens.touchMin,
          child: Center(child: box),
        ),
      ),
    );
  }
}
