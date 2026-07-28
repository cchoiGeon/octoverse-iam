import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';

/// 제목 + "＋ 추가" 토글 + 내용. 경력·이력·링크 세 섹션이 공유한다.
class SectionBlock extends StatelessWidget {
  const SectionBlock({
    super.key,
    required this.title,
    required this.open,
    required this.onToggle,
    required this.children,
  });

  final String title;
  final bool open;
  final VoidCallback onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.title3.copyWith(height: 1.3),
              ),
            ),
            IamButton(
              label: open ? '닫기' : '＋ 추가',
              variant: IamButtonVariant.ghost,
              size: IamButtonSize.sm,
              onPressed: onToggle,
            ),
          ],
        ),
        const SizedBox(height: AppDimens.space3),
        ...children,
      ],
    );
  }
}

/// 추가된 항목 한 줄 — 제목·부제 + 삭제.
class EntryCard extends StatelessWidget {
  const EntryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.space2),
      padding: const EdgeInsets.symmetric(
        vertical: AppDimens.space3,
        horizontal: AppDimens.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    height: 1.4,
                    fontWeight: AppTypography.semibold,
                  ),
                ),
                const SizedBox(height: AppDimens.space1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimens.space3),
          Semantics(
            button: true,
            label: '삭제',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDelete,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimens.space1,
                  horizontal: AppDimens.space2,
                ),
                child: Text(
                  '삭제',
                  style: AppTypography.caption.copyWith(
                    height: 1,
                    fontWeight: AppTypography.medium,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 인라인 입력 폼 껍데기 — 카드 배경 + 세로 간격.
class InlineForm extends StatelessWidget {
  const InlineForm({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.space2),
      padding: const EdgeInsets.all(AppDimens.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: AppDimens.space4),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// 인라인 폼 하단 취소/추가 버튼 쌍.
class InlineFormActions extends StatelessWidget {
  const InlineFormActions({
    super.key,
    required this.onCancel,
    required this.onAdd,
    this.canAdd = true,
  });

  final VoidCallback onCancel;
  final VoidCallback onAdd;
  final bool canAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IamButton(
          label: '취소',
          variant: IamButtonVariant.ghost,
          size: IamButtonSize.sm,
          onPressed: onCancel,
        ),
        const SizedBox(width: AppDimens.space2),
        IamButton(
          label: '추가',
          size: IamButtonSize.sm,
          enabled: canAdd,
          onPressed: onAdd,
        ),
      ],
    );
  }
}

/// 단일 선택 칩 그룹 — 직무·이력 종류·링크 유형·어학 수준에 쓴다.
///
/// [selected]를 다시 누르면 해제되도록 [allowDeselect]를 켤 수 있다.
class ChoiceChipRow<T> extends StatelessWidget {
  const ChoiceChipRow({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.allowDeselect = true,
  });

  final String label;
  final List<T> options;
  final T? selected;
  final String Function(T) labelOf;

  /// 해제 시 null 이 넘어온다.
  final ValueChanged<T?> onSelected;

  final bool allowDeselect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyS.copyWith(
            height: 1.4,
            fontWeight: AppTypography.medium,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimens.space2),
        Wrap(
          spacing: AppDimens.space2,
          runSpacing: AppDimens.space2,
          children: [
            for (final o in options)
              IamFilterChip(
                label: labelOf(o),
                selected: selected == o,
                size: IamFilterChipSize.sm,
                onTap: () =>
                    onSelected(selected == o && allowDeselect ? null : o),
              ),
          ],
        ),
      ],
    );
  }
}
