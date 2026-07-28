/// 앱 전역 상수 · 환경 설정.
/// 웹의 `IAM_web/src/lib/config/env.ts` 대응.
///
/// 값은 `--dart-define`으로 주입한다(키를 소스에 박지 않는다):
///   flutter run --dart-define=API_BASE=https://dev-api.octoverse.kr/iam/v1 \
///               --dart-define=KAKAO_NATIVE_KEY=xxxx
library;

// ── 서버 ─────────────────────────────────────────────────────
/// REST base. 웹과 동일 계약(`/iam/v1` · snake_case · string id).
const String kApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'https://dev-api.octoverse.kr/iam/v1',
);

/// Swagger: {kApiBase 도메인}/iam/docs
const Duration kConnectTimeout = Duration(seconds: 15);
const Duration kReceiveTimeout = Duration(seconds: 30);

// ── 인증 ─────────────────────────────────────────────────────
/// 카카오 네이티브 앱 키. 웹의 JS 키와 다르다(콘솔에서 별도 확인).
const String kKakaoNativeKey = String.fromEnvironment('KAKAO_NATIVE_KEY');

/// 개발용 로그인(REST §1.7 `POST /auth/test/login`) 사용 여부.
/// 카카오 키가 비어 있으면 자동으로 테스트 로그인으로 폴백한다.
///
/// `.isEmpty` 대신 `== ''` 를 쓰는 이유: 프로퍼티 접근은 const 식에서 허용되지
/// 않는다(`const_eval_property_access`). 비교 연산은 허용된다.
const bool kUseTestLogin = kKakaoNativeKey == '';

/// 테스트 로그인 기본 계정. 웹 `lib/config/dev-identity.ts`와 동일.
const String kDevEmail = 'doyoon@iam.app';

// ── 저장소 키 (GetStorage) ───────────────────────────────────
const String kStorageAccessToken = 'iam.access';
const String kStorageRefreshToken = 'iam.refresh';

/// 참조 데이터(관심사·카테고리) 버전 캐시. 웹 `iam.reference` 대응.
const String kStorageReference = 'iam.reference';

/// 읽은 알림 id 집합. 서버에 읽음 API가 없어 로컬로 보관한다.
/// 웹 `iam.notif.read`와 같은 임시 조치 — 서버 지원 시 제거.
const String kStorageNotificationRead = 'iam.notif.read';

// ── 도메인 규칙 ──────────────────────────────────────────────
/// 체크인 창이 열리는 시점 = start_at - 1시간.
/// ⚠️ 클라 계산은 진입점 노출용일 뿐, 최종 판정은 전적으로 서버다.
const Duration kCheckinLead = Duration(hours: 1);

/// 체크인 코드 자릿수.
const int kCheckinCodeLength = 6;

/// 프로필 입력 제한 (REST §3).
const int kMaxOneLiner = 80;
const int kMaxIntroduction = 1500;
const int kMaxInterests = 5;
const int kMaxSkills = 20;
const int kMaxLinks = 5;

/// 이미지 업로드 제한 (REST §2.1).
const int kMaxImageBytes = 5 * 1024 * 1024;
const List<String> kAllowedImageTypes = ['image/jpeg', 'image/png'];

/// 목록 페이지 크기.
const int kPageSize = 20;

// ── 외부 링크 ────────────────────────────────────────────────
const String kTermsUrl = 'https://octoverse.kr/terms';
const String kPrivacyUrl = 'https://octoverse.kr/privacy';

/// 참가 QR에 담기는 URL 형식: `{kWebOrigin}/event/{slug}`.
/// 스캐너는 이 형식만 우리 QR로 인정한다.
const String kWebOrigin = String.fromEnvironment(
  'WEB_ORIGIN',
  defaultValue: 'https://iam.octoverse.kr',
);
