import 'package:flutter/material.dart';

import 'colors.dart';

/// IAM 간격·반경·그림자 토큰.
/// `IAM_web/src/styles/tokens/{spacing,radius,shadows,motion}.css` 1:1 이식.
abstract final class AppDimens {
  // ── Spacing (8pt 그리드 + 4px 하프스텝) ──────────────────────
  static const space0 = 0.0;
  static const space1 = 4.0;
  static const space2 = 8.0;
  static const space3 = 12.0;
  static const space4 = 16.0;
  static const space5 = 20.0;
  static const space6 = 24.0;
  static const space7 = 32.0;
  static const space8 = 40.0;
  static const space9 = 48.0;
  static const space10 = 56.0;
  static const space11 = 64.0;
  static const space12 = 80.0;
  static const space14 = 96.0;

  // ── Semantic spacing ───────────────────────────────────────
  /// 화면 좌우 여백. Figma 변수 `--gutter-mobile` = 16.
  static const gutterMobile = 16.0;
  static const gutterDesktop = 24.0;
  static const sectionGap = 32.0;
  static const stackTight = 8.0;
  static const stack = 12.0;
  static const stackLoose = 16.0;

  // ── Touch targets (모바일 최소 44) ──────────────────────────
  static const touchMin = 44.0;
  static const touchComfy = 48.0;
  static const bottomCtaHeight = 56.0;

  // ── Layout ─────────────────────────────────────────────────
  /// 모바일 콘텐츠 최대폭. 태블릿·폴더블에서 가운데 정렬 기준.
  static const maxContent = 480.0;
  static const maxContentWide = 1040.0;
  static const headerHeight = 56.0;
  static const tabbarHeight = 64.0;

  // ── Button heights (Button size sm/md/lg) ──────────────────
  static const buttonSm = 40.0;
  static const buttonMd = 48.0;
  static const buttonLg = 56.0;

  // ── Radius ─────────────────────────────────────────────────
  static const radiusXs = 6.0; // 칩, 작은 태그
  static const radiusSm = 8.0; // 입력 보조요소
  static const radiusMd = 12.0; // 버튼, 입력, 카카오 버튼(가이드 고정)
  static const radiusLg = 16.0; // 카드
  static const radiusXl = 20.0; // 큰 카드, 시트
  static const radius2xl = 24.0; // 바텀시트, 모달
  static const radiusPill = 999.0; // 필터칩, 아바타, 토글

  // ── Border widths ──────────────────────────────────────────
  static const borderWidth = 1.0;
  static const borderWidthStrong = 1.5;
}

/// Elevation — 부드럽고 낮은 그림자(안심). 그림자 색은 잉크 네이비 계열.
/// Figma 스타일 `IAM/Elevation/3`이 `elev3`에 대응한다.
abstract final class AppShadows {
  static const _ink = Color(0xFF1A1F26); // rgb(26,31,38)

  static const none = <BoxShadow>[];

  static final elev1 = [
    BoxShadow(
      color: _ink.withValues(alpha: 0.06),
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
    BoxShadow(
      color: _ink.withValues(alpha: 0.04),
      offset: const Offset(0, 1),
      blurRadius: 3,
    ),
  ];
  static final elev2 = [
    BoxShadow(
      color: _ink.withValues(alpha: 0.07),
      offset: const Offset(0, 2),
      blurRadius: 6,
    ),
    BoxShadow(
      color: _ink.withValues(alpha: 0.05),
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  /// = Figma `IAM/Elevation/3`
  static final elev3 = [
    BoxShadow(
      color: _ink.withValues(alpha: 0.09),
      offset: const Offset(0, 6),
      blurRadius: 16,
    ),
    BoxShadow(
      color: _ink.withValues(alpha: 0.05),
      offset: const Offset(0, 2),
      blurRadius: 4,
    ),
  ];
  static final elev4 = [
    BoxShadow(
      color: _ink.withValues(alpha: 0.14),
      offset: const Offset(0, 12),
      blurRadius: 32,
    ),
    BoxShadow(
      color: _ink.withValues(alpha: 0.06),
      offset: const Offset(0, 4),
      blurRadius: 8,
    ),
  ];

  /// 하단 고정 CTA — 위로 드리우는 그림자
  static final bottomCta = [
    BoxShadow(
      color: _ink.withValues(alpha: 0.06),
      offset: const Offset(0, -2),
      blurRadius: 12,
    ),
  ];

  /// 포커스 링(접근성)
  static final ringFocus = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.35),
      spreadRadius: 3,
    ),
  ];
}

/// Motion — 차분·절제·안심. 과한 바운스 없음.
/// Hover = 색 어둡게, Press = 살짝 축소(0.97) + 더 어둡게.
abstract final class AppMotion {
  static const instant = Duration(milliseconds: 80);
  static const fast = Duration(milliseconds: 120);
  static const base = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 320);

  /// 스켈레톤 shimmer 1주기
  static const skeleton = Duration(milliseconds: 1500);

  static const standard = Cubic(0.2, 0, 0, 1);
  static const emphasized = Cubic(0.3, 0, 0, 1);
  static const exit = Cubic(0.4, 0, 1, 1);
  static const gentleSpring = Cubic(0.34, 1.3, 0.5, 1);

  /// 눌림 축소 배율
  static const pressScale = 0.97;
}
