import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/dimens.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';

/// 명함 전체 보기 — 어두운 배경에 이미지 하나만 두고 좌우로 넘긴다.
///
/// `CardViewerSheet` 안의 이미지를 탭하면 열린다. 시트는 명함을 작게 보여주고
/// 저장·공유를 담당하는 자리라, 명함에 적힌 글씨를 읽으려면 더 큰 화면이 필요하다.
///
/// 내 명함과 상대방 명함이 같은 시트를 쓰므로 이 뷰어도 양쪽에 함께 붙는다.
abstract final class CardFullscreenViewer {
  /// [urls] 는 앞면부터 순서대로. [initial] 은 시트에서 보고 있던 면이다 —
  /// 뒷면을 보다가 탭했는데 앞면이 열리면 맥락이 끊긴다.
  static Future<void> show(
    BuildContext context, {
    required List<String> urls,
    int initial = 0,
  }) {
    if (urls.isEmpty) return Future<void>.value();

    // rootNavigator — 시트 안에서 밀면 시트 *아래* 로 깔린다.
    return Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: AppColors.gray900,
        pageBuilder: (_, __, ___) => _Viewer(urls: urls, initial: initial),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: AppMotion.fast,
      ),
    );
  }
}

class _Viewer extends StatefulWidget {
  const _Viewer({required this.urls, required this.initial});

  final List<String> urls;
  final int initial;

  @override
  State<_Viewer> createState() => _ViewerState();
}

class _ViewerState extends State<_Viewer> {
  late final PageController _controller = PageController(
    initialPage: _index,
  );
  late int _index = widget.initial.clamp(0, widget.urls.length - 1);

  bool get _hasMultiple => widget.urls.length > 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.gray900,
      child: SafeArea(
        child: Stack(
          children: [
            // ⚠️ Positioned.fill — Stack 의 기본 fit 은 loose 라 비배치 자식이
            //    자기 크기를 정한다. 그러면 이미지가 위쪽에 붙고 아래가 텅 빈다.
            Positioned.fill(
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.urls.length,
                onPageChanged: (i) => setState(() => _index = i),
                // ⚠️ 이미지에 상자 크기를 맡기지 않는다.
                //
                // 페이지 전체(tight, 화면 크기)를 줘도 그림이 상자 맨 위에
                // 붙어 그려진다 — 같은 자리의 Container 는 정확히 중앙에
                // 놓이는데도 그렇다. 색을 칠해 페이지·Center·이미지를 한
                // 프레임에서 비교해 확인했다.
                //
                // 그래서 크기를 밖에서 확정한다. FractionallySizedBox 로
                // 페이지 폭을 채우고(Center 만 쓰면 느슨한 제약이 내려가
                // AspectRatio 가 폭을 못 잡고 조그맣게 그려진다),
                // AspectRatio 로 세로를 정해 남는 공간을 가운데 정렬한다.
                // 9:5 는 카드·시트가 쓰는 것과 같은 명함 비율이다.
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.all(AppDimens.gutterMobile),
                  child: FractionallySizedBox(
                    widthFactor: 1,
                    child: AspectRatio(
                      aspectRatio: 9 / 5,
                      child: Image(
                        image: CachedNetworkImageProvider(widget.urls[i]),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            '이미지를 불러오지 못했어요.',
                            style: AppTypography.body.copyWith(
                              color: AppColors.gray0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: AppDimens.space2,
              right: AppDimens.space2,
              child: Semantics(
                button: true,
                label: '닫기',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: AppDimens.touchMin,
                    height: AppDimens.touchMin,
                    child: Center(
                      // 흰 아이콘이 밝은 명함 위에 얹히면 안 보인다.
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.overlayScrimStrong,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(6),
                          child: IamIcon(
                            IamIconName.close,
                            size: 22,
                            color: AppColors.gray0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_hasMultiple)
              Positioned(
                left: 0,
                right: 0,
                bottom: AppDimens.space6,
                child: _dots(),
              ),
          ],
        ),
      ),
    );
  }

  /// 현재 면 표시. 넘기는 건 스와이프가 맡으므로 여기선 탭 타깃을 두지 않는다.
  Widget _dots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < widget.urls.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _index == i
                    ? AppColors.gray0
                    : AppColors.gray0.withValues(alpha: 0.35),
              ),
            ),
          ),
      ],
    );
  }
}
