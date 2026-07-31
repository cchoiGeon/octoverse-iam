// Material에서 필요한 것만 가져온다 — DS에 Material 테마가 새어들지 않게.
import 'package:flutter/material.dart'
    show InputBorder, InputDecoration, TextField;
import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/utils/keyboard_utils.dart';
import 'package:iam/common/widgets/ds/badges/iam_count_badge.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';

/// filled — sunken 필(48px). 참가자 검색 등 단독으로 놓일 때.
/// outlined — 흰 카드 + 테두리(36px). 홈에서 필터·정렬 칩과 한 줄에 놓일 때.
enum IamSearchBarVariant { filled, outlined }

/// IamSearchBar — IAM DS · forms
///
/// `IAM_web/src/components/ds/forms/SearchBar.tsx` 이식.
/// outlined는 칩과 높이(36)를 맞춘다 — 홈 Figma 272:871.
class IamSearchBar extends StatelessWidget {
  const IamSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.onClear,
    this.placeholder = '이름·관심사로 검색',
    this.variant = IamSearchBarVariant.filled,
    this.onFilter,
    this.filterCount = 0,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String placeholder;
  final IamSearchBarVariant variant;

  /// 우측 필터 버튼. null이면 버튼을 그리지 않는다.
  final VoidCallback? onFilter;

  /// 적용된 필터 수. 0보다 크면 버튼이 활성 색을 띠고 배지가 붙는다.
  final int filterCount;

  @override
  Widget build(BuildContext context) {
    final field = _field();
    if (onFilter == null) return field;

    return Row(
      children: [
        Expanded(child: field),
        const SizedBox(width: AppDimens.space2),
        _filterButton(),
      ],
    );
  }

  /// 우측 필터 버튼 — 적용 중이면 인디고로 채우고 개수 배지를 얹는다.
  Widget _filterButton() {
    final active = filterCount > 0;

    return Semantics(
      button: true,
      label: active ? '필터 $filterCount개 적용됨' : '필터',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onFilter,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: active ? AppColors.iris50 : AppColors.surfaceSunken,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? AppColors.iris300 : const Color(0x00000000),
              width: 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IamIcon(
                IamIconName.sliders,
                size: 20,
                color: active ? AppColors.iris600 : AppColors.textSecondary,
              ),
              if (active)
                Positioned(
                  top: 4,
                  right: 4,
                  child: IamCountBadge(count: filterCount),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field() {
    final outlined = variant == IamSearchBarVariant.outlined;

    return Container(
      height: outlined ? 36 : 48,
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space4),
      decoration: BoxDecoration(
        color: outlined ? AppColors.surfaceCard : AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(
          outlined ? AppDimens.radiusMd : AppDimens.radiusPill,
        ),
        border: Border.all(
          color: outlined ? AppColors.borderDefault : const Color(0x00000000),
          width: outlined ? 1 : 1.5,
        ),
      ),
      child: Row(
        children: [
          const IamIcon(
            IamIconName.search,
            size: 20,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: AppDimens.space2),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onTapOutside: dismissKeyboardOnTapOutside,
              textAlignVertical: TextAlignVertical.center,
              style: AppTypography.body.copyWith(
                height: 1.4,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: placeholder,
                hintStyle: AppTypography.body.copyWith(
                  height: 1.4,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
          // 입력이 있을 때만 지우기 버튼. 44px 히트 영역 안에 20px 원.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return Semantics(
                button: true,
                label: '지우기',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    controller.clear();
                    onClear?.call();
                  },
                  child: SizedBox(
                    width: 32,
                    height: outlined ? 36 : 44,
                    child: Center(
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.gray300,
                          shape: BoxShape.circle,
                        ),
                        child: const IamIcon(
                          IamIconName.close,
                          size: 13,
                          strokeWidth: 2.6,
                          color: AppColors.gray0,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
