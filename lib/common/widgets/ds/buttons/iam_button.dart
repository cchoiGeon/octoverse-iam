import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';

/// 버튼 변형.
/// ⚠️ 화면당 `primary`는 **하나**다. 나머지는 보조 액션에 쓴다.
enum IamButtonVariant { primary, secondary, accent, ghost, danger }

/// sm 40 · md 48 · lg 56 (px 높이)
enum IamButtonSize { sm, md, lg }

/// IamButton — IAM DS · buttons
///
/// `IAM_web/src/components/ds/buttons/Button.tsx` 이식.
/// 눌림은 축소(0.97) + 배경 어둡게 — 웹의 `.iam-btn:active`와 같은 규칙이다.
class IamButton extends StatefulWidget {
  const IamButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = IamButtonVariant.primary,
    this.size = IamButtonSize.md,
    this.block = false,
    this.loading = false,
    this.enabled = true,
    this.iconLeft,
    this.iconRight,
  });

  final String label;

  /// null이면 비활성으로 본다(웹의 `disabled`와 동일 취급).
  final VoidCallback? onPressed;

  final IamButtonVariant variant;
  final IamButtonSize size;

  /// 가로 100% — 하단 고정 CTA에 쓴다.
  final bool block;

  /// 진행 중. 스피너를 띄우고 입력을 막는다.
  final bool loading;

  /// 명시적 비활성. [onPressed]가 null이어도 비활성이다.
  final bool enabled;

  final Widget? iconLeft;
  final Widget? iconRight;

  bool get _isDisabled => !enabled || loading || onPressed == null;

  @override
  State<IamButton> createState() => _IamButtonState();
}

class _IamButtonState extends State<IamButton> {
  bool _pressed = false;

  ({double height, double padX, TextStyle text}) get _metrics =>
      switch (widget.size) {
        IamButtonSize.sm => (
          height: AppDimens.buttonSm,
          padX: 16.0,
          text: AppTypography.bodyS,
        ),
        IamButtonSize.md => (
          height: AppDimens.buttonMd,
          padX: 20.0,
          text: AppTypography.body,
        ),
        IamButtonSize.lg => (
          height: AppDimens.buttonLg,
          padX: 24.0,
          text: AppTypography.bodyL,
        ),
      };

  /// (기본 배경, 눌림 배경, 전경, 테두리)
  ({Color bg, Color press, Color fg, Color border}) get _palette =>
      switch (widget.variant) {
        IamButtonVariant.primary => (
          bg: AppColors.primary,
          press: AppColors.primaryPress,
          fg: AppColors.onPrimary,
          border: const Color(0x00000000),
        ),
        IamButtonVariant.secondary => (
          bg: AppColors.primarySoft,
          press: AppColors.iris200,
          fg: AppColors.iris700,
          border: const Color(0x00000000),
        ),
        IamButtonVariant.accent => (
          bg: AppColors.accent,
          press: AppColors.accentPress,
          fg: AppColors.textOnPrimary,
          border: const Color(0x00000000),
        ),
        IamButtonVariant.ghost => (
          bg: const Color(0x00000000),
          press: AppColors.gray200,
          fg: AppColors.textSecondary,
          border: AppColors.borderStrong,
        ),
        IamButtonVariant.danger => (
          bg: AppColors.error600,
          press: AppColors.error700,
          fg: AppColors.gray0,
          border: const Color(0x00000000),
        ),
      };

  @override
  Widget build(BuildContext context) {
    final m = _metrics;
    final p = _palette;
    final disabled = widget._isDisabled;

    // 로딩 중에는 흐리게 하지 않는다 — 스피너가 이미 상태를 알린다.
    final opacity = disabled && !widget.loading ? 0.4 : 1.0;
    final spinnerSize = widget.size == IamButtonSize.lg ? 20.0 : 18.0;

    final child = Row(
      mainAxisSize: widget.block ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          _Spinner(size: spinnerSize, color: p.fg)
        else if (widget.iconLeft != null)
          widget.iconLeft!,
        if (widget.loading || widget.iconLeft != null)
          const SizedBox(width: AppDimens.space2),
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            textAlign: TextAlign.center,
            style: m.text.copyWith(
              height: 1,
              fontWeight: AppTypography.semibold,
              letterSpacing: m.text.fontSize! * -0.01,
              color: p.fg.withValues(alpha: widget.loading ? 0.85 : 1),
            ),
          ),
        ),
        if (!widget.loading && widget.iconRight != null) ...[
          const SizedBox(width: AppDimens.space2),
          widget.iconRight!,
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: disabled ? null : () => setState(() => _pressed = false),
        onTap: disabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? AppMotion.pressScale : 1.0,
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          child: Opacity(
            opacity: opacity,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              height: m.height,
              width: widget.block ? double.infinity : null,
              padding: EdgeInsets.symmetric(horizontal: m.padX),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _pressed ? p.press : p.bg,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(
                  color: p.border,
                  width: AppDimens.borderWidthStrong,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// 로딩 스피너 — 위쪽이 뚫린 링이 도는 형태.
/// 웹의 `border-top-color: transparent` + `iam-spin`과 같은 모양이다.
class _Spinner extends StatefulWidget {
  const _Spinner({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _SpinnerPainter(
            turns: _c.value,
            color: widget.color.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter({required this.turns, required this.color});

  final double turns;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 2.5;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final rect =
        const Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);

    // 3/4 원호 — 나머지 1/4이 뚫린 자리(웹의 transparent top).
    canvas.drawArc(rect, turns * 2 * math.pi, 1.5 * math.pi, false, paint);
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) =>
      old.turns != turns || old.color != color;
}
