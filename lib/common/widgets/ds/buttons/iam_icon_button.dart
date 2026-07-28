import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';

/// IamIconButton — IAM DS · buttons
///
/// 아이콘 전용 버튼. 시각 크기와 무관하게 터치 영역은 최소 44px을 지킨다.
/// `IAM_web/src/components/ds/buttons/IconButton.tsx` 이식.
class IamIconButton extends StatefulWidget {
  const IamIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.size = 24,
    this.color,
    this.enabled = true,
  });

  final IamIconName icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  /// 아이콘 자체 크기. 버튼 박스는 항상 44px.
  final double size;

  final Color? color;
  final bool enabled;

  @override
  State<IamIconButton> createState() => _IamIconButtonState();
}

class _IamIconButtonState extends State<IamIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = !widget.enabled || widget.onPressed == null;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: disabled ? null : () => setState(() => _pressed = false),
        onTap: disabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          child: Opacity(
            opacity: disabled ? 0.4 : 1,
            child: Container(
              width: AppDimens.touchMin,
              height: AppDimens.touchMin,
              decoration: BoxDecoration(
                color: _pressed
                    ? AppColors.surfaceSunken
                    : const Color(0x00000000),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: IamIcon(
                widget.icon,
                size: widget.size,
                color: widget.color ?? AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
