import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/utils/channel_utils.dart';
import 'package:iam/common/utils/datetime_utils.dart';
import 'package:iam/common/widgets/ds/ds.dart';
import 'package:iam/core/route/app_pages.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/feature/shared/app_tab_bar.dart';

import 'home_controller.dart';
import 'widgets/filter_sheet.dart';
import 'widgets/sort_sheet.dart';

/// 04b 모임 둘러보기.
///
/// 라우트   : AppRoutes.home
/// 웹 대응  : `IAM_web/src/app/(app)/page.tsx`의 `<Explore>`
/// 디자인   : Figma `3.UI` node 272:865 (04b · v4 개편)
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCard,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            _controlRow(),
            Expanded(child: _body()),
          ],
        ),
      ),
      floatingActionButton: IamFab(
        semanticLabel: 'QR로 모임 참가',
        label: 'QR로 참가',
        icon: IamIconName.qrCode,
        onPressed: () => Get.toNamed(AppRoutes.scan),
      ),
      bottomNavigationBar: const AppTabBar(active: 'home'),
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
              '모임 둘러보기',
              style: AppTypography.title1.copyWith(height: 1.3),
            ),
          ),
          Obx(
            () => IamNotificationBell(
              count: controller.unreadCount,
              onTap: () => Get.toNamed(AppRoutes.meNotifications),
            ),
          ),
        ],
      ),
    );
  }

  /// 검색 · 필터 · 정렬 한 줄 (Figma 272:870).
  Widget _controlRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutterMobile,
        0,
        AppDimens.gutterMobile,
        AppDimens.space3,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: IamSearchBar(
              controller: controller.searchController,
              variant: IamSearchBarVariant.outlined,
              placeholder: '모임 이름으로 검색',
              onChanged: controller.onSearchChanged,
              onClear: controller.onSearchCleared,
            ),
          ),
          const SizedBox(width: AppDimens.space2),
          Obx(
            () => IamControlChip(
              label: '필터',
              icon: IamIconName.sliders,
              active: controller.filterCount > 0,
              value: _filterSummary(),
              extraCount: controller.filterCount > 1
                  ? controller.filterCount - 1
                  : null,
              onTap: () => showHomeFilterSheet(Get.context!, controller),
            ),
          ),
          const SizedBox(width: AppDimens.space2),
          Obx(
            () => IamControlChip(
              label: '정렬',
              icon: IamIconName.sort,
              active: controller.sortChanged,
              value: controller.sortChanged
                  ? sortLabel(controller.sort.value)
                  : null,
              onTap: () => showHomeSortSheet(Get.context!, controller),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    return Obx(() {
      if (controller.isLoading.value) return _skeletonList();
      if (controller.error.value != null) return _errorState();
      if (controller.visible.isEmpty) return _emptyState();
      return _list();
    });
  }

  Widget _skeletonList() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimens.gutterMobile),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: AppDimens.space3),
      itemBuilder: (_, __) =>
          const IamSkeleton.block(height: 230, radius: AppDimens.radiusLg),
    );
  }

  Widget _errorState() {
    return IamEmptyState(
      icon: IamIconName.alertCircle,
      title: '모임을 불러오지 못했어요',
      description: controller.error.value,
      action: IamButton(
        label: '다시 시도',
        variant: IamButtonVariant.secondary,
        size: IamButtonSize.sm,
        onPressed: controller.load,
      ),
    );
  }

  Widget _emptyState() {
    final filtered = controller.filterCount > 0;
    return IamEmptyState(
      icon: IamIconName.inbox,
      title: '해당하는 모임이 없어요',
      description: filtered ? '필터나 검색어를 바꿔 다시 시도해 보세요.' : '아직 공개된 모임이 없어요.',
      action: filtered
          ? IamButton(
              label: '필터 초기화',
              variant: IamButtonVariant.secondary,
              size: IamButtonSize.sm,
              onPressed: controller.resetFilters,
            )
          : null,
    );
  }

  /// 적용된 필터 중 첫 라벨. 나머지는 칩의 "+N"이 맡는다.
  String? _filterSummary() {
    final c = controller;
    if (c.category.value != null) {
      return c.reference.categories
          .firstWhereOrNull((o) => o.value.name == c.category.value)
          ?.label;
    }
    if (c.interest.value != null) {
      return c.reference.interests
          .firstWhereOrNull((t) => t.name.name == c.interest.value)
          ?.label;
    }
    return statusLabel(c.statusFilter.value);
  }

  Widget _list() {
    return RefreshIndicator(
      onRefresh: controller.load,
      color: AppColors.primary,
      child: ListView.separated(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppDimens.gutterMobile,
          AppDimens.space4,
          AppDimens.gutterMobile,
          AppDimens.space12,
        ),
        itemCount: controller.visible.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: AppDimens.space3),
        itemBuilder: (_, i) {
          if (i == controller.visible.length) return _footer();
          return _card(controller.visible[i]);
        },
      ),
    );
  }

  Widget _card(ChannelListItem c) {
    return IamEventCard(
      title: c.title,
      description: c.description,
      cover: c.coverImageUrl,
      date: DateTimeUtils.eventRange(c.startAt, c.endAt),
      place: c.location,
      joined: c.acceptedCount,
      capacity: c.capacity,
      // 서버 status가 아니라 시각·정원으로 계산한 phase를 쓴다.
      phase: ChannelUtils.phaseOfListItem(c),
      host: c.organizer.nickname,
      hostAvatar: c.organizer.photoUrl,
      interests: c.interests.map((t) => t.label).toList(),
      onTap: () => Get.toNamed(AppRoutes.eventDetailOf(c.slug)),
    );
  }

  Widget _footer() {
    return Obx(
      () => controller.isLoadingMore.value
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimens.space4),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          : const SizedBox(height: AppDimens.space4),
    );
  }
}
