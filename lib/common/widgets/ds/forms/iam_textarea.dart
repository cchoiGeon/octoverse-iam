import 'package:flutter/material.dart'
    show InputBorder, InputDecoration, TextField;
import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/utils/keyboard_utils.dart';

/// IamTextarea — IAM DS · forms
///
/// 여러 줄 입력 + 글자수 카운터. 90%를 넘기면 카운터가 경고색으로 바뀐다.
/// `IAM_web/src/components/ds/forms/Textarea.tsx` 이식.
class IamTextarea extends StatefulWidget {
  const IamTextarea({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.error,
    this.placeholder,
    this.maxLength = 150,
    this.rows = 4,
    this.required = false,
    this.enabled = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final String? error;
  final String? placeholder;

  /// null이면 카운터를 그리지 않는다.
  final int? maxLength;

  final int rows;
  final bool required;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  State<IamTextarea> createState() => _IamTextareaState();
}

class _IamTextareaState extends State<IamTextarea> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null && widget.error!.isNotEmpty;
    final focused = _focus.hasFocus;

    final borderColor = hasError
        ? AppColors.error500
        : focused
        ? AppColors.borderFocus
        : AppColors.borderStrong;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text.rich(
            TextSpan(
              text: widget.label,
              children: widget.required
                  ? [
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(color: AppColors.error600),
                      ),
                    ]
                  : null,
            ),
            style: AppTypography.bodyS.copyWith(
              height: 1.3,
              fontWeight: AppTypography.semibold,
            ),
          ),
          const SizedBox(height: AppDimens.space2),
        ],
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimens.space3,
            horizontal: AppDimens.space4,
          ),
          decoration: BoxDecoration(
            color: widget.enabled
                ? AppColors.surfaceCard
                : AppColors.surfaceSunken,
            border: Border.all(
              color: borderColor,
              width: AppDimens.borderWidthStrong,
            ),
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            boxShadow: focused && !hasError ? AppShadows.ringFocus : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            enabled: widget.enabled,
            maxLength: widget.maxLength,
            minLines: widget.rows,
            maxLines: null,
            onChanged: widget.onChanged,
            onTapOutside: dismissKeyboardOnTapOutside,
            keyboardType: TextInputType.multiline,
            style: AppTypography.bodyL.copyWith(height: 1.6),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              // Material 기본 카운터를 끄고 아래에 직접 그린다.
              counterText: '',
              hintText: widget.placeholder,
              hintStyle: AppTypography.bodyL.copyWith(
                height: 1.6,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimens.space2),
        _FooterRow(
          controller: widget.controller,
          maxLength: widget.maxLength,
          error: hasError ? widget.error : null,
          hint: widget.hint,
        ),
      ],
    );
  }
}

/// 도움말/에러 + 글자수. 입력할 때마다 카운터만 다시 그린다.
class _FooterRow extends StatelessWidget {
  const _FooterRow({
    required this.controller,
    this.maxLength,
    this.error,
    this.hint,
  });

  final TextEditingController controller;
  final int? maxLength;
  final String? error;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final isError = error != null;
    final message = isError ? error! : (hint ?? '');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: message.isEmpty
              ? const SizedBox.shrink()
              : Text(
                  message,
                  style: AppTypography.caption.copyWith(
                    height: 1.4,
                    color: isError
                        ? AppColors.error700
                        : AppColors.textTertiary,
                  ),
                ),
        ),
        if (maxLength != null)
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) {
              final len = value.text.length;
              // 90%를 넘기면 경고색 — 한도가 가까워졌음을 미리 알린다.
              final near = len >= maxLength! * 0.9;
              return Padding(
                padding: const EdgeInsets.only(left: AppDimens.space2),
                child: Text(
                  '$len/$maxLength',
                  style: AppTypography.caption.copyWith(
                    height: 1.4,
                    fontWeight: AppTypography.medium,
                    color: near ? AppColors.warning700 : AppColors.textTertiary,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
