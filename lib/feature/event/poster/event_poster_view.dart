import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';

import 'event_poster_controller.dart';
import 'poster_config.dart';
import 'widgets/poster_canvas.dart';

/// 홍보포스터 만들기.
///
/// 라우트   : AppRoutes.eventPoster
/// 웹 대응  : `IAM_web/src/components/app/poster/PosterEditor.tsx`
/// ⚠️ Figma 시안 없음 — 웹 구현 기준.
class EventPosterView extends GetView<EventPosterController> {
  const EventPosterView({super.key});

  static const _tabs = ['색상', '레이아웃', '내용'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePage,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Obx(
              () => IamAppHeader(
                title: '홍보포스터',
                onBack: Get.back,
                right: controller.channel.value == null
                    ? null
                    : _recommendChip(),
              ),
            ),
            Expanded(child: Obx(() => _body(context))),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () =>
            controller.isLoading.value ||
                controller.channel.value == null ||
                !controller.isOrganizer.value
            ? const SizedBox.shrink()
            : IamBottomCTABar(
                children: [
                  IamButton(
                    label: '저장',
                    variant: IamButtonVariant.secondary,
                    size: IamButtonSize.lg,
                    loading: controller.isBusy.value,
                    onPressed: controller.save,
                  ),
                  Expanded(
                    child: IamButton(
                      label: '공유하기',
                      size: IamButtonSize.lg,
                      block: true,
                      loading: controller.isBusy.value,
                      iconLeft: const IamIcon(
                        IamIconName.share,
                        size: 18,
                        color: AppColors.gray0,
                      ),
                      onPressed: controller.share,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// 추천 그대로면 표시만, 바꿨으면 되돌리기 버튼.
  Widget _recommendChip() {
    if (controller.isAtRecommended) {
      return Padding(
        padding: const EdgeInsets.only(right: AppDimens.space2),
        child: Text(
          '✓ 추천',
          style: AppTypography.caption.copyWith(
            height: 1,
            fontWeight: AppTypography.semibold,
            color: AppColors.textTertiary,
          ),
        ),
      );
    }
    return IamButton(
      label: '추천으로',
      variant: IamButtonVariant.ghost,
      size: IamButtonSize.sm,
      onPressed: controller.restoreRecommended,
    );
  }

  Widget _body(BuildContext context) {
    if (controller.isLoading.value) {
      return const Padding(
        padding: EdgeInsets.all(AppDimens.gutterMobile),
        child: IamSkeleton.block(height: 380, radius: AppDimens.radiusLg),
      );
    }
    if (controller.channel.value != null && !controller.isOrganizer.value) {
      return IamEmptyState(
        icon: IamIconName.shieldCheck,
        title: '주최자만 만들 수 있어요',
        description: '홍보포스터는 모임 주최자만 만들 수 있어요.',
        action: IamButton(
          label: '모임으로 가기',
          variant: IamButtonVariant.secondary,
          size: IamButtonSize.sm,
          onPressed: controller.goDetail,
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
        _preview(context),
        const SizedBox(height: AppDimens.space5),
        IamSegmentedControl(
          segments: _tabs,
          value: controller.tab.value,
          onChanged: (i) => controller.tab.value = i,
        ),
        const SizedBox(height: AppDimens.space5),
        switch (controller.tab.value) {
          0 => _colorPanel(),
          1 => _layoutPanel(),
          _ => _contentPanel(),
        },
      ],
    );
  }

  /// 미리보기 — 캡처 대상이자 화면에 보이는 것. 둘이 같은 위젯이라
  /// "보이는 대로" 저장된다.
  Widget _preview(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final side = constraints.maxWidth;
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
              child: RepaintBoundary(
                key: controller.posterKey,
                child: _canvas(side),
              ),
            ),
            Positioned(
              right: AppDimens.space2,
              bottom: AppDimens.space2,
              child: _zoomButton(context, side),
            ),
          ],
        );
      },
    );
  }

  PosterCanvas _canvas(double side) {
    final c = controller;
    return PosterCanvas(
      size: side,
      config: c.config.value,
      title: c.title,
      categoryLabel: c.categoryLabel,
      dateLabel: c.dateLabel,
      location: c.place,
      organizerName: c.organizerName,
      interests: c.interests,
      joinUrl: c.joinUrl,
    );
  }

  Widget _zoomButton(BuildContext context, double side) {
    return Semantics(
      button: true,
      label: '포스터 확대',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openFullscreen(context),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space3,
            vertical: AppDimens.space2,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(AppDimens.radiusPill),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Text(
            '확대',
            style: AppTypography.caption.copyWith(
              height: 1,
              fontWeight: AppTypography.semibold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  /// 전체화면 — 아무 데나 누르면 닫힌다.
  Future<void> _openFullscreen(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final side = (media.width < media.height ? media.width : media.height) * 0.9;

    return showDialog<void>(
      context: context,
      barrierColor: const Color(0xE6000000),
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            // 전체화면은 보기 전용이라 컨트롤러의 캡처 키를 달지 않는다
            // (같은 key를 두 위젯이 쓰면 캡처가 어느 쪽을 잡을지 알 수 없다).
            child: Obx(() => _canvas(side)),
          ),
        ),
      ),
    );
  }

  // ── 색상 ────────────────────────────────────────────────────
  Widget _colorPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _groupLabel('그라데이션'),
        _swatchRow(PosterColorFormat.gradient),
        const SizedBox(height: AppDimens.space4),
        _groupLabel('솔리드 단일색'),
        _swatchRow(PosterColorFormat.solid),
      ],
    );
  }

  Widget _swatchRow(PosterColorFormat format) {
    final config = controller.config.value;
    return Wrap(
      spacing: AppDimens.space3,
      runSpacing: AppDimens.space3,
      children: [
        for (final hue in PosterHue.values)
          _swatch(
            hue: hue,
            format: format,
            selected: config.format == format && config.hue == hue,
          ),
      ],
    );
  }

  Widget _swatch({
    required PosterHue hue,
    required PosterColorFormat format,
    required bool selected,
  }) {
    final colors = format == PosterColorFormat.solid
        ? [hue.solid, hue.solid]
        : hue.gradient;

    return Semantics(
      button: true,
      selected: selected,
      label: hue.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => controller.setColor(format, hue),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors,
                ),
                border: Border.all(
                  // 페이퍼는 흰 배경에 묻히므로 항상 테두리를 준다.
                  color: selected
                      ? AppColors.primary
                      : (hue.isLight
                            ? AppColors.borderStrong
                            : const Color(0x00000000)),
                  width: selected ? 2.5 : 1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hue.label,
              style: AppTypography.caption.copyWith(
                height: 1,
                color: selected
                    ? AppColors.primary
                    : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 레이아웃 ────────────────────────────────────────────────
  Widget _layoutPanel() {
    final config = controller.config.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _groupLabel('레이아웃'),
        Row(
          children: [
            for (final layout in PosterLayout.values) ...[
              Expanded(
                child: _layoutThumb(layout, config.layout == layout),
              ),
              if (layout != PosterLayout.values.last)
                const SizedBox(width: AppDimens.space2),
            ],
          ],
        ),
        const SizedBox(height: AppDimens.space5),
        _groupLabel('제목 크기'),
        Wrap(
          spacing: AppDimens.space2,
          children: [
            for (final scale in PosterTitleScale.values)
              IamFilterChip(
                label: scale.label,
                selected: config.titleScale == scale,
                size: IamFilterChipSize.sm,
                onTap: () => controller.setTitleScale(scale),
              ),
          ],
        ),
      ],
    );
  }

  /// 레이아웃 썸네일 — 실제 캔버스를 아주 작게 그리는 대신, 구도만 막대로 흉내낸다
  /// (작은 크기에서 실물을 그리면 글자가 뭉개져 오히려 구분이 안 된다).
  Widget _layoutThumb(PosterLayout layout, bool selected) {
    final config = controller.config.value;
    final band = layout == PosterLayout.band;

    return Semantics(
      button: true,
      selected: selected,
      label: layout.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => controller.setLayout(layout),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : AppColors.borderSubtle,
                    width: selected ? 2.5 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Band는 위만 색면이고 아래는 페이퍼다.
                    Column(
                      children: [
                        Expanded(
                          flex: band ? 132 : 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: config.background,
                              ),
                            ),
                          ),
                        ),
                        if (band)
                          const Expanded(
                            flex: 100,
                            child: ColoredBox(color: AppColors.gray50),
                          ),
                      ],
                    ),
                    ..._thumbMarks(layout),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              layout.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                height: 1,
                fontWeight: AppTypography.semibold,
                color: selected ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 구도 힌트 — 제목 막대 위치와 QR 자리.
  List<Widget> _thumbMarks(PosterLayout layout) {
    Widget bar({
      double? left,
      double? right,
      required double top,
      required double width,
      double height = 6,
      Color color = const Color(0xEBFFFFFF),
    }) => Positioned(
      left: left,
      right: right,
      top: top,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );

    Widget qr({double? left, double? right, required double bottom}) =>
        Positioned(
          left: left,
          right: right,
          bottom: bottom,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.gray0,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: AppColors.borderDefault),
            ),
          ),
        );

    return switch (layout) {
      PosterLayout.editorial => [
        bar(left: 10, top: 34, width: 42),
        bar(left: 10, top: 46, width: 30),
        qr(right: 10, bottom: 10),
      ],
      PosterLayout.centered => [
        bar(left: 20, top: 40, width: 38),
        bar(left: 25, top: 52, width: 28),
        qr(left: 32, bottom: 10),
      ],
      PosterLayout.headline => [
        bar(left: 10, top: 12, width: 54, height: 12),
        bar(left: 10, top: 60, width: 26),
        qr(right: 10, bottom: 10),
      ],
      PosterLayout.band => [
        bar(left: 10, top: 30, width: 42),
        bar(left: 10, top: 56, width: 28, color: AppColors.gray400),
        qr(right: 10, bottom: 10),
      ],
    };
  }

  // ── 내용 ────────────────────────────────────────────────────
  Widget _contentPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IamTextarea(
          controller: controller.introController,
          label: '모임 소개',
          hint: '기존 내용을 불러왔어요',
          maxLength: 400,
          rows: 4,
          onChanged: controller.setIntro,
        ),
        const SizedBox(height: AppDimens.space3),
        IamListItem(
          title: '포스터에 소개 문구 표시',
          description: '길면 포스터가 빽빽해져요',
          showChevron: false,
          trailing: IamToggle(
            checked: controller.config.value.showIntro,
            onChanged: controller.setShowIntro,
            semanticLabel: '포스터에 소개 문구 표시',
          ),
        ),
      ],
    );
  }

  Widget _groupLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppDimens.space2),
    child: Text(
      text,
      style: AppTypography.bodyS.copyWith(
        height: 1,
        fontWeight: AppTypography.bold,
        color: AppColors.textSecondary,
      ),
    ),
  );
}
