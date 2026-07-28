import 'package:flutter/material.dart';

/// IAM 색 토큰 — `IAM_web/src/styles/tokens/colors.css` 1:1 이식.
///
/// Figma 변수(`3.UI` node 16:4)와 이름·값이 정확히 일치한다:
///   `--color-primary` #4360E6 · `--color-accent` #FF6B52 · `--text-primary` #15191F …
///
/// 방향 B "따뜻한 연결": Iris indigo = 신뢰, Coral = 온기/찜.
/// 본문 텍스트 조합은 WCAG AA(4.5:1) 이상을 목표로 한다.
///
/// ⚠️ 화면에서 raw hex를 쓰지 않는다. 반드시 아래 semantic alias를 참조한다.
abstract final class AppColors {
  // ── Primary · Iris indigo (신뢰 / Primary CTA) ──────────────
  static const iris50 = Color(0xFFEEF1FE);
  static const iris100 = Color(0xFFDCE4FD);
  static const iris200 = Color(0xFFBCC9FB);
  static const iris300 = Color(0xFF94A6F6);
  static const iris400 = Color(0xFF6B82EF);

  /// 브랜드 · primary 버튼 (흰 글자 대비 5.1:1)
  static const iris500 = Color(0xFF4360E6);
  static const iris600 = Color(0xFF2C44C9);
  static const iris700 = Color(0xFF2235A0);
  static const iris800 = Color(0xFF1B2A7D);
  static const iris900 = Color(0xFF16215C);

  // ── Secondary · Coral (온기 · 찜 하트 · 의향) ────────────────
  // FILL / ICON 전용 — 본문 텍스트로 쓰기엔 너무 밝다.
  static const coral50 = Color(0xFFFFF0ED);
  static const coral100 = Color(0xFFFFDED7);
  static const coral200 = Color(0xFFFFC3B6);
  static const coral300 = Color(0xFFFF9E8B);
  static const coral400 = Color(0xFFFF8166);

  /// 찜 채워진 하트
  static const coral500 = Color(0xFFFF6B52);
  static const coral600 = Color(0xFFED4A30);

  /// 흰 배경 위 코랄 텍스트 (AA)
  static const coral700 = Color(0xFFC23A23);

  // ── Semantic · 인증/성공 ────────────────────────────────────
  static const success50 = Color(0xFFE7F8F0);
  static const success100 = Color(0xFFC6EFDC);
  static const success500 = Color(0xFF12B886);
  static const success600 = Color(0xFF0CA678);
  static const success700 = Color(0xFF0B7A52);

  // ── Semantic · 경고 (amber — 카카오 옐로 아님) ───────────────
  static const warning50 = Color(0xFFFFF6E5);
  static const warning100 = Color(0xFFFFE8BF);
  static const warning500 = Color(0xFFF59F00);
  static const warning600 = Color(0xFFE08700);
  static const warning700 = Color(0xFF9C6500);

  // ── Semantic · 오류 ─────────────────────────────────────────
  static const error50 = Color(0xFFFFEDED);
  static const error100 = Color(0xFFFFD6D6);
  static const error500 = Color(0xFFFA5252);
  static const error600 = Color(0xFFE03131);
  static const error700 = Color(0xFFC0282A);

  // ── Semantic · 정보 ─────────────────────────────────────────
  static const info50 = Color(0xFFE7F2FE);
  static const info100 = Color(0xFFCBE3FD);
  static const info500 = Color(0xFF3B9EF0);
  static const info600 = Color(0xFF1E86E0);
  static const info700 = Color(0xFF1366B0);

  // ── Neutral · Slate (살짝 차가운 중립, 인디고와 짝) ──────────
  static const gray0 = Color(0xFFFFFFFF);
  static const gray50 = Color(0xFFF7F8FA);
  static const gray100 = Color(0xFFEFF1F4);
  static const gray200 = Color(0xFFE4E7EC);
  static const gray300 = Color(0xFFD2D7DF);
  static const gray400 = Color(0xFFAAB2BF);
  static const gray500 = Color(0xFF828B99);
  static const gray600 = Color(0xFF626B7A);
  static const gray700 = Color(0xFF454D5A);
  static const gray800 = Color(0xFF2B313B);
  static const gray900 = Color(0xFF15191F);

  // ── Brand fixed · Kakao (로그인 버튼 전용 · 절대 재사용 금지) ─
  static const kakaoYellow = Color(0xFFFEE500);
  static const kakaoSymbol = Color(0xFF000000);
  static const kakaoLabel = Color(0xD9000000); // rgba(0,0,0,0.85)

  // ══════════════════════════════════════════════════════════
  // Semantic aliases — 컴포넌트는 여기만 참조한다
  // ══════════════════════════════════════════════════════════

  // Action
  static const primary = iris500;
  static const primaryHover = iris600;
  static const primaryPress = iris700;
  static const primarySoft = iris50;
  static const primarySofter = iris100;
  static const onPrimary = gray0;

  /// 찜 · 온기 포인트
  static const accent = coral500;
  static const accentPress = coral600;
  static const accentSoft = coral50;

  // Text
  static const textPrimary = gray900;
  static const textSecondary = Color(0xFF545C6B); // 흰 배경 대비 ~6:1 (AA)
  static const textTertiary = Color(0xFF79808E); // placeholder / hint
  static const textDisabled = gray400;
  static const textOnPrimary = gray0;
  static const textLink = iris600;

  // Surface
  static const surfacePage = gray50;
  static const surfaceCard = gray0;
  static const surfaceSunken = gray100;
  static const surfaceRaised = gray0;
  static const surfaceInverse = gray900;
  static const overlayScrim = Color(0x8015191F); // rgba(21,25,31,0.50)
  static const overlayScrimStrong = Color(0xB815191F); // 커버 위 텍스트 가독용

  // Border
  static const borderSubtle = gray100;
  static const borderDefault = gray200;
  static const borderStrong = gray300;
  static const borderFocus = iris500;

  // Verified (본인인증) — ⚠️ K2: 전 화면 미렌더. 토큰만 유지한다.
  static const verifiedBg = success700;
  static const verifiedFg = gray0;
  static const verifiedSoftBg = success50;
  static const verifiedSoftFg = success700;

  // Status — 모임 상태 배지 (channelPhase 결과에 매핑)
  static const statusOpenFg = success700;
  static const statusOpenBg = success50;
  static const statusClosedFg = gray600;
  static const statusClosedBg = gray100;
  static const statusSoonFg = warning700;
  static const statusSoonBg = warning50;
  static const statusLiveFg = info700;
  static const statusLiveBg = info50;
}
