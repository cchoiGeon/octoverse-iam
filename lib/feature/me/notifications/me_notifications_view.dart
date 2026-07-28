import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/utils/datetime_utils.dart';
import 'package:iam/common/widgets/ds/ds.dart';

import 'me_notifications_controller.dart';

/// 13 알림 센터.
///
/// 라우트   : AppRoutes.meNotifications
/// 웹 대응  : `IAM_web/src/app/(app)/me/notifications/page.tsx`
/// 디자인   : Figma `3.UI` node 162:434
class MeNotificationsView extends GetView<MeNotificationsController> {
  const MeNotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCard,
      body: SafeArea(
        child: Column(
          children: [
            IamAppHeader(
              title: '알림',
              onBack: Get.back,
              right: Obx(
                () => controller.unreadCount == 0
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(right: AppDimens.space2),
                        child: GestureDetector(
                          onTap: controller.markAllRead,
                          child: Text(
                            '모두 읽음',
                            style: AppTypography.bodyS.copyWith(
                              fontWeight: AppTypography.semibold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(child: Obx(_body)),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (controller.isLoading.value && controller.items.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.space2),
        itemCount: 5,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimens.gutterMobile,
            vertical: AppDimens.space3,
          ),
          child: IamSkeleton.block(height: 56),
        ),
      );
    }

    if (controller.items.isEmpty) {
      return const IamEmptyState(
        icon: IamIconName.bell,
        title: '새 알림이 없어요',
        description: '모임 소식이 생기면 여기에 표시돼요.',
      );
    }

    return RefreshIndicator(
      onRefresh: controller.load,
      color: AppColors.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: controller.items.length,
        itemBuilder: (_, i) {
          final n = controller.items[i];
          return IamNotificationItem(
            kind: IamNotificationItem.kindOf(n.type),
            title: n.type.label,
            body: n.channel?.title,
            time: DateTimeUtils.relative(n.createdAt),
            read: n.isRead,
            onTap: () => controller.open(n),
          );
        },
      ),
    );
  }
}
