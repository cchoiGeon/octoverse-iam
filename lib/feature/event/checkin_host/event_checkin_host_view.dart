import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/utils/datetime_utils.dart';
import 'package:iam/common/widgets/ds/ds.dart';

import 'event_checkin_host_controller.dart';

/// S1 주최자 체크인 — 코드 게시.
///
/// 라우트   : AppRoutes.eventCheckinHost
/// 웹 대응  : `IAM_web/src/app/(app)/event/[slug]/checkin/host/page.tsx`
/// 디자인   : Figma `현장 체크인` 보드 (474:1383)
class EventCheckinHostView extends GetView<EventCheckinHostController> {
  const EventCheckinHostView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: SafeArea(
        child: Column(
          children: [
            IamAppHeader(
              title: '현장 체크인',
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
      return const Padding(
        padding: EdgeInsets.all(AppDimens.gutterMobile),
        child: Column(
          children: [
            IamSkeleton.block(height: 108, radius: AppDimens.radiusLg),
            SizedBox(height: AppDimens.space4),
            IamSkeleton.block(height: 214, radius: AppDimens.radiusLg),
          ],
        ),
      );
    }

    if (controller.channel.value != null && !controller.isOrganizer) {
      return IamEmptyState(
        icon: IamIconName.alertCircle,
        title: '주최자만 볼 수 있어요',
        description: '체크인 코드는 모임을 만든 사람에게만 표시돼요.',
        action: IamButton(
          label: '모임으로 돌아가기',
          variant: IamButtonVariant.secondary,
          size: IamButtonSize.sm,
          onPressed: controller.goEvent,
        ),
      );
    }

    if (controller.channel.value == null) {
      return IamEmptyState(
        icon: IamIconName.alertCircle,
        title: '모임을 불러올 수 없어요',
        description: controller.error.value,
        action: IamButton(
          label: '다시 시도',
          variant: IamButtonVariant.secondary,
          size: IamButtonSize.sm,
          onPressed: controller.load,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.gutterMobile,
        AppDimens.space4,
        AppDimens.gutterMobile,
        AppDimens.space10,
      ),
      children: [
        _summary(),
        const SizedBox(height: AppDimens.space4),
        if (controller.info.value == null)
          IamEmptyState(
            icon: IamIconName.alertCircle,
            title: '체크인 정보를 불러올 수 없어요',
            description: '서버에 체크인 기능이 아직 준비되지 않았을 수 있어요.',
            action: IamButton(
              label: '다시 시도',
              variant: IamButtonVariant.secondary,
              size: IamButtonSize.sm,
              onPressed: controller.load,
            ),
          )
        else if (controller.isOpen)
          _codeCard()
        else if (controller.isBefore)
          IamEmptyState(
            icon: IamIconName.calendar,
            title:
                '체크인은 ${DateTimeUtils.time(controller.info.value!.window.opensAt)}부터 열려요',
            description:
                '${DateTimeUtils.until(controller.untilOpen)} 시작돼요. 시작 1시간 전부터 코드가 표시돼요.',
          )
        else
          const IamEmptyState(
            icon: IamIconName.alertCircle,
            title: '체크인이 마감됐어요',
            description: '모임이 종료돼 더 이상 체크인할 수 없어요.',
          ),
        const SizedBox(height: AppDimens.space4),
        IamButton(
          label: '참석 현황 보기',
          variant: IamButtonVariant.secondary,
          block: true,
          onPressed: controller.goPeople,
        ),
        if (controller.isOpen) ...[
          const SizedBox(height: AppDimens.space4),
          const IamInfoBanner(message: '이 화면을 열어두는 동안 화면이 꺼지지 않아요'),
        ],
      ],
    );
  }

  /// 어느 모임의 코드인지가 카운터보다 먼저 읽혀야 한다.
  Widget _summary() {
    final c = controller.channel.value!;
    final info = controller.info.value;

    return Container(
      padding: const EdgeInsets.all(AppDimens.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(c.title, style: AppTypography.title3.copyWith(height: 1.35)),
          const SizedBox(height: AppDimens.space2),
          Text(
            '${c.location} · ${DateTimeUtils.eventDate(c.startAt)}',
            style: AppTypography.bodyS.copyWith(
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppDimens.space3),
            child: Divider(height: 1, color: AppColors.borderSubtle),
          ),
          Row(
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
              // "N명 중 M명" 어법. 슬래시 분수(12 / 18)는 "12월 18일"로 읽혀 금지.
              Text(
                info == null ? '—' : '${info.total}명 중 ${info.checkedIn}명',
                style: AppTypography.body.copyWith(
                  height: 1,
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _codeCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimens.space5,
        horizontal: AppDimens.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.accent),
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Column(
        children: [
          const IamTag('체크인 코드', tone: IamTagTone.accent),
          const SizedBox(height: AppDimens.space3),
          Text(
            controller.groupedCode,
            style: AppTypography.display.copyWith(
              height: 1.1,
              letterSpacing: 1.12,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppDimens.space3),
          Text(
            '이 코드를 참가자에게 알려주세요',
            textAlign: TextAlign.center,
            style: AppTypography.bodyS.copyWith(
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
