import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';
import 'package:iam/common/widgets/ds/feedback/iam_bottom_sheet.dart';

class IamSortOption {
  const IamSortOption(this.value, this.label, {this.description});

  final String value;
  final String label;

  /// 있으면 시트에서 라벨 아래 설명으로 보인다.
  final String? description;
}

/// IamSortSelect — IAM DS · forms
///
/// 정렬 선택. 필 모양 트리거를 누르면 바텀시트가 열린다.
/// `IAM_web/src/components/ds/forms/SortSelect.tsx` 이식.
///
/// 웹은 네이티브 `<select>`였지만 모바일에서는 시트가 훨씬 누르기 쉽고
/// 옵션 설명까지 보여줄 수 있다.
class IamSortSelect extends StatelessWidget {
  const IamSortSelect({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.sheetTitle = '정렬',
  });

  final String value;
  final List<IamSortOption> options;
  final ValueChanged<String> onChanged;
  final String sheetTitle;

  IamSortOption get _current =>
      options.firstWhere((o) => o.value == value, orElse: () => options.first);

  Future<void> _open(BuildContext context) async {
    final picked = await IamBottomSheet.show<String>(
      context,
      title: sheetTitle,
      titleExtra: '정렬 기준을 선택하세요',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final o in options) ...[
            _Option(
              option: o,
              selected: o.value == value,
              onTap: () => Navigator.of(ctx).pop(o.value),
            ),
            if (o != options.last) const SizedBox(height: AppDimens.space2),
          ],
        ],
      ),
    );
    if (picked != null && picked != value) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '정렬: ${_current.label}',
      child: GestureDetector(
        onTap: () => _open(context),
        child: Container(
          height: 40,
          padding: const EdgeInsets.only(
            left: AppDimens.space3,
            right: AppDimens.space3,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppDimens.radiusPill),
            border: Border.all(
              color: AppColors.borderStrong,
              width: AppDimens.borderWidthStrong,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _current.label,
                style: AppTypography.bodyS.copyWith(
                  height: 1,
                  fontWeight: AppTypography.semibold,
                ),
              ),
              const SizedBox(width: AppDimens.space2),
              const IamIcon(
                IamIconName.chevronDown,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final IamSortOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: AppDimens.space3,
            horizontal: AppDimens.space4,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.iris50 : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.borderStrong,
              width: AppDimens.borderWidthStrong,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: AppTypography.body.copyWith(
                        height: 1.3,
                        fontWeight: AppTypography.semibold,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (option.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        option.description!,
                        style: AppTypography.bodyS.copyWith(
                          height: 1.3,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                const IamIcon(
                  IamIconName.check,
                  size: 18,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
