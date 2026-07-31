import 'package:flutter/widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/common/constants/typography.dart';
import 'package:iam/common/widgets/ds/ds.dart';

import '../poster_config.dart';

/// 포스터 아트보드 — 1:1 정사각.
///
/// 웹 대응: `IAM_web/src/components/app/poster/EventPosterCanvas.tsx`
///
/// 웹은 1080px 실치수 노드를 만들고 미리보기만 `transform: scale`로 줄였다.
/// 여기서는 반대로 **주어진 [size]에 맞춰 그리고**, 캡처할 때 `pixelRatio`를
/// 올려 1080px을 얻는다(`EventPosterController.shareImage` 참고).
/// 레이아웃이 전부 [size] 비례라 결과 구도는 웹과 같다.
class PosterCanvas extends StatelessWidget {
  const PosterCanvas({
    super.key,
    required this.size,
    required this.config,
    required this.title,
    required this.categoryLabel,
    required this.dateLabel,
    required this.location,
    required this.organizerName,
    required this.interests,
    required this.joinUrl,
  });

  /// 이 위젯이 차지할 한 변 길이(px).
  final double size;

  final PosterConfig config;
  final String title;
  final String categoryLabel;
  final String dateLabel;
  final String location;
  final String organizerName;
  final List<String> interests;
  final String joinUrl;

  /// 1080 기준 값을 실제 크기로 환산한다.
  double _u(double v) => v * size / 1080;

  bool get _light => config.hue.isLight;
  Color get _fg => _light ? AppColors.gray900 : AppColors.gray0;
  Color get _fg2 => _light
      ? AppColors.textSecondary
      : AppColors.gray0.withValues(alpha: 0.72);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: config.layout == PosterLayout.band ? _band() : _standard(),
      ),
    );
  }

  // ── Editorial · Centered · Headline ─────────────────────────
  Widget _standard() {
    final centered = config.layout == PosterLayout.centered;
    final headline = config.layout == PosterLayout.headline;

    return Container(
      padding: EdgeInsets.all(_u(64)),
      decoration: BoxDecoration(gradient: _gradient()),
      child: Column(
        crossAxisAlignment: centered
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          _header(),
          // Headline은 제목을 위로 올려 먼저 읽히게 한다.
          if (headline) ...[
            SizedBox(height: _u(40)),
            _title(centered),
          ],
          const Spacer(),
          if (!headline) ...[
            _title(centered),
            SizedBox(height: _u(28)),
          ],
          _info(centered),
          SizedBox(height: _u(34)),
          _footer(centered),
        ],
      ),
    );
  }

  // ── Band — 위는 색면, 아래는 페이퍼 밴드 ────────────────────
  Widget _band() {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              flex: 132,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(_u(64)),
                decoration: BoxDecoration(gradient: _gradient()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(),
                    const Spacer(),
                    _title(false),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 100,
              child: Container(
                width: double.infinity,
                // 우측은 QR 자리로 비워 둔다(아래 Positioned가 덮는다).
                padding: EdgeInsets.fromLTRB(_u(64), _u(64), _u(340), _u(64)),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.gray0, AppColors.gray100],
                  ),
                  border: Border(
                    top: BorderSide(color: AppColors.borderDefault),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _metaRow(IamIconName.calendar, dateLabel, AppColors.gray900),
                    SizedBox(height: _u(14)),
                    _metaRow(IamIconName.mapPin, location, AppColors.gray900),
                    if (_showIntro) ...[
                      SizedBox(height: _u(24)),
                      Flexible(
                        child: Text(
                          config.intro.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _text(26, height: 1.5).copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        // 주최 + QR은 다른 레이아웃과 같은 자리에 고정한다.
        Positioned(
          left: _u(64),
          right: _u(64),
          bottom: _u(64),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '주최 · $organizerName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _text(
                    28,
                    weight: AppTypography.medium,
                  ).copyWith(color: AppColors.textSecondary),
                ),
              ),
              _qr(light: true),
            ],
          ),
        ),
      ],
    );
  }

  // ── 조각 ────────────────────────────────────────────────────

  LinearGradient _gradient() => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: config.background,
  );

  bool get _showIntro => config.showIntro && config.intro.trim().isNotEmpty;

  /// 카테고리 배지 + IAM 워드마크. 모든 레이아웃이 공유한다.
  Widget _header() {
    return Row(
      children: [
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _u(24),
              vertical: _u(13),
            ),
            decoration: BoxDecoration(
              color: _light
                  ? AppColors.primarySoft
                  : AppColors.gray0.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(_u(999)),
            ),
            child: Text(
              categoryLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _text(26, weight: AppTypography.bold).copyWith(
                letterSpacing: _u(0.78),
                color: _light ? AppColors.primaryPress : AppColors.gray0,
              ),
            ),
          ),
        ),
        const Spacer(),
        Text(
          'IAM',
          style: _text(
            34,
            weight: AppTypography.bold,
          ).copyWith(letterSpacing: _u(-0.34)),
        ),
      ],
    );
  }

  Widget _title(bool centered) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        title,
        textAlign: centered ? TextAlign.center : TextAlign.left,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: _text(
          config.titleSize,
          weight: AppTypography.bold,
          height: 1.08,
        ).copyWith(letterSpacing: _u(config.titleSize * -0.02)),
      ),
    );
  }

  Widget _info(bool centered) {
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Container(
          height: _u(2),
          width: double.infinity,
          color: _light
              ? AppColors.borderDefault
              : AppColors.gray0.withValues(alpha: 0.18),
        ),
        SizedBox(height: _u(26)),
        _metaRow(IamIconName.calendar, dateLabel, _fg, centered: centered),
        SizedBox(height: _u(14)),
        _metaRow(IamIconName.mapPin, location, _fg, centered: centered),
        if (interests.isNotEmpty) ...[
          SizedBox(height: _u(26)),
          Wrap(
            alignment: centered ? WrapAlignment.center : WrapAlignment.start,
            spacing: _u(12),
            runSpacing: _u(12),
            children: [
              for (final tag in interests.take(3)) _chip(tag),
            ],
          ),
        ],
        if (_showIntro) ...[
          SizedBox(height: _u(26)),
          Text(
            config.intro.trim(),
            textAlign: centered ? TextAlign.center : TextAlign.left,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: _text(26, height: 1.5).copyWith(color: _fg2),
          ),
        ],
      ],
    );
  }

  Widget _chip(String tag) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _u(22), vertical: _u(10)),
      decoration: BoxDecoration(
        color: _light
            ? AppColors.gray100
            : AppColors.gray0.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(_u(999)),
        border: _light
            ? null
            : Border.all(
                color: AppColors.gray0.withValues(alpha: 0.26),
                width: _u(1),
              ),
      ),
      child: Text('#$tag', style: _text(24, weight: AppTypography.semibold)),
    );
  }

  Widget _metaRow(
    IamIconName icon,
    String text,
    Color color, {
    bool centered = false,
  }) {
    return Row(
      mainAxisAlignment: centered
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      mainAxisSize: centered ? MainAxisSize.min : MainAxisSize.max,
      children: [
        IamIcon(icon, size: _u(32), color: color),
        SizedBox(width: _u(14)),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _text(
              30,
              weight: AppTypography.semibold,
            ).copyWith(color: color),
          ),
        ),
      ],
    );
  }

  Widget _footer(bool centered) {
    final organizer = Text(
      '주최 · $organizerName',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: _text(28, weight: AppTypography.medium).copyWith(color: _fg2),
    );

    if (centered) {
      return Column(
        children: [
          _qr(),
          SizedBox(height: _u(24)),
          organizer,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: organizer),
        SizedBox(width: _u(20)),
        _qr(),
      ],
    );
  }

  /// QR은 항상 흰 카드 위에 짙은 남색으로 — 스캔 신뢰성을 배색보다 우선한다.
  Widget _qr({bool light = false}) {
    return Container(
      width: _u(264),
      height: _u(264),
      padding: EdgeInsets.all(_u(22)),
      decoration: BoxDecoration(
        color: AppColors.gray0,
        borderRadius: BorderRadius.circular(_u(28)),
        border: (_light || light)
            ? Border.all(color: AppColors.borderDefault, width: _u(1))
            : null,
      ),
      child: QrImageView(
        data: joinUrl,
        size: _u(220),
        padding: EdgeInsets.zero,
        // 웹 QR_DARK와 같은 값.
        dataModuleStyle: const QrDataModuleStyle(
          color: Color(0xFF16215C),
          dataModuleShape: QrDataModuleShape.square,
        ),
        eyeStyle: const QrEyeStyle(
          color: Color(0xFF16215C),
          eyeShape: QrEyeShape.square,
        ),
      ),
    );
  }

  TextStyle _text(
    double size, {
    FontWeight weight = AppTypography.regular,
    double height = 1.2,
  }) => TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: _u(size),
    fontWeight: weight,
    height: height,
    color: _fg,
  );
}
