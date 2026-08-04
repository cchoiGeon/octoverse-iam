import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/utils/image_share_utils.dart';
import 'package:iam/common/widgets/ds/ds.dart';
import 'package:iam/service/services.dart';

import 'card_fullscreen_viewer.dart';

/// 명함 뷰어 — 앞/뒤를 크게 보고 저장·공유한다.
///
/// 웹 대응: `IAM_web/src/components/app/CardViewerSheet.tsx`
///
/// 명함은 이미 이미지라 포스터처럼 위젯을 캡처할 필요가 없다 — URL을 그대로
/// 내려받아 갤러리에 넣거나 공유 시트로 넘긴다.
abstract final class CardViewerSheet {
  /// [backUrl]이 있으면 앞/뒤 전환 도트가 붙는다.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String frontUrl,
    String? backUrl,
  }) {
    return IamBottomSheet.show<void>(
      context,
      title: title,
      builder: (_) =>
          _Body(title: title, frontUrl: frontUrl, backUrl: backUrl),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.title, required this.frontUrl, this.backUrl});

  final String title;
  final String frontUrl;
  final String? backUrl;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  /// 0 = 앞면, 1 = 뒷면.
  ///
  /// 스와이프와 도트 어느 쪽으로 넘겨도 이 값이 진실이다 —
  /// 저장·공유가 지금 보고 있는 면을 대상으로 해야 하기 때문이다.
  int _side = 0;
  bool _busy = false;

  final PageController _pager = PageController();

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  bool get _hasBack => widget.backUrl != null && widget.backUrl!.isNotEmpty;

  /// 지금 보고 있는 면. 저장·공유도 이 면을 대상으로 한다.
  String get _currentUrl =>
      _side == 1 && _hasBack ? widget.backUrl! : widget.frontUrl;

  /// 전체 보기에 넘길 목록 — 앞면부터.
  List<String> get _urls => [
    widget.frontUrl,
    if (_hasBack) widget.backUrl!,
  ];

  ToastService get _toast => Get.find<ToastService>();

  Future<void> _run(bool save) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await ImageShareUtils.fetchImageBytes(_currentUrl);
      if (bytes == null) {
        _toast.error('명함 이미지를 불러오지 못했어요.');
        return;
      }
      final name = ImageShareUtils.slugify(widget.title, fallback: 'card');
      final result = save
          ? await ImageShareUtils.saveToGallery(bytes, name: name)
          : await ImageShareUtils.shareImage(
              bytes,
              fileName: name,
              text: widget.title,
            );

      switch (result) {
        case ImageActionResult.done:
          if (save) _toast.success('명함을 저장했어요.');
        case ImageActionResult.denied:
          _toast.error('사진 접근 권한이 없어 저장하지 못했어요. 설정에서 허용해 주세요.');
        case ImageActionResult.failed:
          _toast.error(
            save
                ? '저장에 실패했어요. 잠시 후 다시 시도해 주세요.'
                : '공유에 실패했어요. 잠시 후 다시 시도해 주세요.',
          );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          child: AspectRatio(
            aspectRatio: 9 / 5,
            child: PageView.builder(
              controller: _pager,
              itemCount: _urls.length,
              // 도트로 넘기든 밀어서 넘기든 여기로 모인다.
              onPageChanged: (i) => setState(() => _side = i),
              itemBuilder: (_, i) => Semantics(
                button: true,
                label: '명함 전체 보기',
                // 시트 안에서는 명함 글씨를 읽기 어렵다 — 탭하면 전체 보기로
                // 넘긴다. 보고 있던 면 그대로 열어야 맥락이 끊기지 않는다.
                child: GestureDetector(
                  onTap: () => CardFullscreenViewer.show(
                    context,
                    urls: _urls,
                    initial: i,
                  ),
                  child: CachedNetworkImage(
                    imageUrl: _urls[i],
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) =>
                        const ColoredBox(color: AppColors.surfaceSunken),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_hasBack) ...[
          const SizedBox(height: AppDimens.space3),
          _dots(),
        ],
        const SizedBox(height: AppDimens.space4),
        Row(
          children: [
            Expanded(
              child: IamButton(
                label: '저장',
                variant: IamButtonVariant.ghost,
                block: true,
                loading: _busy,
                onPressed: () => _run(true),
              ),
            ),
            const SizedBox(width: AppDimens.space2),
            Expanded(
              child: IamButton(
                label: '공유',
                block: true,
                loading: _busy,
                onPressed: () => _run(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 앞/뒤 전환 — 도트가 곧 탭 타깃이다. 8px 원을 44px 히트 영역이 감싼다.
  Widget _dots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 2; i++)
          Semantics(
            button: true,
            selected: _side == i,
            label: i == 0 ? '앞면' : '뒷면',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // _side 를 직접 바꾸지 않는다 — 페이지를 옮기면 onPageChanged 가
              // 갱신한다. 직접 바꾸면 도트와 보이는 면이 어긋난다.
              onTap: () => _pager.animateToPage(
                i,
                duration: AppMotion.base,
                curve: AppMotion.standard,
              ),
              child: SizedBox(
                width: 28,
                height: AppDimens.touchMin,
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _side == i
                          ? AppColors.primary
                          : AppColors.borderDefault,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
