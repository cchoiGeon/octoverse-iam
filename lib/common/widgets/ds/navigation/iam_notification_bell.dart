import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/widgets/ds/badges/iam_count_badge.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';

/// IamNotificationBell — IAM DS · navigation
///
/// 알림 종 + 미읽음 카운트. 헤더 우측에 쓴다.
/// `IAM_web/src/components/ds/navigation/NotificationBell.tsx` 이식.
class IamNotificationBell extends StatelessWidget {
  const IamNotificationBell({super.key, this.count = 0, this.onTap});

  /// 0이면 배지를 그리지 않는다.
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final has = count > 0;

    return Semantics(
      button: true,
      label: has ? '알림, 안 읽음 $count개' : '알림',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // 44px — 모바일 최소 터치 타깃.
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const IamIcon(
                IamIconName.bell,
                size: 24,
                color: AppColors.textPrimary,
              ),
              if (has)
                Positioned(
                  top: 6,
                  right: 6,
                  child: IamCountBadge(count: count),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
