import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/core/iam_icon.dart';
import 'package:iam/data/enums/social_enums.dart';

/// 알림 성격 — 아이콘·색을 정한다.
enum IamNotificationKind { like, event, card, system, verify }

/// IamNotificationItem — IAM DS · navigation
///
/// 알림 한 줄. 안 읽음은 배경을 인디고로 강조하고 우측에 점을 찍는다.
/// `IAM_web/src/components/ds/navigation/NotificationItem.tsx` 이식.
class IamNotificationItem extends StatelessWidget {
  const IamNotificationItem({
    super.key,
    required this.title,
    this.kind = IamNotificationKind.system,
    this.body,
    this.time,
    this.read = false,
    this.onTap,
  });

  final String title;
  final IamNotificationKind kind;
  final String? body;
  final String? time;
  final bool read;
  final VoidCallback? onTap;

  /// 서버 알림 타입 → 표시 성격.
  static IamNotificationKind kindOf(NotificationType type) => switch (type) {
    NotificationType.cardExchangeRequested ||
    NotificationType.cardExchangeAccepted ||
    NotificationType.cardExchangeCancelled => IamNotificationKind.card,
    NotificationType.participationAck ||
    NotificationType.reminder24h ||
    NotificationType.reminder1h ||
    NotificationType.channelUpdated ||
    NotificationType.channelCancelled => IamNotificationKind.event,
    NotificationType.welcome => IamNotificationKind.system,
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (kind) {
      IamNotificationKind.like => (
        AppColors.coral50,
        AppColors.coral500,
        IamIconName.heart,
      ),
      IamNotificationKind.event => (
        AppColors.iris50,
        AppColors.iris600,
        IamIconName.calendar,
      ),
      IamNotificationKind.card => (
        AppColors.iris50,
        AppColors.iris600,
        IamIconName.idCard,
      ),
      IamNotificationKind.verify => (
        AppColors.success50,
        AppColors.success700,
        IamIconName.shieldCheck,
      ),
      IamNotificationKind.system => (
        AppColors.surfaceSunken,
        AppColors.textSecondary,
        IamIconName.info,
      ),
    };

    return Semantics(
      button: onTap != null,
      label: read ? title : '안 읽음, $title',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimens.space4,
            horizontal: AppDimens.gutterMobile,
          ),
          decoration: BoxDecoration(
            // 안 읽음은 배경으로 한눈에 구분된다.
            color: read ? AppColors.surfaceCard : AppColors.iris50,
            border: const Border(
              bottom: BorderSide(color: AppColors.borderSubtle),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: IamIcon(icon, size: 20, color: fg),
              ),
              const SizedBox(width: AppDimens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body.copyWith(
                        height: 1.45,
                        fontWeight: read
                            ? AppTypography.medium
                            : AppTypography.semibold,
                      ),
                    ),
                    if (body != null && body!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        body!,
                        style: AppTypography.bodyS.copyWith(
                          height: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (time != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        time!,
                        style: AppTypography.caption.copyWith(
                          height: 1,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!read) ...[
                const SizedBox(width: AppDimens.space2),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
