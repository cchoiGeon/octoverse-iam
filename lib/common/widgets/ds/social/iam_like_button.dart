import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';

/// icon 원형 아이콘 · pill 라벨 포함
enum IamLikeVariant { icon, pill }

/// IamLikeButton — IAM DS · social
///
/// 찜 버튼. 찜하면 코랄 하트가 채워지고 살짝 팝 한다.
/// `IAM_web/src/components/ds/social/LikeButton.tsx` 이식.
class IamLikeButton extends StatefulWidget {
  const IamLikeButton({
    super.key,
    this.liked = false,
    this.onChanged,
    this.variant = IamLikeVariant.icon,
    this.size = 44,
    this.count,
    this.enabled = true,
  });

  final bool liked;

  /// 다음 상태를 넘긴다.
  final ValueChanged<bool>? onChanged;

  final IamLikeVariant variant;

  /// icon 변형 지름. 최소 44(터치 타깃).
  final double size;

  final int? count;
  final bool enabled;

  @override
  State<IamLikeButton> createState() => _IamLikeButtonState();
}

class _IamLikeButtonState extends State<IamLikeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );

  @override
  void didUpdateWidget(IamLikeButton old) {
    super.didUpdateWidget(old);
    // 찜할 때만 팝 — 해제는 조용히.
    if (widget.liked && !old.liked) _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  bool get _disabled => !widget.enabled || widget.onChanged == null;

  void _handle() {
    if (_disabled) return;
    widget.onChanged!(!widget.liked);
  }

  /// 0 → 1.22 → 1 로 튕기는 스케일. 웹 `iam-pop` 키프레임과 같은 곡선.
  Widget _heart(double size, Color color, {bool filled = false}) {
    return AnimatedBuilder(
      animation: _pop,
      builder: (_, child) {
        final t = _pop.value;
        final scale = t == 0 || t == 1
            ? 1.0
            : t < 0.4
            ? 1 + (0.22 * (t / 0.4))
            : 1.22 - (0.22 * ((t - 0.4) / 0.6));
        return Transform.scale(scale: scale, child: child);
      },
      child: IamIcon(
        IamIconName.heart,
        size: size,
        color: color,
        // 채움 표현이 없어 선을 굵혀 "채워진 느낌"을 낸다.
        strokeWidth: filled ? 3.2 : 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.variant == IamLikeVariant.pill ? _pill() : _icon();
  }

  Widget _icon() {
    final size = widget.size < AppDimens.touchMin
        ? AppDimens.touchMin
        : widget.size;

    return Semantics(
      button: true,
      toggled: widget.liked,
      label: widget.liked ? '찜 취소' : '찜하기',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _disabled ? null : _handle,
        child: Opacity(
          opacity: _disabled ? 0.4 : 1,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: widget.liked ? AppColors.coral50 : AppColors.gray0,
              shape: BoxShape.circle,
              boxShadow: widget.liked ? null : AppShadows.elev1,
            ),
            alignment: Alignment.center,
            child: _heart(
              size * 0.46,
              widget.liked ? AppColors.coral500 : AppColors.gray600,
              filled: widget.liked,
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill() {
    final fg = widget.liked ? AppColors.coral700 : AppColors.textOnPrimary;

    return Semantics(
      button: true,
      toggled: widget.liked,
      label: widget.liked ? '찜 취소' : '찜하기',
      child: GestureDetector(
        onTap: _disabled ? null : _handle,
        child: Opacity(
          opacity: _disabled ? 0.4 : 1,
          child: AnimatedContainer(
            duration: AppMotion.base,
            curve: AppMotion.standard,
            height: AppDimens.buttonLg,
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.space5),
            decoration: BoxDecoration(
              color: widget.liked ? AppColors.coral50 : AppColors.coral500,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(
                color: widget.liked
                    ? AppColors.coral300
                    : const Color(0x00000000),
                width: AppDimens.borderWidthStrong,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _heart(
                  20,
                  widget.liked ? AppColors.coral500 : AppColors.textOnPrimary,
                  filled: widget.liked,
                ),
                const SizedBox(width: AppDimens.space2),
                Text(
                  widget.liked ? '찜함' : '찜하기',
                  style: AppTypography.bodyL.copyWith(
                    height: 1,
                    fontWeight: AppTypography.semibold,
                    color: fg,
                  ),
                ),
                if (widget.count != null) ...[
                  const SizedBox(width: AppDimens.space2),
                  Text(
                    '${widget.count}',
                    style: AppTypography.bodyL.copyWith(
                      height: 1,
                      fontWeight: AppTypography.medium,
                      color: fg.withValues(alpha: 0.7),
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
