import 'package:flutter/widgets.dart';

import 'colors.dart';

/// IAM 타이포 토큰 — `IAM_web/src/styles/tokens/typography.css` 1:1 이식.
///
/// 한글은 라틴보다 시각 밀도가 높아 행간을 넉넉히(1.5~1.65) 두고,
/// 큰 제목은 자간을 좁혀(-0.02em) 또렷하게 만든다.
///
/// CSS의 `letter-spacing: em` → Flutter는 px이므로 `fontSize * em`으로 환산했다.
/// (예: 24px × -0.018em = -0.432)
abstract final class AppTypography {
  static const fontFamily = 'Pretendard';

  // ── Weights ────────────────────────────────────────────────
  static const regular = FontWeight.w400;
  static const medium = FontWeight.w500;
  static const semibold = FontWeight.w600;
  static const bold = FontWeight.w700;

  /// 공통 베이스. 각 스타일은 여기서 파생한다.
  static const _base = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.textPrimary,
  );

  // ── Type scale (모바일 기준) ────────────────────────────────
  // 이름         size / line / weight / tracking
  // display-l    32 / 42 / 700 / -0.02em   온보딩 히어로
  // display      28 / 38 / 700 / -0.02em
  // title-1      24 / 33 / 700 / -0.018em  화면 제목
  // title-2      20 / 28 / 700 / -0.015em  섹션 제목
  // title-3      18 / 26 / 600 / -0.01em   카드 제목
  // body-l       17 / 27 / 400 / -0.005em  중요 본문
  // body         15 / 24 / 400 / -0.003em  기본 본문
  // body-s       14 / 22 / 400 /  0        보조 본문
  // caption      13 / 19 / 400 /  0        캡션
  // label        12 / 17 / 500 /  0.01em   라벨/뱃지

  static final displayL = _base.copyWith(
    fontSize: 32,
    height: 42 / 32,
    fontWeight: bold,
    letterSpacing: -0.64,
  );
  static final display = _base.copyWith(
    fontSize: 28,
    height: 38 / 28,
    fontWeight: bold,
    letterSpacing: -0.56,
  );
  static final title1 = _base.copyWith(
    fontSize: 24,
    height: 33 / 24,
    fontWeight: bold,
    letterSpacing: -0.432,
  );
  static final title2 = _base.copyWith(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: bold,
    letterSpacing: -0.3,
  );
  static final title3 = _base.copyWith(
    fontSize: 18,
    height: 26 / 18,
    fontWeight: semibold,
    letterSpacing: -0.18,
  );
  static final bodyL = _base.copyWith(
    fontSize: 17,
    height: 27 / 17,
    fontWeight: regular,
    letterSpacing: -0.085,
  );
  static final body = _base.copyWith(
    fontSize: 15,
    height: 24 / 15,
    fontWeight: regular,
    letterSpacing: -0.045,
  );
  static final bodyS = _base.copyWith(
    fontSize: 14,
    height: 22 / 14,
    fontWeight: regular,
  );
  static final caption = _base.copyWith(
    fontSize: 13,
    height: 19 / 13,
    fontWeight: regular,
  );
  static final label = _base.copyWith(
    fontSize: 12,
    height: 17 / 12,
    fontWeight: medium,
    letterSpacing: 0.12,
  );
}
