import 'package:flutter_test/flutter_test.dart';

import 'package:iam/data/enums/enums.dart';
import 'package:iam/feature/event/poster/poster_config.dart';

/// 포스터 추천 프리셋 · 타이틀 크기 규칙 테스트.
///
/// 웹 `IAM_web/src/lib/poster/presets.ts`와 표가 어긋나면 같은 모임이 웹과 앱에서
/// 다른 포스터로 시작한다.
void main() {
  const description = '판교에서 만나는 사이드프로젝트 모임';

  group('recommend — 카테고리별 추천', () {
    test('소셜 네트워킹은 코랄 · Centered', () {
      final c = PosterPresets.recommend(
        EventCategory.socialNetworking,
        description,
      );
      expect(c.hue, PosterHue.coral);
      expect(c.layout, PosterLayout.centered);
    });

    test('컨퍼런스·박람회는 잉크 · Headline', () {
      for (final category in [
        EventCategory.conferenceSeminar,
        EventCategory.expoExhibition,
      ]) {
        final c = PosterPresets.recommend(category, description);
        expect(c.hue, PosterHue.ink, reason: '$category');
        expect(c.layout, PosterLayout.headline, reason: '$category');
      }
    });

    test('표에 없는 카테고리는 아이리스 · Editorial로 떨어진다', () {
      final c = PosterPresets.recommend(
        EventCategory.workshopStudy,
        description,
      );
      expect(c.hue, PosterHue.iris);
      expect(c.layout, PosterLayout.editorial);
    });

    test('추천은 항상 그라데이션이고, 소개는 접힌 채로 시작한다', () {
      final c = PosterPresets.recommend(EventCategory.orientation, description);
      expect(c.format, PosterColorFormat.gradient);
      expect(c.intro, description, reason: '설명은 프리필하되');
      expect(c.showIntro, isFalse, reason: '노출은 사용자가 켜야 한다');
    });
  });

  group('isRecommended — 추천과 같은지', () {
    const category = EventCategory.socialNetworking;
    final rec = PosterPresets.recommend(category, description);

    test('갓 만든 추천은 추천이다', () {
      expect(PosterPresets.isRecommended(rec, category), isTrue);
    });

    test('색을 바꾸면 추천이 아니다', () {
      final changed = rec.copyWith(hue: PosterHue.amber);
      expect(PosterPresets.isRecommended(changed, category), isFalse);
    });

    // 소개 편집은 "시각 설정"이 아니므로 추천 여부를 흔들면 안 된다.
    test('소개만 고친 건 여전히 추천이다', () {
      final edited = rec.copyWith(intro: '완전히 다른 소개', showIntro: true);
      expect(PosterPresets.isRecommended(edited, category), isTrue);
    });
  });

  group('restore — 추천으로 되돌리기', () {
    test('시각 설정은 되돌리고 편집한 소개는 남긴다', () {
      const category = EventCategory.conferenceSeminar;
      final edited = PosterPresets.recommend(category, description)
          .copyWith(
            hue: PosterHue.light,
            format: PosterColorFormat.solid,
            layout: PosterLayout.band,
            titleScale: PosterTitleScale.l,
            intro: '내가 고친 소개',
            showIntro: true,
          );

      final restored = PosterPresets.restore(edited, category);

      expect(restored.hue, PosterHue.ink);
      expect(restored.format, PosterColorFormat.gradient);
      expect(restored.layout, PosterLayout.headline);
      expect(restored.titleScale, PosterTitleScale.m);
      expect(restored.intro, '내가 고친 소개');
      expect(restored.showIntro, isTrue);
    });
  });

  group('titleSize — 제목 크기', () {
    PosterConfig config(PosterLayout layout, PosterTitleScale scale) =>
        PosterConfig(
          format: PosterColorFormat.gradient,
          hue: PosterHue.iris,
          layout: layout,
          titleScale: scale,
          intro: '',
          showIntro: false,
        );

    test('Headline은 다른 레이아웃보다 크게 시작한다', () {
      expect(
        config(PosterLayout.headline, PosterTitleScale.m).titleSize,
        greaterThan(config(PosterLayout.editorial, PosterTitleScale.m).titleSize),
      );
    });

    test('크기 단계가 오르내린다', () {
      final small = config(PosterLayout.editorial, PosterTitleScale.s).titleSize;
      final medium = config(
        PosterLayout.editorial,
        PosterTitleScale.m,
      ).titleSize;
      final large = config(PosterLayout.editorial, PosterTitleScale.l).titleSize;
      expect(small, lessThan(medium));
      expect(large, greaterThan(medium));
    });
  });

  group('hue — 배색', () {
    test('페이퍼만 밝은 배경이다(글자를 잉크색으로 뒤집는다)', () {
      for (final hue in PosterHue.values) {
        expect(hue.isLight, hue == PosterHue.light, reason: '$hue');
      }
    });

    test('모든 배색이 그라데이션 두 색과 솔리드 한 색을 갖는다', () {
      for (final hue in PosterHue.values) {
        expect(hue.gradient, hasLength(2), reason: '$hue');
      }
    });
  });
}
