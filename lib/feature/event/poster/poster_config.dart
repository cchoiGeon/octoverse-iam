import 'package:flutter/widgets.dart';

import 'package:iam/common/constants/colors.dart';
import 'package:iam/data/data_manager.dart';

/// 홍보포스터 편집 상태 모델 + 색/레이아웃 스킴.
///
/// 웹 대응: `IAM_web/src/lib/poster/{types,schemes,presets}.ts`
///
/// ⚠️ **폰트 축은 옮기지 않았다.** 웹은 명조·둥근·임팩트·손글씨를 웹폰트로 고르지만
///    앱은 번들된 Pretendard 하나뿐이라, 폰트를 지원하려면 서체를 에셋으로 넣는
///    라이선스·용량 결정이 먼저다. 그때까지 이 축은 없다.

enum PosterColorFormat { gradient, solid }

enum PosterHue { iris, coral, forest, amber, ink, light }

enum PosterLayout { editorial, centered, headline, band }

enum PosterTitleScale { s, m, l }

extension PosterHueX on PosterHue {
  String get label => switch (this) {
    PosterHue.iris => '아이리스',
    PosterHue.coral => '코랄',
    PosterHue.forest => '포레스트',
    PosterHue.amber => '앰버',
    PosterHue.ink => '잉크',
    PosterHue.light => '페이퍼',
  };

  /// 그라데이션(위→아래) 짝.
  List<Color> get gradient => switch (this) {
    PosterHue.iris => const [AppColors.iris400, AppColors.iris900],
    PosterHue.coral => const [AppColors.coral400, AppColors.coral700],
    PosterHue.forest => const [AppColors.success500, AppColors.success700],
    PosterHue.amber => const [AppColors.warning500, AppColors.warning700],
    PosterHue.ink => const [AppColors.gray800, AppColors.gray900],
    PosterHue.light => const [AppColors.gray0, AppColors.gray100],
  };

  /// 솔리드 단일색.
  Color get solid => switch (this) {
    PosterHue.iris => AppColors.iris500,
    PosterHue.coral => AppColors.coral500,
    PosterHue.forest => AppColors.success600,
    PosterHue.amber => AppColors.warning600,
    PosterHue.ink => AppColors.gray900,
    PosterHue.light => AppColors.gray50,
  };

  /// 배경이 밝아 글자를 잉크색으로 뒤집어야 하는가.
  bool get isLight => this == PosterHue.light;
}

extension PosterLayoutX on PosterLayout {
  String get label => switch (this) {
    PosterLayout.editorial => 'Editorial',
    PosterLayout.centered => 'Centered',
    PosterLayout.headline => 'Headline',
    PosterLayout.band => 'Band',
  };
}

extension PosterTitleScaleX on PosterTitleScale {
  String get label => switch (this) {
    PosterTitleScale.s => '작게',
    PosterTitleScale.m => '보통',
    PosterTitleScale.l => '크게',
  };
}

/// 포스터 한 장의 설정. 값 타입이라 `copyWith`로만 바뀐다.
@immutable
class PosterConfig {
  const PosterConfig({
    required this.format,
    required this.hue,
    required this.layout,
    required this.titleScale,
    required this.intro,
    required this.showIntro,
  });

  final PosterColorFormat format;
  final PosterHue hue;
  final PosterLayout layout;
  final PosterTitleScale titleScale;

  /// 모임 소개(상세의 description을 프리필하고 사용자가 고칠 수 있다).
  final String intro;

  /// 포스터에 소개 문구를 노출할지.
  final bool showIntro;

  PosterConfig copyWith({
    PosterColorFormat? format,
    PosterHue? hue,
    PosterLayout? layout,
    PosterTitleScale? titleScale,
    String? intro,
    bool? showIntro,
  }) => PosterConfig(
    format: format ?? this.format,
    hue: hue ?? this.hue,
    layout: layout ?? this.layout,
    titleScale: titleScale ?? this.titleScale,
    intro: intro ?? this.intro,
    showIntro: showIntro ?? this.showIntro,
  );

  /// 배경 — 솔리드도 같은 색 두 개짜리 그라데이션으로 만들어 그리는 쪽을 하나로 둔다.
  List<Color> get background =>
      format == PosterColorFormat.solid ? [hue.solid, hue.solid] : hue.gradient;

  /// 1080 캔버스 기준 타이틀 크기. Headline은 더 크게 시작한다.
  double get titleSize {
    final base = layout == PosterLayout.headline ? 118.0 : 86.0;
    return base +
        switch (titleScale) {
          PosterTitleScale.s => -14.0,
          PosterTitleScale.m => 0.0,
          PosterTitleScale.l => 16.0,
        };
  }
}

/// 카테고리 → 추천 색·레이아웃. 웹 `CATEGORY_PRESET`과 같은 표다.
abstract final class PosterPresets {
  static const _fallback = (PosterHue.iris, PosterLayout.editorial);

  static const _byCategory = {
    EventCategory.socialNetworking: (PosterHue.coral, PosterLayout.centered),
    EventCategory.conferenceSeminar: (PosterHue.ink, PosterLayout.headline),
    EventCategory.expoExhibition: (PosterHue.ink, PosterLayout.headline),
  };

  /// 진입 시 자동 적용되는 추천 설정. 소개는 기본 접힘이다
  /// (긴 설명이 그대로 들어가면 포스터가 빽빽해진다).
  static PosterConfig recommend(EventCategory category, String description) {
    final (hue, layout) = _byCategory[category] ?? _fallback;
    return PosterConfig(
      format: PosterColorFormat.gradient,
      hue: hue,
      layout: layout,
      titleScale: PosterTitleScale.m,
      intro: description,
      showIntro: false,
    );
  }

  /// 지금 설정이 추천과 같은가 — **시각 설정만** 본다(소개 편집은 제외).
  static bool isRecommended(PosterConfig config, EventCategory category) {
    final rec = recommend(category, config.intro);
    return config.format == rec.format &&
        config.hue == rec.hue &&
        config.layout == rec.layout &&
        config.titleScale == rec.titleScale;
  }

  /// 추천으로 되돌리기 — 사용자가 편집한 소개는 보존한다.
  static PosterConfig restore(PosterConfig config, EventCategory category) =>
      recommend(category, config.intro).copyWith(showIntro: config.showIntro);
}
