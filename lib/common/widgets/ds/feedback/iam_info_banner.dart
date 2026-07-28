import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';

enum IamBannerVariant { info, success, warning, error }

/// IamInfoBanner — IAM DS · feedback
///
/// 인라인 안내 배너. 아이콘 + 문구.
/// `IAM_web/src/components/ds/feedback/InfoBanner.tsx` 이식 (Figma 194:16).
class IamInfoBanner extends StatelessWidget {
  const IamInfoBanner({
    super.key,
    required this.message,
    this.variant = IamBannerVariant.info,
    this.onClose,
  });

  final String message;
  final IamBannerVariant variant;

  /// 주면 우측에 닫기 버튼이 생긴다.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (variant) {
      IamBannerVariant.info => (
        AppColors.info50,
        AppColors.info700,
        IamIconName.info,
      ),
      IamBannerVariant.success => (
        AppColors.success50,
        AppColors.success700,
        IamIconName.checkCircle,
      ),
      IamBannerVariant.warning => (
        AppColors.warning50,
        AppColors.warning700,
        IamIconName.alertCircle,
      ),
      IamBannerVariant.error => (
        AppColors.error50,
        AppColors.error700,
        IamIconName.alertCircle,
      ),
    };

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: IamIcon(icon, size: 18, color: fg),
            ),
            const SizedBox(width: AppDimens.space2),
            Expanded(
              child: Text(
                message,
                style: AppTypography.caption.copyWith(height: 1.46, color: fg),
              ),
            ),
            if (onClose != null) ...[
              const SizedBox(width: AppDimens.space2),
              Semantics(
                button: true,
                label: '닫기',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onClose,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Center(
                      child: IamIcon(IamIconName.close, size: 16, color: fg),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
