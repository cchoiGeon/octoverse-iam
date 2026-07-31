import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';
import 'package:iam/data/data_manager.dart';

import 'me_cards_controller.dart';
import 'widgets/card_viewer_sheet.dart';

/// 명함첩.
///
/// 라우트   : AppRoutes.meCards
/// 웹 대응  : `IAM_web/src/app/(app)/me/cards/page.tsx`
/// 디자인   : Figma `명함 교환` 보드 (436:1945 · 436:2072 · 436:2109)
class MeCardsView extends GetView<MeCardsController> {
  const MeCardsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: SafeArea(
        child: Column(
          children: [
            IamAppHeader(title: '명함첩', onBack: Get.back),
            Expanded(child: Obx(() => _body(context))),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (controller.isLoading.value) {
      return const Padding(
        padding: EdgeInsets.all(AppDimens.gutterMobile),
        child: Column(
          children: [
            IamSkeleton.block(height: 180, radius: AppDimens.radiusLg),
            SizedBox(height: AppDimens.space4),
            IamSkeleton.block(height: 44),
          ],
        ),
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
          _myCardSection(context),
          const SizedBox(height: AppDimens.space5),
          IamSegmentedControl(
            segments: MeCardsController.tabs,
            value: controller.tab.value,
            onChanged: (i) => controller.tab.value = i,
          ),
          const SizedBox(height: AppDimens.space4),
          if (controller.current.isEmpty)
            _empty()
          else
            for (final e in controller.current) ...[
              _exchangeRow(context, e),
              const SizedBox(height: AppDimens.space3),
            ],
        ],
      ),
    );
  }

  /// 내 명함이 없으면 교환 자체가 불가능하다 — 맨 위에서 등록을 유도한다.
  Widget _myCardSection(BuildContext context) {
    final card = controller.myCard.value;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  '내 명함',
                  style: AppTypography.title3.copyWith(height: 1.3),
                ),
              ),
              IamButton(
                label: card == null ? '등록하기' : '수정',
                variant: card == null
                    ? IamButtonVariant.primary
                    : IamButtonVariant.ghost,
                size: IamButtonSize.sm,
                onPressed: controller.openEdit,
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space3),
          if (card == null)
            const IamInfoBanner(message: '아직 등록한 명함이 없어요. 명함을 등록해야 교환할 수 있어요.')
          else ...[
            // 탭하면 크게 보고 저장·공유할 수 있다.
            GestureDetector(
              onTap: () => CardViewerSheet.show(
                context,
                title: '내 명함',
                frontUrl: card.frontImageUrl,
                backUrl: card.backImageUrl,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                child: AspectRatio(
                  aspectRatio: 9 / 5,
                  child: CachedNetworkImage(
                    imageUrl: card.frontImageUrl,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) =>
                        const ColoredBox(color: AppColors.surfaceSunken),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimens.space2),
            Align(
              alignment: Alignment.center,
              child: Text(
                '탭하여 미리보기 · 공유',
                style: AppTypography.caption.copyWith(
                  height: 1.3,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _empty() => IamEmptyState(
    icon: IamIconName.idCard,
    title: switch (controller.tab.value) {
      0 => '아직 교환한 명함이 없어요',
      1 => '받은 요청이 없어요',
      _ => '보낸 요청이 없어요',
    },
    description: controller.tab.value == 0 ? '모임에서 만난 사람과 명함을 주고받아 보세요.' : null,
  );

  Widget _exchangeRow(BuildContext context, CardExchangeListItem e) {
    final busy = controller.busyId.value == e.id;
    final name = e.user.nickname ?? '익명';

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
                src: e.user.photoUrl,
                name: name,
                preset: IamAvatarSize.md,
              ),
              const SizedBox(width: AppDimens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        height: 1.3,
                        fontWeight: AppTypography.semibold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.status.label,
                      style: AppTypography.bodyS.copyWith(
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 교환이 성사됐을 때만 명함이 내려온다(서버가 그전엔 null을 준다).
          if (e.card != null) ...[
            const SizedBox(height: AppDimens.space3),
            GestureDetector(
              onTap: () => _viewCard(context, name, e.card!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                child: AspectRatio(
                  aspectRatio: 9 / 5,
                  child: CachedNetworkImage(
                    imageUrl: e.card!.frontImageUrl,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) =>
                        const ColoredBox(color: AppColors.surfaceSunken),
                  ),
                ),
              ),
            ),
          ],
          if (controller.tab.value == 1) ...[
            const SizedBox(height: AppDimens.space3),
            Row(
              children: [
                Expanded(
                  child: IamButton(
                    label: '수락',
                    size: IamButtonSize.sm,
                    block: true,
                    loading: busy,
                    onPressed: () => controller.accept(e),
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
                    onPressed: () => controller.reject(e),
                  ),
                ),
              ],
            ),
          ] else if (controller.tab.value == 2) ...[
            const SizedBox(height: AppDimens.space3),
            IamButton(
              label: '요청 취소',
              variant: IamButtonVariant.ghost,
              size: IamButtonSize.sm,
              block: true,
              enabled: !busy,
              onPressed: () => controller.cancel(e),
            ),
          ],
        ],
      ),
    );
  }

  /// 교환한 명함 뷰어 — 앞/뒤를 크게 보고 저장·공유한다.
  Future<void> _viewCard(
    BuildContext context,
    String name,
    ExchangeCard card,
  ) {
    return CardViewerSheet.show(
      context,
      title: '$name님의 명함',
      frontUrl: card.frontImageUrl,
      backUrl: card.backImageUrl,
    );
  }
}
