part of 'app_pages.dart';

/// 라우트 경로 상수 — `IAM_web/src/app/**` 파일 경로와 1:1이다.
///
/// 동적 세그먼트는 `:slug` · `:userId`. 이동 시 헬퍼를 쓰면 오타를 막을 수 있다:
///   `Get.toNamed(AppRoutes.eventDetailOf('ai-meetup'))`
abstract final class AppRoutes {
  // ── 진입 ───────────────────────────────────────────────────
  /// 부팅 · 세션 확인. 웹에는 없다(RouteGuard가 대신했다).
  static const splash = '/splash';

  /// 01 랜딩. 웹은 `/`에서 비로그인이면 Landing을 그렸지만,
  /// 앱은 화면을 분리해 스택 제어를 단순하게 한다.
  static const login = '/login';

  /// 02·03 프로필 작성 3스텝.
  static const onboarding = '/onboarding';

  // ── 메인 탭 (하단 탭바가 보이는 4개 화면) ───────────────────
  /// 04b 모임 둘러보기.
  static const home = '/';
  static const meMeetings = '/me/meetings';
  static const meLikes = '/me/likes';
  static const me = '/me';

  /// 하단 탭바를 띄우는 라우트 목록. 순서 = 탭 순서(홈·모임·찜·마이).
  static const tabRoutes = [home, meMeetings, meLikes, me];

  // ── 모임 ───────────────────────────────────────────────────
  /// ⚠️ `eventNew`는 `eventDetail`(`/event/:slug`)보다 **먼저** 등록해야 한다.
  ///    안 그러면 `new`가 slug로 잡힌다.
  static const eventNew = '/event/new';
  static const eventDetail = '/event/:slug';
  static const eventEdit = '/event/:slug/edit';
  static const eventManage = '/event/:slug/manage';
  static const eventPeople = '/event/:slug/people';
  static const eventPeopleDetail = '/event/:slug/people/:userId';
  static const eventCheckin = '/event/:slug/checkin';
  static const eventCheckinHost = '/event/:slug/checkin/host';
  static const eventPoster = '/event/:slug/poster';

  /// J1 QR 스캐너. 탭바 없는 전체화면.
  static const scan = '/scan';

  // ── 마이 ───────────────────────────────────────────────────
  static const meProfile = '/me/profile';
  static const meProfileCareer = '/me/profile/career';
  static const meProfileRecord = '/me/profile/record';
  static const meProfileLink = '/me/profile/link';
  static const meCards = '/me/cards';
  static const meCardsEdit = '/me/cards/edit';
  static const meNotifications = '/me/notifications';
  static const meSettings = '/me/settings';

  // ── 경로 생성 헬퍼 ─────────────────────────────────────────
  static String eventDetailOf(String slug) => '/event/$slug';
  static String eventEditOf(String slug) => '/event/$slug/edit';
  static String eventManageOf(String slug) => '/event/$slug/manage';
  static String eventPeopleOf(String slug) => '/event/$slug/people';
  static String eventPeopleDetailOf(String slug, String userId) =>
      '/event/$slug/people/$userId';
  static String eventCheckinOf(String slug) => '/event/$slug/checkin';
  static String eventCheckinHostOf(String slug) => '/event/$slug/checkin/host';
  static String eventPosterOf(String slug) => '/event/$slug/poster';
}
