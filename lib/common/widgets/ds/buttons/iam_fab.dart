import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';

/// primary(기본·인디고) · accent(코랄 — 체크인 계열)
enum IamFabTone { primary, accent }

/// IamFab — IAM DS · buttons
///
/// 56px 원형 FAB. [label]을 주면 확장(pill) 변형이 된다.
/// `IAM_web/src/components/ds/buttons/FAB.tsx` 이식 (Figma 193:16).
class IamFab extends StatefulWidget {
  const IamFab({
    super.key,
    required this.semanticLabel,
    this.onPressed,
    this.icon,
    this.label,
    this.tone = IamFabTone.primary,
    this.enabled = true,
  });

  /// 스크린 리더용 설명. 아이콘만 있는 경우 필수.
  final String semanticLabel;
  final VoidCallback? onPressed;

  /// 없으면 plus 아이콘.
  final IamIconName? icon;

  /// 주면 확장형(아이콘 + 텍스트).
  final String? label;

  final IamFabTone tone;
  final bool enabled;

  bool get _extended => label != null && label!.isNotEmpty;

  @override
  State<IamFab> createState() => _IamFabState();
}

class _IamFabState extends State<IamFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = !widget.enabled || widget.onPressed == null;
    final extended = widget._extended;

    final bg = disabled
        ? AppColors.gray300
        : widget.tone == IamFabTone.accent
        ? AppColors.accent
        : AppColors.primary;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: disabled ? null : () => setState(() => _pressed = false),
        onTap: disabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? AppMotion.pressScale : 1.0,
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          child: Container(
            height: 56,
            width: extended ? null : 56,
            padding: extended
                ? const EdgeInsets.symmetric(horizontal: AppDimens.space5)
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppDimens.radiusPill),
              boxShadow: AppShadows.elev3,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IamIcon(
                  widget.icon ?? IamIconName.plus,
                  size: extended ? 20 : 26,
                  color: AppColors.gray0,
                ),
                if (extended) ...[
                  const SizedBox(width: AppDimens.space2),
                  Text(
                    widget.label!,
                    style: AppTypography.body.copyWith(
                      height: 1,
                      fontWeight: AppTypography.semibold,
                      letterSpacing: -0.15,
                      color: AppColors.gray0,
                    ),
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
