import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/feature/shared/app_tab_bar.dart';

import 'me_likes_controller.dart';

/// 12 찜 관리.
///
/// 라우트   : AppRoutes.meLikes
/// 웹 대응  : `IAM_web/src/app/(app)/me/likes/page.tsx`
/// 디자인   : Figma `3.UI` node 133:632
class MeLikesView extends GetView<MeLikesController> {
  const MeLikesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCard,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.gutterMobile,
                AppDimens.space3,
                AppDimens.gutterMobile,
                AppDimens.space2,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '찜',
                  style: AppTypography.title1.copyWith(height: 1.3),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.space4,
                AppDimens.space2,
                AppDimens.space4,
                AppDimens.space3,
              ),
              child: Obx(
                () => IamSegmentedControl(
                  segments: MeLikesController.tabs,
                  value: controller.tab.value,
                  onChanged: (i) => controller.tab.value = i,
                ),
              ),
            ),
            Expanded(child: Obx(_body)),
          ],
        ),
      ),
      bottomNavigationBar: const AppTabBar(active: 'likes'),
    );
  }

  Widget _body() {
    if (controller.isLoading.value) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppDimens.gutterMobile),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: AppDimens.space3),
        itemBuilder: (_, __) => const IamProfileCardSkeleton(),
      );
    }
    if (controller.error.value != null) {
      return IamEmptyState(
        icon: IamIconName.alertCircle,
        title: '불러오지 못했어요',
        description: controller.error.value,
        action: IamButton(
          label: '다시 시도',
          variant: IamButtonVariant.secondary,
          size: IamButtonSize.sm,
          onPressed: controller.load,
        ),
      );
    }

    final rows = controller.current;
    if (rows.isEmpty) {
      return IamEmptyState(
        icon: IamIconName.heart,
        title: controller.tab.value == 0 ? '아직 찜한 사람이 없어요' : '아직 나를 찜한 사람이 없어요',
        description: controller.tab.value == 0
            ? '모임 참가자 목록에서 마음이 가는 사람을 찜해 보세요.'
            : '프로필을 채우면 다른 참가자에게 더 잘 보여요.',
      );
    }

    return RefreshIndicator(
      onRefresh: controller.load,
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppDimens.gutterMobile,
          AppDimens.space2,
          AppDimens.gutterMobile,
          AppDimens.space10,
        ),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppDimens.space3),
        itemBuilder: (_, i) => _row(rows[i]),
      ),
    );
  }

  /// 찜 카드에는 "어느 모임에서 찜했는지"가 함께 보여야 맥락이 산다.
  Widget _row(MyLikeRow row) {
    return IamProfileCard(
      name: row.user.nickname,
      photo: row.user.photoUrl,
      headline: row.channel.title,
      onTap: () => controller.openProfile(row),
    );
  }
}
