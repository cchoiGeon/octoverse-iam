import 'package:flutter/material.dart'
    show InputBorder, InputDecoration, TextField;
import 'package:flutter/services.dart' show TextInputAction, TextInputFormatter;
import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/utils/keyboard_utils.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';

/// IamInput — IAM DS · forms
///
/// 단일행 입력. 라벨 · 도움말 · 에러 · 좌측 아이콘 · 우측 suffix.
/// `IAM_web/src/components/ds/forms/Input.tsx` 이식.
class IamInput extends StatefulWidget {
  const IamInput({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.error,
    this.placeholder,
    this.iconLeft,
    this.suffix,
    this.required = false,
    this.enabled = true,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String? label;

  /// 에러가 없을 때 아래에 표시되는 도움말.
  final String? hint;

  /// 있으면 테두리·문구가 빨강으로 바뀐다.
  final String? error;

  final String? placeholder;
  final IamIconName? iconLeft;

  /// 우측 보조 텍스트("원", "@" 등).
  final String? suffix;

  final bool required;
  final bool enabled;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  @override
  State<IamInput> createState() => _IamInputState();
}

class _IamInputState extends State<IamInput> {
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
          _Label(text: widget.label!, required: widget.required),
          const SizedBox(height: AppDimens.space2),
        ],
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space4),
          decoration: BoxDecoration(
            color: widget.enabled
                ? AppColors.surfaceCard
                : AppColors.surfaceSunken,
            border: Border.all(
              color: borderColor,
              width: AppDimens.borderWidthStrong,
            ),
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            // 포커스 링 — 웹의 --ring-focus 대응.
            boxShadow: focused && !hasError ? AppShadows.ringFocus : null,
          ),
          child: Row(
            children: [
              if (widget.iconLeft != null) ...[
                IamIcon(
                  widget.iconLeft!,
                  size: 20,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: AppDimens.space2),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  maxLength: widget.maxLength,
                  keyboardType: widget.keyboardType,
                  inputFormatters: widget.inputFormatters,
                  obscureText: widget.obscureText,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  onTapOutside: dismissKeyboardOnTapOutside,
                  textInputAction: widget.textInputAction,
                  textAlignVertical: TextAlignVertical.center,
                  style: AppTypography.bodyL.copyWith(height: 1.4),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    // 기본 카운터는 숨긴다 — 글자수는 hint로 직접 넣는다.
                    counterText: '',
                    hintText: widget.placeholder,
                    hintStyle: AppTypography.bodyL.copyWith(
                      height: 1.4,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
              if (widget.suffix != null) ...[
                const SizedBox(width: AppDimens.space2),
                Text(
                  widget.suffix!,
                  style: AppTypography.bodyS.copyWith(
                    height: 1,
                    fontWeight: AppTypography.medium,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (hasError || (widget.hint != null && widget.hint!.isNotEmpty)) ...[
          const SizedBox(height: AppDimens.space2),
          _Helper(error: hasError ? widget.error : null, hint: widget.hint),
        ],
      ],
    );
  }
}

/// 라벨 + 필수 표시. Input·Textarea·TagSelect·ImageUpload 공용.
class _Label extends StatelessWidget {
  const _Label({required this.text, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text,
        children: required
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
    );
  }
}

/// 도움말/에러 한 줄. 에러면 아이콘 + 빨강.
class _Helper extends StatelessWidget {
  const _Helper({this.error, this.hint});

  final String? error;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final isError = error != null;
    final text = isError ? error! : (hint ?? '');
    if (text.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isError) ...[
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: IamIcon(
              IamIconName.alertCircle,
              size: 14,
              color: AppColors.error700,
            ),
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            text,
            style: AppTypography.caption.copyWith(
              height: 1.4,
              color: isError ? AppColors.error700 : AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}
