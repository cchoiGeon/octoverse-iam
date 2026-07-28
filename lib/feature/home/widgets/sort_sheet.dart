import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';

import '../home_controller.dart';

/// 홈 정렬 옵션. 기본(최신순)을 맨 위에 둔다.
const _options = [
  IamSortOption(
    HomeController.sortCreatedAt,
    '최신순',
    description: '최근 등록된 모임 먼저',
  ),
  IamSortOption(
    HomeController.sortStartAt,
    '마감 임박순',
    description: '곧 시작하는 모임 먼저',
  ),
  IamSortOption(
    HomeController.sortPopular,
    '인기순',
    description: '참가자가 많은 모임 먼저',
  ),
  IamSortOption(HomeController.sortName, '가나다순', description: '모임 이름 가나다순'),
];

String sortLabel(String value) =>
    _options.firstWhereOrNull((o) => o.value == value)?.label ?? '정렬';

/// 정렬 시트 — 단일 선택, 고르면 즉시 적용하고 닫힌다.
Future<void> showHomeSortSheet(
  BuildContext context,
  HomeController controller,
) async {
  final picked = await IamBottomSheet.show<String>(
    context,
    title: '정렬',
    titleExtra: '정렬 기준을 선택하세요',
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final o in _options) ...[
          _SortRow(
            option: o,
            selected: o.value == controller.sort.value,
            onTap: () => Navigator.of(ctx).pop(o.value),
          ),
          const SizedBox(height: AppDimens.space2),
        ],
        // 서버가 못 하는 정렬은 그 사실을 숨기지 않는다.
        if (HomeController.clientSorts.contains(controller.sort.value))
          Padding(
            padding: const EdgeInsets.only(top: AppDimens.space2),
            child: Text(
              '※ 서버 정렬 지원 전까지는 불러온 목록 안에서 정렬됩니다.',
              style: AppTypography.bodyS.copyWith(
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    ),
  );
  if (picked != null) controller.setSort(picked);
}

class _SortRow extends StatelessWidget {
  const _SortRow({
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
      button: true,
      selected: selected,
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
