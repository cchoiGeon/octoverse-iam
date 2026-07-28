import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';

/// IamToggle — IAM DS · forms
///
/// 스위치. track 44×26 · knob 20. on=인디고 / off=회색.
/// `IAM_web/src/components/ds/forms/Toggle.tsx` 이식 (Figma 174:35).
class IamToggle extends StatelessWidget {
  const IamToggle({
    super.key,
    required this.checked,
    this.onChanged,
    this.enabled = true,
    this.semanticLabel,
  });

  final bool checked;
  final ValueChanged<bool>? onChanged;
  final bool enabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final disabled = !enabled || onChanged == null;

    return Semantics(
      toggled: checked,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled ? null : () => onChanged!(!checked),
        child: Opacity(
          opacity: disabled ? 0.5 : 1,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            width: 44,
            height: 26,
            decoration: BoxDecoration(
              color: checked ? AppColors.primary : AppColors.borderStrong,
              borderRadius: BorderRadius.circular(AppDimens.radiusPill),
            ),
            child: AnimatedAlign(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              alignment: checked ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(3),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.gray0,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.elev1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
