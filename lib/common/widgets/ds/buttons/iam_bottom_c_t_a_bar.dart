import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';

/// IamBottomCTABar — IAM DS · buttons
///
/// 화면 하단 고정 CTA. 엄지 도달 영역 + safe-area 대응.
/// `IAM_web/src/components/ds/buttons/BottomCTABar.tsx` 이식.
///
/// 화면당 Primary는 하나라는 원칙에 따라 보통 버튼 1개만 넣는다.
class IamBottomCTABar extends StatelessWidget {
  const IamBottomCTABar({super.key, required this.children, this.info});

  final List<Widget> children;

  /// 버튼 위 보조 정보(안내 문구 등).
  final Widget? info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppDimens.gutterMobile,
        right: AppDimens.gutterMobile,
        top: AppDimens.space3,
        bottom: AppDimens.space3 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: const Border(top: BorderSide(color: AppColors.borderSubtle)),
        boxShadow: AppShadows.bottomCta,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (info != null) ...[
            info!,
            const SizedBox(height: AppDimens.space2),
          ],
          Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: AppDimens.space2),
                children[i],
              ],
            ],
          ),
        ],
      ),
    );
  }
}
