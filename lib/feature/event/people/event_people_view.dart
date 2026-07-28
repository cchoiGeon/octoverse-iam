import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';
import 'package:iam/data/data_manager.dart';

import 'event_people_controller.dart';
import 'widgets/organizer_card.dart';

/// 07 참가자 리스트.
///
/// 라우트   : AppRoutes.eventPeople
/// 웹 대응  : `IAM_web/src/app/(app)/event/[slug]/people/page.tsx`
/// 디자인   : Figma `3.UI` node 104:159
class EventPeopleView extends GetView<EventPeopleController> {
  const EventPeopleView({super.key});

  static const _sortOptions = [
    IamSortOption('checked_in', '참석한 사람 먼저'),
    IamSortOption('join_at', '가입순'),
    IamSortOption('nickname', '가나다순'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: SafeArea(
        child: Column(
          children: [
            IamAppHeader(
              title: '참가자',
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
    if (controller.accessDenied.value) {
      return const IamEmptyState(
        icon: IamIconName.users,
        title: '아직 볼 수 없어요',
        description: '참가가 확정되면 다른 참가자를 볼 수 있어요.',
      );
    }
    if (controller.isLoading.value) return _skeleton();
    if (controller.error.value != null) {
      return IamEmptyState(
        icon: IamIconName.alertCircle,
        title: '참가자를 불러올 수 없어요',
        description: controller.error.value,
        action: IamButton(
          label: '다시 시도',
          variant: IamButtonVariant.secondary,
          size: IamButtonSize.sm,
          onPressed: controller.load,
        ),
      );
    }
    return _list();
  }

  Widget _skeleton() => ListView.separated(
    padding: const EdgeInsets.all(AppDimens.gutterMobile),
    itemCount: 4,
    separatorBuilder: (_, __) => const SizedBox(height: AppDimens.space3),
    itemBuilder: (_, __) => const IamProfileCardSkeleton(),
  );

  Widget _list() {
    final rows = controller.visible;
    final organizer = controller.organizer;
    // 주최자 카드는 검색·필터를 타지 않고 항상 상단에 고정한다.
    final showOrganizer = organizer != null && !controller.hasFilter;

    // 참석 정렬은 참석자가 생긴 뒤에만 선택지에 넣는다.
    final options = controller.hasAttendance
        ? _sortOptions
        : _sortOptions.where((o) => o.value != 'checked_in').toList();

    return RefreshIndicator(
      onRefresh: controller.load,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppDimens.gutterMobile,
          AppDimens.space4,
          AppDimens.gutterMobile,
          AppDimens.space10,
        ),
        children: [
          IamSearchBar(
            controller: controller.searchController,
            placeholder: '닉네임으로 검색',
            onChanged: controller.onSearchChanged,
            onClear: controller.onSearchCleared,
          ),
          const SizedBox(height: AppDimens.space4),
          if (controller.isOrganizer && controller.attendedCount > 0) ...[
            _attendanceSummary(),
            const SizedBox(height: AppDimens.space4),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  '${rows.length}명',
                  style: AppTypography.bodyS.copyWith(
                    height: 1,
                    fontWeight: AppTypography.medium,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              IamSortSelect(
                value: controller.effectiveSort,
                options: options,
                onChanged: controller.onSortChanged,
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space3),
          if (showOrganizer) ...[
            OrganizerHeroCard(
              organizer: organizer,
              liked: controller.likedIds.contains(organizer.id),
              onLike: controller.canLike(organizer.id)
                  ? (next) => controller.toggleLike(organizer.id, next)
                  : null,
              onTap: () => controller.openProfile(organizer.id),
            ),
            const SizedBox(height: AppDimens.space3),
          ],
          if (rows.isEmpty)
            _empty(showOrganizer)
          else
            for (final r in rows) ...[
              _card(r),
              const SizedBox(height: AppDimens.space3),
            ],
        ],
      ),
    );
  }

  Widget _card(ParticipationRow r) {
    final u = r.user;
    return IamProfileCard(
      name: u.nickname ?? '익명',
      photo: u.photoUrl,
      headline: u.oneLiner,
      tags: [for (final t in u.interests ?? const []) t.label],
      // 참석한 사람에게만 배지 — 미참석은 아무 표시도 하지 않는다(낙인 방지).
      badge: r.attended
          ? const IamStatusBadge(
              '참석',
              tone: IamStatusTone.open,
              size: IamStatusBadgeSize.sm,
              dot: false,
            )
          : null,
      liked: controller.likedIds.contains(u.id),
      onLike: controller.canLike(u.id)
          ? (next) => controller.toggleLike(u.id, next)
          : null,
      onTap: () => controller.openProfile(u.id),
    );
  }

  Widget _empty(bool hasOrganizer) {
    if (controller.hasFilter) {
      return IamEmptyState(
        icon: IamIconName.search,
        title: '검색 결과가 없어요',
        description: '다른 검색어를 시도해 보세요.',
        action: IamButton(
          label: '검색 초기화',
          variant: IamButtonVariant.secondary,
          size: IamButtonSize.sm,
          onPressed: controller.onSearchCleared,
        ),
      );
    }
    if (hasOrganizer) return const SizedBox.shrink();
    return const IamEmptyState(
      icon: IamIconName.users,
      title: '아직 참가자가 없어요',
      description: '참가 확정된 분들이 여기에 표시돼요.',
    );
  }

  /// 참석 현황은 주최자에게만. "N명 중 M명" 어법을 쓴다
  /// (슬래시 분수는 날짜로 읽혀 금지).
  Widget _attendanceSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimens.space3,
        horizontal: AppDimens.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '참석 현황',
              style: AppTypography.bodyS.copyWith(
                height: 1,
                fontWeight: AppTypography.medium,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          Text(
            '${controller.acceptedTotal}명 중 ${controller.attendedCount}명',
            style: AppTypography.body.copyWith(
              height: 1,
              fontWeight: AppTypography.bold,
            ),
          ),
        ],
      ),
    );
  }
}
