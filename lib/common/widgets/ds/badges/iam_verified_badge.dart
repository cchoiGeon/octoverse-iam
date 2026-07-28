import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';

/// IamVerifiedBadge — IAM DS · badges
///
/// 본인인증 배지.
///
/// ⚠️ **K2 — MVP에서는 어디에도 렌더하지 않는다.**
/// 계약(디자인시스템·API)상 자리를 지키려고 남겨둔 컴포넌트다. 화면에서
/// 이걸 쓰기 전에 반드시 제품 결정을 먼저 확인한다.
///
/// `IAM_web/src/components/ds/badges/VerifiedBadge.tsx` 이식.
class IamVerifiedBadge extends StatelessWidget {
  const IamVerifiedBadge({super.key, this.label = '본인인증', this.soft = false});

  final String label;

  /// soft = 연한 배경 + 진한 글자 / 기본 = 진한 배경 + 흰 글자.
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final bg = soft ? AppColors.verifiedSoftBg : AppColors.verifiedBg;
    final fg = soft ? AppColors.verifiedSoftFg : AppColors.verifiedFg;

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IamIcon(
            IamIconName.shieldCheck,
            size: 13,
            strokeWidth: 2.4,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.label.copyWith(
              height: 1,
              fontWeight: AppTypography.semibold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
