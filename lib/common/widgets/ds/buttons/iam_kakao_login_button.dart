import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/typography.dart';

/// 카카오가 승인한 라벨만 쓴다. 임의 문구 금지.
enum IamKakaoLabel {
  login('카카오 로그인'),
  start('카카오로 시작하기'),
  continueWith('카카오 계정으로 계속하기');

  const IamKakaoLabel(this.text);
  final String text;
}

/// IamKakaoLoginButton — IAM DS · buttons
///
/// ⚠️ **카카오 공식 가이드 고정값이다.** 배경 #FEE500 · 검정 말풍선 ·
///    radius 12 · 승인 라벨만. **IAM 스타일을 입히지 않는다.**
///    색·모양을 바꾸면 심사에서 반려된다.
///
/// `IAM_web/src/components/ds/buttons/KakaoLoginButton.tsx` 이식.
class IamKakaoLoginButton extends StatefulWidget {
  const IamKakaoLoginButton({
    super.key,
    this.label = IamKakaoLabel.login,
    this.onPressed,
    this.block = true,
    this.enabled = true,
  });

  final IamKakaoLabel label;
  final VoidCallback? onPressed;
  final bool block;
  final bool enabled;

  @override
  State<IamKakaoLoginButton> createState() => _IamKakaoLoginButtonState();
}

class _IamKakaoLoginButtonState extends State<IamKakaoLoginButton> {
  bool _pressed = false;

  /// 카카오 말풍선 심볼. 웹 원본의 path를 그대로 옮겼다.
  static const _symbol =
      '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20" fill="none">'
      '<path fill="#000000" d="M10 2.2C5.58 2.2 2 5.02 2 8.5c0 2.23 1.49 4.19 3.74 5.31-.16.58-.6 2.18-.69 2.52-.11.42.16.41.33.3.14-.09 2.16-1.47 3.03-2.07.52.08 1.05.12 1.59.12 4.42 0 8-2.82 8-6.3S14.42 2.2 10 2.2Z"/>'
      '</svg>';

  @override
  Widget build(BuildContext context) {
    final disabled = !widget.enabled || widget.onPressed == null;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.label.text,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: disabled ? null : () => setState(() => _pressed = false),
        onTap: disabled ? null : widget.onPressed,
        child: Opacity(
          opacity: disabled ? 0.5 : (_pressed ? 0.95 : 1),
          child: Container(
            width: widget.block ? double.infinity : null,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.kakaoYellow,
              // 12px — 카카오 고정값. AppDimens를 쓰지 않는 유일한 자리다.
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 심볼은 좌측 고정, 텍스트는 가운데 — 카카오 가이드 배치.
                Positioned(
                  left: 0,
                  child: SvgPicture.string(_symbol, width: 20, height: 20),
                ),
                Text(
                  widget.label.text,
                  style: AppTypography.body.copyWith(
                    fontSize: 16,
                    height: 1,
                    fontWeight: AppTypography.semibold,
                    color: AppColors.kakaoLabel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
