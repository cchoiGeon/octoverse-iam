import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/defines.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/utils/datetime_utils.dart';
import 'package:iam/common/widgets/ds/ds.dart';

import 'event_checkin_controller.dart';
import 'widgets/code_input.dart';

/// S2~S4 참가자 체크인.
///
/// 라우트   : AppRoutes.eventCheckin
/// 웹 대응  : `IAM_web/src/app/(app)/event/[slug]/checkin/page.tsx`
/// 디자인   : Figma `현장 체크인` 보드 (476:1416 · 477:1443 · 478:1455)
class EventCheckinView extends GetView<EventCheckinController> {
  const EventCheckinView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            IamAppHeader(
              title: '체크인',
              onBack: Get.back,
              variant: IamHeaderVariant.center,
            ),
            Expanded(child: Obx(_body)),
          ],
        ),
      ),
      bottomNavigationBar: Obx(_bottom),
    );
  }

  Widget _body() {
    if (controller.isLoading.value) {
      return const Padding(
        padding: EdgeInsets.all(AppDimens.gutterMobile),
        child: Column(
          children: [
            IamSkeleton(width: 240, height: 26),
            SizedBox(height: AppDimens.space4),
            IamSkeleton.block(height: 39),
            SizedBox(height: AppDimens.space4),
            IamSkeleton.block(height: 62),
          ],
        ),
      );
    }
    if (controller.result.value != null) return _success();
    if (controller.terminal.value != null) return _terminal();
    return _codeEntry();
  }

  // ── S2 코드 입력 ────────────────────────────────────────────
  Widget _codeEntry() {
    final error = controller.inlineError.value;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutterMobile,
        AppDimens.space4,
        AppDimens.gutterMobile,
        AppDimens.space10,
      ),
      children: [
        // 어느 모임에 체크인하는지가 가장 먼저 읽혀야 한다.
        Text(
          controller.channel.value?.title ?? '',
          style: AppTypography.title2.copyWith(height: 1.35),
        ),
        const SizedBox(height: AppDimens.space4),
        const IamInfoBanner(message: '주최자 화면의 6자리 코드를 입력하세요'),
        const SizedBox(height: AppDimens.space4),
        CheckinCodeInput(
          controller: controller.code,
          focusNode: controller.codeFocus,
          enabled: !controller.isSubmitting.value,
          invalid: error != null,
        ),
        const SizedBox(height: AppDimens.space4),
        Text(
          error ?? '숫자 6자리를 모두 입력하면 자동으로 확인해요',
          style: AppTypography.bodyS.copyWith(
            height: 1.4,
            fontWeight: error != null ? AppTypography.medium : null,
            color: error != null ? AppColors.error700 : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  // ── S3 성공 ─────────────────────────────────────────────────
  Widget _success() {
    final r = controller.result.value!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutterMobile,
        AppDimens.space6,
        AppDimens.gutterMobile,
        AppDimens.space10,
      ),
      children: [
        IamEmptyState(
          tone: IamEmptyStateTone.success,
          icon: IamIconName.checkCircle,
          title: r.already ? '이미 참석 확인됐어요' : '참석 확인됐어요',
          description:
              '${controller.channel.value?.title ?? ''} · ${DateTimeUtils.time(r.checkedInAt)}',
        ),
        if (controller.likedAttending.value > 0)
          Container(
            padding: const EdgeInsets.all(AppDimens.space4),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '찜한 ${controller.likedAttending}명이 참석해 있어요',
                  style: AppTypography.body.copyWith(
                    height: 1.4,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const SizedBox(height: AppDimens.space1),
                Text(
                  '누가 왔는지는 참가자 목록에서 확인해요',
                  style: AppTypography.bodyS.copyWith(
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── S4 실패(끝난 상태) ──────────────────────────────────────
  Widget _terminal() {
    final start = controller.channel.value?.startAt;
    final opensAt = start == null
        ? null
        : DateTimeUtils.time(
            DateTime.parse(
              start,
            ).subtract(kCheckinLead).toUtc().toIso8601String(),
          );

    return switch (controller.terminal.value!) {
      CheckinTerminal.notOpen => IamEmptyState(
        icon: IamIconName.calendar,
        title: opensAt == null ? '아직 체크인 시간이 아니에요' : '체크인은 $opensAt부터 열려요',
        description: '모임 시작 1시간 전부터 체크인할 수 있어요.',
        action: _backButton(),
      ),
      CheckinTerminal.closed => IamEmptyState(
        icon: IamIconName.alertCircle,
        title: '체크인이 마감됐어요',
        description: '모임이 종료돼 더 이상 체크인할 수 없어요.',
        action: _backButton(),
      ),
      CheckinTerminal.ownChannel => IamEmptyState(
        icon: IamIconName.checkCircle,
        title: '주최자는 자동으로 참석 처리돼요',
        description: '주최자 체크인 화면에서 코드를 게시할 수 있어요.',
        action: IamButton(
          label: '체크인 화면 열기',
          variant: IamButtonVariant.secondary,
          size: IamButtonSize.sm,
          onPressed: controller.goHostCheckin,
        ),
      ),
      CheckinTerminal.notParticipating => IamEmptyState(
        icon: IamIconName.users,
        title: '먼저 참가 신청이 필요해요',
        description: '참가가 확정되면 코드로 체크인할 수 있어요.',
        action: IamButton(
          label: '참가 신청하기',
          size: IamButtonSize.sm,
          onPressed: controller.joinThenRetry,
        ),
      ),
    };
  }

  Widget _backButton() => IamButton(
    label: '모임 보기',
    variant: IamButtonVariant.secondary,
    size: IamButtonSize.sm,
    onPressed: controller.goEvent,
  );

  Widget _bottom() {
    if (controller.isLoading.value || controller.terminal.value != null) {
      return const SizedBox.shrink();
    }
    if (controller.result.value != null) {
      return IamBottomCTABar(
        children: [
          Expanded(
            child: IamButton(
              label: '참석한 사람 보기',
              block: true,
              onPressed: controller.goPeople,
            ),
          ),
        ],
      );
    }
    return IamBottomCTABar(
      children: [
        Expanded(
          child: IamButton(
            label: '확인',
            block: true,
            loading: controller.isSubmitting.value,
            enabled: controller.code.text.length == kCheckinCodeLength,
            onPressed: controller.submit,
          ),
        ),
      ],
    );
  }
}
