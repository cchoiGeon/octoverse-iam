import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/utils/datetime_utils.dart';
import 'package:iam/common/widgets/ds/ds.dart';
import 'package:iam/data/data_manager.dart';

import 'event_detail_controller.dart';

/// 05 모임 상세.
///
/// 라우트   : AppRoutes.eventDetail
/// 웹 대응  : `IAM_web/src/app/(app)/event/[slug]/page.tsx`
/// 디자인   : Figma `3.UI` node 99:78
class EventDetailView extends GetView<EventDetailController> {
  const EventDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceCard,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          if (controller.isLoading.value) return _loading();
          if (controller.channel.value == null) return _error();
          return _content(context);
        }),
      ),
      bottomNavigationBar: Obx(
        () => controller.isLoading.value || controller.channel.value == null
            ? const SizedBox.shrink()
            : IamBottomCTABar(children: _ctaButtons()),
      ),
      floatingActionButton: Obx(
        () => controller.showCheckinFab
            ? IamFab(
                tone: IamFabTone.accent,
                semanticLabel: controller.isOrganizer ? '체크인 코드 보기' : '체크인하기',
                label: controller.isOrganizer ? '체크인 코드' : '체크인',
                icon: controller.isOrganizer
                    ? IamIconName.keypad
                    : IamIconName.checkCircle,
                onPressed: controller.openCheckin,
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  // ── 상태 화면 ───────────────────────────────────────────────
  Widget _loading() {
    return Column(
      children: [
        IamAppHeader(title: '', onBack: Get.back),
        const AspectRatio(
          aspectRatio: 16 / 9,
          child: IamSkeleton.block(radius: 0),
        ),
        const Padding(
          padding: EdgeInsets.all(AppDimens.gutterMobile),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IamSkeleton(width: 72, height: 26, radius: AppDimens.radiusPill),
              SizedBox(height: AppDimens.space4),
              IamSkeleton(width: 240, height: 28),
              SizedBox(height: AppDimens.space4),
              IamSkeleton(height: 16),
              SizedBox(height: AppDimens.space3),
              IamSkeleton(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _error() {
    final notFound = controller.notFound.value;
    return Column(
      children: [
        IamAppHeader(
          title: '모임 상세',
          onBack: Get.back,
          variant: IamHeaderVariant.center,
        ),
        Expanded(
          child: Center(
            child: IamEmptyState(
              icon: notFound ? IamIconName.search : IamIconName.alertCircle,
              title: notFound ? '모임을 찾을 수 없어요' : '불러오기 실패',
              description: notFound
                  ? '삭제됐거나 잘못된 링크예요.'
                  : '네트워크 문제가 생겼어요. 다시 시도해 주세요.',
              action: notFound
                  ? null
                  : IamButton(
                      label: '다시 시도',
                      variant: IamButtonVariant.secondary,
                      size: IamButtonSize.sm,
                      onPressed: controller.load,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ── 본문 ────────────────────────────────────────────────────
  Widget _content(BuildContext context) {
    final c = controller.channel.value!;

    return Column(
      children: [
        IamAppHeader(
          title: '',
          onBack: Get.back,
          variant: IamHeaderVariant.center,
          border: false,
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              IamEventDetailHeader(
                title: c.title,
                cover: c.coverImageUrl,
                date: DateTimeUtils.eventRange(c.startAt, c.endAt),
                place: c.location,
                joined: c.acceptedCount,
                capacity: c.capacity,
                phase: controller.phase,
                host: c.organizer.nickname,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimens.gutterMobile,
                  AppDimens.space5,
                  AppDimens.gutterMobile,
                  AppDimens.space10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (controller.showCheckinHint) ...[
                      const IamInfoBanner(
                        message: '이미 현장에 계신가요? 참가 신청 후 체크인해주세요.',
                      ),
                      const SizedBox(height: AppDimens.space6),
                    ],
                    _section('카테고리', [
                      IamTag(
                        controller.categoryLabel(c.category),
                        tone: IamTagTone.primary,
                      ),
                    ]),
                    _section('주최자', [
                      Row(
                        children: [
                          // K2: verified 미전달
                          IamAvatar(
                            src: c.organizer.photoUrl,
                            name: c.organizer.nickname,
                            preset: IamAvatarSize.sm,
                          ),
                          const SizedBox(width: AppDimens.space3),
                          Text(
                            c.organizer.nickname,
                            style: AppTypography.body.copyWith(
                              height: 1.4,
                              fontWeight: AppTypography.medium,
                            ),
                          ),
                        ],
                      ),
                    ]),
                    if (c.interests.isNotEmpty)
                      _section('관련 관심사', [
                        Wrap(
                          spacing: AppDimens.space2,
                          runSpacing: AppDimens.space2,
                          children: [
                            for (final t in c.interests) IamTag(t.label),
                          ],
                        ),
                      ]),
                    if (c.description.isNotEmpty)
                      _section('모임 소개', [
                        Text(
                          c.description,
                          style: AppTypography.body.copyWith(
                            height: 1.7,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 섹션 라벨(대문자 캡션) + 내용.
  Widget _section(String label, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              height: 1.3,
              fontWeight: AppTypography.semibold,
              letterSpacing: 0.26,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppDimens.space2),
          ...children,
        ],
      ),
    );
  }

  // ── 하단 CTA ────────────────────────────────────────────────
  List<Widget> _ctaButtons() {
    final busy = controller.isMutating.value;

    return switch (controller.cta) {
      ChannelCta.join => [
        Expanded(
          child: IamButton(
            label: '참가 신청',
            block: true,
            loading: busy,
            onPressed: controller.join,
          ),
        ),
      ],
      ChannelCta.joined => [
        Expanded(
          child: IamButton(
            label: '참가자 보기',
            block: true,
            onPressed: controller.openPeople,
          ),
        ),
        if (!controller.hideLeave)
          IamButton(
            label: '참가 취소',
            variant: IamButtonVariant.ghost,
            loading: busy,
            onPressed: () => _confirmLeave(Get.context!),
          ),
      ],
      ChannelCta.pending => [
        const Expanded(
          child: IamButton(label: '승인 대기 중', block: true, enabled: false),
        ),
      ],
      ChannelCta.full => [
        const Expanded(
          child: IamButton(label: '정원 마감', block: true, enabled: false),
        ),
      ],
      ChannelCta.closed => [
        const Expanded(
          child: IamButton(label: '지난 모임이에요', block: true, enabled: false),
        ),
      ],
      ChannelCta.organizer => [
        Expanded(
          child: IamButton(
            label: '참가자 관리',
            block: true,
            onPressed: controller.openManage,
          ),
        ),
        IamButton(
          label: '수정',
          variant: IamButtonVariant.secondary,
          onPressed: controller.openEdit,
        ),
      ],
      ChannelCta.guest => [
        Expanded(
          child: IamButton(
            label: '카카오로 시작',
            block: true,
            onPressed: controller.goLanding,
          ),
        ),
      ],
    };
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final ok = await IamDialog.show(
      context,
      title: '참가를 취소할까요?',
      description: '취소하면 자리가 사라져요. 다시 신청하면 재참가할 수 있어요.',
      confirmText: '취소하기',
      cancelText: '유지하기',
      tone: IamDialogTone.danger,
    );
    if (ok) await controller.leave();
  }
}
