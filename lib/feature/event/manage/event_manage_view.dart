import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';
import 'package:iam/data/data_manager.dart';

import 'event_manage_controller.dart';

/// 11b 참가자 관리 (주최자).
///
/// 라우트   : AppRoutes.eventManage
/// 웹 대응  : `IAM_web/src/app/(app)/event/[slug]/manage/page.tsx`
/// 디자인   : Figma `3.UI` node 131:585
class EventManageView extends GetView<EventManageController> {
  const EventManageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: SafeArea(
        child: Column(
          children: [
            IamAppHeader(
              title: '참가자 관리',
              onBack: Get.back,
              variant: IamHeaderVariant.center,
            ),
            Expanded(child: Obx(_body)),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (controller.isLoading.value) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppDimens.gutterMobile),
        itemCount: 3,
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
    // 주최자 가드 — 서버도 403을 주지만 화면에서도 명확히 막는다.
    if (!controller.isOrganizer) {
      return const IamEmptyState(
        icon: IamIconName.shieldCheck,
        title: '주최자만 볼 수 있어요',
        description: '참가자 관리는 모임을 만든 사람에게만 열려요.',
      );
    }

    final rows = controller.current;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimens.space4),
          child: IamSegmentedControl(
            segments: [
              '${EventManageController.tabs[0]} ${controller.accepted.length}',
              '${EventManageController.tabs[1]} ${controller.pending.length}',
              '${EventManageController.tabs[2]} ${controller.rejected.length}',
            ],
            value: controller.tab.value,
            onChanged: (i) => controller.tab.value = i,
          ),
        ),
        if (controller.tab.value == 1)
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimens.gutterMobile,
              0,
              AppDimens.gutterMobile,
              AppDimens.space3,
            ),
            child: IamInfoBanner(
              message: 'MVP에서는 신청 시 자동 승인돼요. 목록이 비어 있는 게 정상이에요.',
            ),
          ),
        Expanded(
          child: rows.isEmpty
              ? _empty()
              : RefreshIndicator(
                  onRefresh: controller.load,
                  color: AppColors.primary,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppDimens.gutterMobile,
                      0,
                      AppDimens.gutterMobile,
                      AppDimens.space10,
                    ),
                    itemCount: rows.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDimens.space3),
                    itemBuilder: (_, i) => _row(rows[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _empty() => IamEmptyState(
    icon: IamIconName.users,
    title: switch (controller.tab.value) {
      0 => '아직 승인된 참가자가 없어요',
      1 => '대기 중인 신청이 없어요',
      _ => '거절한 신청이 없어요',
    },
  );

  Widget _row(ParticipationRow r) {
    final u = r.user;
    final busy = controller.busyId.value == r.id;
    // 승인/거절 액션은 대기 탭에서만 의미가 있다.
    final showActions = controller.tab.value == 1;

    return Container(
      padding: const EdgeInsets.all(AppDimens.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IamAvatar(
                src: u.photoUrl,
                name: u.nickname ?? '익명',
                preset: IamAvatarSize.md,
              ),
              const SizedBox(width: AppDimens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.nickname ?? '익명',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        height: 1.3,
                        fontWeight: AppTypography.semibold,
                      ),
                    ),
                    if (u.oneLiner != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        u.oneLiner!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyS.copyWith(
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (r.attended)
                const IamStatusBadge(
                  '참석',
                  tone: IamStatusTone.open,
                  size: IamStatusBadgeSize.sm,
                  dot: false,
                ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: AppDimens.space3),
            Row(
              children: [
                Expanded(
                  child: IamButton(
                    label: '승인',
                    size: IamButtonSize.sm,
                    block: true,
                    loading: busy,
                    onPressed: () => controller.decide(r, true),
                  ),
                ),
                const SizedBox(width: AppDimens.space2),
                Expanded(
                  child: IamButton(
                    label: '거절',
                    variant: IamButtonVariant.ghost,
                    size: IamButtonSize.sm,
                    block: true,
                    enabled: !busy,
                    onPressed: () => controller.decide(r, false),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
