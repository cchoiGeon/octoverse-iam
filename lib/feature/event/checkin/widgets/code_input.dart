import 'package:flutter/material.dart'
    show InputBorder, InputDecoration, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/defines.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/utils/keyboard_utils.dart';

/// 6자리 코드 입력.
///
/// 보이는 건 6개의 칸이지만 실제 입력은 **투명한 TextField 하나**가 받는다.
/// 그래야 붙여넣기·SMS 자동완성·키보드 동작이 그대로 살아난다.
/// (칸마다 TextField를 두면 이 셋이 전부 깨진다.)
class CheckinCodeInput extends StatelessWidget {
  const CheckinCodeInput({
    super.key,
    required this.controller,
    required this.focusNode,
    this.enabled = true,
    this.invalid = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool invalid;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => focusNode.requestFocus(),
      child: Stack(
        children: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) => _boxes(value.text),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: kCheckinCodeLength,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onTapOutside: dismissKeyboardOnTapOutside,
                // iOS는 16px 미만이면 포커스 시 화면이 확대된다.
                style: const TextStyle(fontSize: 16),
                showCursor: false,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _boxes(String text) {
    final focusIndex = text.length >= kCheckinCodeLength
        ? kCheckinCodeLength - 1
        : text.length;

    return Row(
      children: [
        for (var i = 0; i < kCheckinCodeLength; i++) ...[
          if (i > 0) const SizedBox(width: AppDimens.space2),
          Expanded(
            child: Container(
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(
                  color: invalid
                      ? AppColors.error600
                      : (enabled && i == focusIndex
                            ? AppColors.primary
                            : AppColors.borderStrong),
                  width: AppDimens.borderWidthStrong,
                ),
              ),
              child: Text(
                i < text.length ? text[i] : '',
                style: AppTypography.title2.copyWith(
                  height: 1,
                  fontWeight: AppTypography.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
