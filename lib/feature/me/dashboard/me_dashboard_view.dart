import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';
import 'package:iam/feature/shared/app_tab_bar.dart';

import 'me_dashboard_controller.dart';

/// 09 마이 대시보드.
///
/// 라우트   : AppRoutes.me
/// 웹 대응  : `IAM_web/src/app/(app)/me/page.tsx`
/// 디자인   : Figma `3.UI` node 121:416
class MeDashboardView extends GetView<MeDashboardController> {
  const MeDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCard,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            Expanded(child: Obx(_body)),
          ],
        ),
      ),
      bottomNavigationBar: const AppTabBar(active: 'me'),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutterMobile,
        AppDimens.space3,
        AppDimens.gutterMobile,
        AppDimens.space2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '마이',
              style: AppTypography.title1.copyWith(height: 1.3),
            ),
          ),
          Obx(
            () => IamNotificationBell(
              count: controller.unreadCount,
              onTap: controller.openNotifications,
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (controller.isLoading.value) return _skeleton();

    return RefreshIndicator(
      onRefresh: controller.load,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppDimens.space10),
        children: [
          _profileSummary(),
          _activityRow(),
          IamListItem(
            icon: IamIconName.heart,
            title: '찜',
            value: '${controller.likesCount}개',
            onTap: controller.openLikes,
          ),
          IamListItem(
            icon: IamIconName.idCard,
            title: '명함첩',
            value: controller.cardRequestCount.value > 0
                ? '받은 ${controller.cardRequestCount}'
                : null,
            onTap: controller.openCards,
          ),
          IamListItem(
            icon: IamIconName.bell,
            title: '알림',
            onTap: controller.openNotifications,
          ),
          IamListItem(
            icon: IamIconName.settings,
            title: '설정',
            onTap: controller.openSettings,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimens.gutterMobile,
              AppDimens.space6,
              AppDimens.gutterMobile,
              AppDimens.space4,
            ),
            child: IamButton(
              label: '모임 만들기',
              size: IamButtonSize.lg,
              block: true,
              onPressed: controller.openCreateEvent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileSummary() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutterMobile,
        AppDimens.space6,
        AppDimens.gutterMobile,
        AppDimens.space5,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Column(
        children: [
          // K2: verified 미전달
          IamAvatar(
            src: controller.photoUrl,
            name: controller.nickname,
            preset: IamAvatarSize.xl,
          ),
          const SizedBox(height: AppDimens.space3),
          Text(
            controller.nickname,
            textAlign: TextAlign.center,
            style: AppTypography.title3.copyWith(
              height: 1.3,
              fontWeight: AppTypography.bold,
            ),
          ),
          if (controller.profile?.oneLiner != null) ...[
            const SizedBox(height: AppDimens.space1),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Text(
                controller.profile!.oneLiner!,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppDimens.space3),
          IamButton(
            label: '프로필 편집',
            variant: IamButtonVariant.ghost,
            size: IamButtonSize.sm,
            onPressed: controller.openProfile,
          ),
        ],
      ),
    );
  }

  /// 주최·참여·대기 카운트 3분할.
  Widget _activityRow() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimens.space4,
        horizontal: AppDimens.gutterMobile,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          _stat('주최한 모임', controller.organizedCount.value, 'organized'),
          const SizedBox(width: AppDimens.space2),
          _stat('참여한 모임', controller.joinedCount.value, 'joined'),
          const SizedBox(width: AppDimens.space2),
          _stat('신청 대기', controller.pendingCount.value, 'pending'),
        ],
      ),
    );
  }

  Widget _stat(String label, int count, String tab) {
    return Expanded(
      child: Semantics(
        button: true,
        label: '$label $count개',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => controller.openMeetings(tab),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimens.space3,
              horizontal: AppDimens.space2,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            ),
            child: Column(
              children: [
                Text(
                  '$count',
                  style: AppTypography.bodyL.copyWith(
                    height: 1.2,
                    fontWeight: AppTypography.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppDimens.space1),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    height: 1.3,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _skeleton() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: AppDimens.gutterMobile),
    child: Column(
      children: [
        SizedBox(height: AppDimens.space6),
        IamSkeleton.circle(width: 88),
        SizedBox(height: AppDimens.space3),
        IamSkeleton(width: 120, height: 22),
        SizedBox(height: AppDimens.space2),
        IamSkeleton(width: 200, height: 16),
        SizedBox(height: AppDimens.space6),
        IamSkeleton.block(height: 64),
        SizedBox(height: AppDimens.space4),
        IamSkeleton.block(height: 56),
      ],
    ),
  );
}
