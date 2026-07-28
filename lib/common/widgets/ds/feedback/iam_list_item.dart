import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';

/// IamListItem — IAM DS · feedback
///
/// 마이·설정의 행. 좌측 아이콘/아바타 · 제목 · 설명 · 우측 값/화살표/스위치.
/// `IAM_web/src/components/ds/feedback/ListItem.tsx` 이식.
class IamListItem extends StatelessWidget {
  const IamListItem({
    super.key,
    required this.title,
    this.icon,
    this.leading,
    this.description,
    this.value,
    this.trailing,
    this.showChevron = true,
    this.danger = false,
    this.onTap,
  });

  final String title;
  final IamIconName? icon;

  /// icon 대신 쓰는 커스텀 좌측 노드(아바타 등).
  final Widget? leading;

  final String? description;

  /// 우측 값 텍스트.
  final String? value;

  /// 우측 커스텀 노드(스위치 등). 주면 화살표 대신 이게 온다.
  final Widget? trailing;

  final bool showChevron;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(
        vertical: AppDimens.space3,
        horizontal: AppDimens.gutterMobile,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          if (leading != null)
            leading!
          else if (icon != null)
            IamIcon(
              icon!,
              size: 22,
              color: danger ? AppColors.error600 : AppColors.textSecondary,
            ),
          if (leading != null || icon != null)
            const SizedBox(width: AppDimens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyL.copyWith(
                    height: 1.4,
                    fontWeight: AppTypography.medium,
                    color: danger ? AppColors.error700 : AppColors.textPrimary,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    description!,
                    style: AppTypography.bodyS.copyWith(
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: AppDimens.space3),
            Text(
              value!,
              style: AppTypography.body.copyWith(
                height: 1.4,
                color: AppColors.textTertiary,
              ),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: AppDimens.space3),
            trailing!,
          ] else if (showChevron && onTap != null) ...[
            const SizedBox(width: AppDimens.space3),
            const IamIcon(
              IamIconName.chevronRight,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return row;

    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: row,
      ),
    );
  }
}
