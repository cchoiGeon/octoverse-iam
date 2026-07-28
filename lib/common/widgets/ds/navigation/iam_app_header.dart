import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';

/// default 좌측 제목 · center 가운데 제목
enum IamHeaderVariant { start, center }

/// IamAppHeader — IAM DS · navigation
///
/// 상단 헤더. 뒤로 · 제목 · 우측 액션.
/// `IAM_web/src/components/ds/navigation/AppHeader.tsx` 이식.
class IamAppHeader extends StatelessWidget implements PreferredSizeWidget {
  const IamAppHeader({
    super.key,
    required this.title,
    this.onBack,
    this.right,
    this.variant = IamHeaderVariant.start,
    this.border = true,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? right;
  final IamHeaderVariant variant;
  final bool border;

  @override
  Size get preferredSize => const Size.fromHeight(AppDimens.headerHeight);

  @override
  Widget build(BuildContext context) {
    final center = variant == IamHeaderVariant.center;

    return Container(
      height: AppDimens.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.space2),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: border
            ? const Border(bottom: BorderSide(color: AppColors.borderSubtle))
            : null,
      ),
      child: Row(
        children: [
          if (onBack != null)
            Semantics(
              button: true,
              label: '뒤로',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBack,
                child: const SizedBox(
                  width: AppDimens.touchMin,
                  height: AppDimens.touchMin,
                  child: Center(
                    child: IamIcon(
                      IamIconName.arrowLeft,
                      size: 24,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            )
          else
            SizedBox(width: center ? AppDimens.touchMin : AppDimens.space2),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: center ? 0 : AppDimens.space2),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: center ? TextAlign.center : TextAlign.left,
                style: AppTypography.title2.copyWith(height: 1.2),
              ),
            ),
          ),
          // 가운데 정렬일 때는 뒤로 버튼과 같은 폭을 확보해야 제목이 진짜 가운데에 온다.
          if (right != null)
            right!
          else
            SizedBox(width: center && onBack != null ? AppDimens.touchMin : 0),
        ],
      ),
    );
  }
}
