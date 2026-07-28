import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';

/// 선택지 하나.
class IamTagOption {
  const IamTagOption(this.value, this.label);

  final String value;
  final String label;
}

/// IamTagSelect — IAM DS · forms
///
/// 다중 선택 칩. 색과 체크 아이콘 **둘 다**로 선택 상태를 알린다(색만으로는
/// 색각 이상 사용자가 구분하기 어렵다).
///
/// `IAM_web/src/components/ds/forms/TagSelect.tsx` 이식.
class IamTagSelect extends StatelessWidget {
  const IamTagSelect({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
    this.max,
    this.hint,
  });

  final List<IamTagOption> options;
  final List<String> value;
  final ValueChanged<List<String>> onChanged;
  final String? label;

  /// 최대 선택 수. 도달하면 미선택 칩이 비활성된다.
  final int? max;

  final String? hint;

  void _toggle(String v) {
    if (value.contains(v)) {
      onChanged(value.where((x) => x != v).toList());
    } else if (max == null || value.length < max!) {
      onChanged([...value, v]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  label!,
                  style: AppTypography.bodyS.copyWith(
                    height: 1.3,
                    fontWeight: AppTypography.semibold,
                  ),
                ),
              ),
              if (max != null)
                Text(
                  '${value.length}/$max',
                  style: AppTypography.caption.copyWith(
                    height: 1,
                    fontWeight: AppTypography.medium,
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimens.space2),
        ],
        Wrap(
          spacing: AppDimens.space2,
          runSpacing: AppDimens.space2,
          children: [
            for (final o in options)
              _Chip(
                option: o,
                selected: value.contains(o.value),
                // 한도에 걸린 미선택 칩은 눌러도 소용없으니 명확히 비활성한다.
                blocked:
                    !value.contains(o.value) &&
                    max != null &&
                    value.length >= max!,
                onTap: () => _toggle(o.value),
              ),
          ],
        ),
        if (hint != null && hint!.isNotEmpty) ...[
          const SizedBox(height: AppDimens.space2),
          Text(
            hint!,
            style: AppTypography.caption.copyWith(
              height: 1.4,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.option,
    required this.selected,
    required this.blocked,
    required this.onTap,
  });

  final IamTagOption option;
  final bool selected;
  final bool blocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onPrimary : AppColors.textSecondary;

    return Semantics(
      checked: selected,
      enabled: !blocked,
      label: option.label,
      child: GestureDetector(
        onTap: blocked ? null : onTap,
        child: Opacity(
          opacity: blocked ? 0.4 : 1,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppDimens.radiusPill),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.borderStrong,
                width: AppDimens.borderWidthStrong,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 리딩 슬롯을 16px로 고정 — ＋↔✓ 가 바뀌어도 칩 너비가 흔들리지 않는다.
                SizedBox(
                  width: 16,
                  child: Center(
                    child: IamIcon(
                      selected ? IamIconName.check : IamIconName.plus,
                      size: 16,
                      strokeWidth: 2.6,
                      color: selected ? fg : fg.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  option.label,
                  style: AppTypography.body.copyWith(
                    height: 1,
                    fontWeight: AppTypography.semibold,
                    color: fg,
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
