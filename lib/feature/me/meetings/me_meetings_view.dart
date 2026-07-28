import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/utils/channel_utils.dart';
import 'package:iam/common/utils/datetime_utils.dart';
import 'package:iam/common/widgets/ds/ds.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/feature/event/shared/share_event_sheet.dart';
import 'package:iam/feature/shared/app_tab_bar.dart';

import 'me_meetings_controller.dart';

/// 11 내 모임.
///
/// 라우트   : AppRoutes.meMeetings
/// 웹 대응  : `IAM_web/src/app/(app)/me/meetings/page.tsx`
/// 디자인   : Figma `3.UI` node 125:477
class MeMeetingsView extends GetView<MeMeetingsController> {
  const MeMeetingsView({super.key});

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
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '내 모임',
                      style: AppTypography.title1.copyWith(height: 1.3),
                    ),
                  ),
                ],
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
                  segments: MeMeetingsController.tabs,
                  value: controller.tab.value,
                  onChanged: (i) => controller.tab.value = i,
                ),
              ),
            ),
            Expanded(child: Obx(_body)),
          ],
        ),
      ),
      bottomNavigationBar: const AppTabBar(active: 'meetings'),
      floatingActionButton: IamFab(
        semanticLabel: '모임 만들기',
        onPressed: controller.openCreate,
      ),
    );
  }

  Widget _body() {
    if (controller.isLoading.value) return _skeleton();
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
    return switch (controller.tab.value) {
      0 => _organizedTab(),
      1 => _joinedTab(),
      _ => _pendingTab(),
    };
  }

  Widget _skeleton() => ListView.separated(
    padding: const EdgeInsets.all(AppDimens.gutterMobile),
    itemCount: 2,
    separatorBuilder: (_, __) => const SizedBox(height: AppDimens.space3),
    itemBuilder: (_, __) =>
        const IamSkeleton.block(height: 260, radius: AppDimens.radiusLg),
  );

  Widget _wrap(List<Widget> children) => RefreshIndicator(
    onRefresh: controller.load,
    color: AppColors.primary,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutterMobile,
        AppDimens.space2,
        AppDimens.gutterMobile,
        AppDimens.space12,
      ),
      children: children,
    ),
  );

  // ── 주최 탭 ─────────────────────────────────────────────────
  Widget _organizedTab() {
    if (controller.organized.isEmpty) {
      return IamEmptyState(
        icon: IamIconName.calendar,
        title: '아직 만든 모임이 없어요',
        description: '직접 모임을 열고 사람들을 모아 보세요.',
        action: IamButton(label: '모임 만들기', onPressed: controller.openCreate),
      );
    }

    return _wrap([
      for (final ch in controller.organized) ...[
        Builder(
          builder: (context) {
            final phase = ChannelUtils.phaseOfListItem(ch);
            final live = phase != ChannelPhase.past;
            return IamOrganizerEventCard(
              title: ch.title,
              description: ch.description,
              cover: ch.coverImageUrl,
              date: DateTimeUtils.eventDate(ch.startAt),
              place: ch.location,
              joined: ch.acceptedCount,
              capacity: ch.capacity,
              phase: phase,
              interests: [for (final t in ch.interests) t.label],
              onTap: () => controller.openDetail(ch.slug),
              onManage: () =>
                  controller.openManageOrPeople(ch.slug, live: live),
              onShare: () => ShareEventSheet.show(
                context,
                slug: ch.slug,
                title: ch.title,
                startAt: ch.startAt,
                endAt: ch.endAt,
              ),
              onMore: () => _moreSheet(context, ch, live: live),
            );
          },
        ),
        const SizedBox(height: AppDimens.space3),
      ],
    ]);
  }

  /// 수정·종료는 지난 모임에서 감춘다(삭제만 남긴다).
  Future<void> _moreSheet(
    BuildContext context,
    ChannelListItem ch, {
    required bool live,
  }) async {
    await IamBottomSheet.show<void>(
      context,
      title: ch.title,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (live)
            IamListItem(
              title: '수정',
              onTap: () {
                Navigator.of(ctx).pop();
                controller.openEdit(ch.slug);
              },
            ),
          if (live)
            IamListItem(
              title: '모임 종료',
              description: '지금 바로 지난 모임으로 바꿔요. 되돌릴 수 없어요.',
              showChevron: false,
              onTap: () async {
                Navigator.of(ctx).pop();
                final ok = await IamDialog.show(
                  context,
                  title: '모임을 종료할까요?',
                  description: '"${ch.title}" 모임을 종료하면 되돌릴 수 없어요.',
                  confirmText: '종료',
                  tone: IamDialogTone.danger,
                );
                if (ok) await controller.closeChannel(ch.slug);
              },
            ),
          IamListItem(
            title: '모임 삭제',
            description: '참가자 정보까지 모두 사라져요.',
            danger: true,
            showChevron: false,
            onTap: () async {
              Navigator.of(ctx).pop();
              final ok = await IamDialog.show(
                context,
                title: '모임을 삭제할까요?',
                description: '"${ch.title}" 모임을 삭제하면 참가자 정보도 모두 사라져요.',
                confirmText: '삭제',
                tone: IamDialogTone.danger,
              );
              if (ok) await controller.deleteChannel(ch.slug);
            },
          ),
        ],
      ),
    );
  }

  // ── 참여 탭 ─────────────────────────────────────────────────
  Widget _joinedTab() {
    if (controller.joined.isEmpty) {
      return IamEmptyState(
        icon: IamIconName.users,
        title: '아직 참가한 모임이 없어요',
        description: '탐색에서 마음에 드는 모임을 찾아 신청해 보세요.',
        action: IamButton(label: '모임 탐색', onPressed: () => Get.offNamed('/')),
      );
    }

    return _wrap([
      for (final ch in controller.joined) ...[
        IamEventCard(
          title: ch.title,
          description: ch.description,
          cover: ch.coverImageUrl,
          date: DateTimeUtils.eventRange(ch.startAt, ch.endAt),
          place: ch.location,
          joined: ch.acceptedCount,
          capacity: ch.capacity,
          phase: ChannelUtils.phaseOf(
            status: ch.status,
            startAt: ch.startAt,
            endAt: ch.endAt,
            capacity: ch.capacity,
            acceptedCount: ch.acceptedCount,
          ),
          host: ch.organizer.nickname,
          hostAvatar: ch.organizer.photoUrl,
          interests: [for (final t in ch.interests) t.label],
          onTap: () => controller.openDetail(ch.slug),
        ),
        const SizedBox(height: AppDimens.space3),
      ],
    ]);
  }

  // ── 대기 탭 ─────────────────────────────────────────────────
  Widget _pendingTab() {
    if (controller.pending.isEmpty) {
      return const IamEmptyState(
        icon: IamIconName.info,
        title: '신청 대기 중인 모임이 없어요',
        description: '참가 신청을 하면 여기에서 확인할 수 있어요.',
      );
    }

    return _wrap([
      for (final p in controller.pending) ...[
        _PendingRow(
          item: p,
          onTap: () => controller.openDetail(p.channel.slug),
        ),
        const SizedBox(height: AppDimens.space2),
      ],
    ]);
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.item, required this.onTap});

  final MyParticipation item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${item.channel.title} 상세 보기',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppDimens.space4),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            border: Border.all(color: AppColors.borderSubtle),
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.channel.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        height: 1.4,
                        fontWeight: AppTypography.semibold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateTimeUtils.eventDate(item.channel.startAt),
                      style: AppTypography.bodyS.copyWith(
                        height: 1.43,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimens.space3),
              const IamStatusBadge(
                '대기중',
                tone: IamStatusTone.soon,
                size: IamStatusBadgeSize.sm,
                dot: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
