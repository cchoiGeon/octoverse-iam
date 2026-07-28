import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';

import 'event_poster_controller.dart';

/// 홍보포스터 만들기.
///
/// 라우트   : AppRoutes.eventPoster
/// 웹 대응  : `IAM_web/src/components/app/poster/PosterEditor.tsx`
/// ⚠️ Figma 시안 없음 — 웹 구현 기준.
class EventPosterView extends GetView<EventPosterController> {
  const EventPosterView({super.key});

  static const _hueColors = {
    PosterHue.iris: [AppColors.iris500, AppColors.iris800],
    PosterHue.coral: [AppColors.coral400, AppColors.coral700],
    PosterHue.forest: [AppColors.success500, AppColors.success700],
    PosterHue.amber: [AppColors.warning500, AppColors.warning700],
    PosterHue.ink: [AppColors.gray700, AppColors.gray900],
    PosterHue.light: [AppColors.gray100, AppColors.gray300],
  };

  static const _hueLabels = {
    PosterHue.iris: '인디고',
    PosterHue.coral: '코랄',
    PosterHue.forest: '포레스트',
    PosterHue.amber: '앰버',
    PosterHue.ink: '잉크',
    PosterHue.light: '라이트',
  };

  bool get _isLight => controller.hue.value == PosterHue.light;
  Color get _fg => _isLight ? AppColors.gray900 : AppColors.gray0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            IamAppHeader(title: '홍보포스터', onBack: Get.back),
            Expanded(child: Obx(_body)),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => controller.isLoading.value || controller.channel.value == null
            ? const SizedBox.shrink()
            : IamBottomCTABar(
                children: [
                  Expanded(
                    child: IamButton(
                      label: '이미지로 공유',
                      size: IamButtonSize.lg,
                      block: true,
                      loading: controller.isSharing.value,
                      iconLeft: const IamIcon(
                        IamIconName.share,
                        size: 18,
                        color: AppColors.gray0,
                      ),
                      onPressed: controller.shareImage,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _body() {
    if (controller.isLoading.value) {
      return const Padding(
        padding: EdgeInsets.all(AppDimens.gutterMobile),
        child: IamSkeleton.block(height: 380, radius: AppDimens.radiusLg),
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
        // 미리보기와 캡처가 같은 위젯이라 "보이는 대로" 저장된다.
        RepaintBoundary(key: controller.posterKey, child: _poster()),
        const SizedBox(height: AppDimens.space5),
        _huePicker(),
        const SizedBox(height: AppDimens.space5),
        IamListItem(
          title: '모임 소개 넣기',
          description: '길면 포스터가 빽빽해져요',
          showChevron: false,
          trailing: IamToggle(
            checked: controller.showIntro.value,
            onChanged: (v) => controller.showIntro.value = v,
            semanticLabel: '모임 소개 넣기',
          ),
        ),
      ],
    );
  }

  Widget _poster() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(AppDimens.space6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _hueColors[controller.hue.value]!,
          ),
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.categoryLabel,
              style: AppTypography.label.copyWith(
                color: _fg.withValues(alpha: 0.8),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: AppDimens.space3),
            Text(
              controller.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.title1.copyWith(height: 1.25, color: _fg),
            ),
            const SizedBox(height: AppDimens.space4),
            _metaLine(IamIconName.calendar, controller.dateLabel),
            const SizedBox(height: AppDimens.space2),
            _metaLine(IamIconName.mapPin, controller.place),
            if (controller.showIntro.value &&
                controller.intro.trim().isNotEmpty) ...[
              const SizedBox(height: AppDimens.space4),
              Expanded(
                child: Text(
                  controller.intro.trim(),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyS.copyWith(
                    height: 1.6,
                    color: _fg.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ] else
              const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IAM',
                        style: AppTypography.title3.copyWith(
                          fontWeight: AppTypography.bold,
                          color: _fg,
                        ),
                      ),
                      Text(
                        'QR로 바로 참가',
                        style: AppTypography.caption.copyWith(
                          color: _fg.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.gray0,
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  ),
                  child: QrImageView(
                    data: controller.joinUrl,
                    size: 72,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaLine(IamIconName icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: IamIcon(icon, size: 15, color: _fg.withValues(alpha: 0.85)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyS.copyWith(
              height: 1.4,
              color: _fg.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }

  Widget _huePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '배색',
          style: AppTypography.bodyS.copyWith(
            height: 1.3,
            fontWeight: AppTypography.semibold,
          ),
        ),
        const SizedBox(height: AppDimens.space2),
        Wrap(
          spacing: AppDimens.space2,
          runSpacing: AppDimens.space2,
          children: [
            for (final h in PosterHue.values)
              IamFilterChip(
                label: _hueLabels[h]!,
                selected: controller.hue.value == h,
                size: IamFilterChipSize.sm,
                onTap: () => controller.hue.value = h,
              ),
          ],
        ),
      ],
    );
  }
}
