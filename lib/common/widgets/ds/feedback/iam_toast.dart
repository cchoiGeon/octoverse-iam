import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';

/// 토스트 톤.
enum IamToastTone { neutral, success, error, info }

/// IamToast — IAM DS · feedback
///
/// 토스트 본체(표현 전용). 띄우는 것은 `ToastService`가 한다 —
/// 화면은 `Get.find<ToastService>().success(...)` 를 부른다.
///
/// `IAM_web/src/components/ds/feedback/Toast.tsx` 이식.
class IamToast extends StatelessWidget {
  const IamToast({
    super.key,
    required this.message,
    this.tone = IamToastTone.neutral,
  });

  final String message;
  final IamToastTone tone;

  @override
  Widget build(BuildContext context) {
    final bg = switch (tone) {
      IamToastTone.success => AppColors.success700,
      IamToastTone.error => AppColors.error600,
      IamToastTone.info => AppColors.info600,
      IamToastTone.neutral => AppColors.gray800,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space4,
        vertical: AppDimens.space3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        boxShadow: AppShadows.elev3,
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTypography.body.copyWith(
          height: 1.4,
          fontWeight: AppTypography.semibold,
          color: AppColors.gray0,
        ),
      ),
    );
  }
}
