import 'package:get/get.dart';

// ── 진입 ───────────────────────────────────────────────────────
import 'package:iam/feature/splash/binding.dart';
import 'package:iam/feature/splash/splash_view.dart';
import 'package:iam/feature/login/binding.dart';
import 'package:iam/feature/login/login_view.dart';
import 'package:iam/feature/onboarding/binding.dart';
import 'package:iam/feature/onboarding/onboarding_view.dart';

// ── 홈 · 스캔 ──────────────────────────────────────────────────
import 'package:iam/feature/home/binding.dart';
import 'package:iam/feature/home/home_view.dart';
import 'package:iam/feature/scan/binding.dart';
import 'package:iam/feature/scan/scan_view.dart';

// ── 모임 ───────────────────────────────────────────────────────
import 'package:iam/feature/event/new/binding.dart';
import 'package:iam/feature/event/new/event_new_view.dart';
import 'package:iam/feature/event/detail/binding.dart';
import 'package:iam/feature/event/detail/event_detail_view.dart';
import 'package:iam/feature/event/edit/binding.dart';
import 'package:iam/feature/event/edit/event_edit_view.dart';
import 'package:iam/feature/event/manage/binding.dart';
import 'package:iam/feature/event/manage/event_manage_view.dart';
import 'package:iam/feature/event/people/binding.dart';
import 'package:iam/feature/event/people/event_people_view.dart';
import 'package:iam/feature/event/people_detail/binding.dart';
import 'package:iam/feature/event/people_detail/event_people_detail_view.dart';
import 'package:iam/feature/event/checkin/binding.dart';
import 'package:iam/feature/event/checkin/event_checkin_view.dart';
import 'package:iam/feature/event/checkin_host/binding.dart';
import 'package:iam/feature/event/checkin_host/event_checkin_host_view.dart';
import 'package:iam/feature/event/poster/binding.dart';
import 'package:iam/feature/event/poster/event_poster_view.dart';

// ── 마이 ───────────────────────────────────────────────────────
import 'package:iam/feature/me/dashboard/binding.dart';
import 'package:iam/feature/me/dashboard/me_dashboard_view.dart';
import 'package:iam/feature/me/profile/binding.dart';
import 'package:iam/feature/me/profile/me_profile_view.dart';
import 'package:iam/feature/me/profile_career/binding.dart';
import 'package:iam/feature/me/profile_career/me_profile_career_view.dart';
import 'package:iam/feature/me/profile_record/binding.dart';
import 'package:iam/feature/me/profile_record/me_profile_record_view.dart';
import 'package:iam/feature/me/profile_link/binding.dart';
import 'package:iam/feature/me/profile_link/me_profile_link_view.dart';
import 'package:iam/feature/me/cards/binding.dart';
import 'package:iam/feature/me/cards/me_cards_view.dart';
import 'package:iam/feature/me/cards_edit/binding.dart';
import 'package:iam/feature/me/cards_edit/me_cards_edit_view.dart';
import 'package:iam/feature/me/likes/binding.dart';
import 'package:iam/feature/me/likes/me_likes_view.dart';
import 'package:iam/feature/me/meetings/binding.dart';
import 'package:iam/feature/me/meetings/me_meetings_view.dart';
import 'package:iam/feature/me/notifications/binding.dart';
import 'package:iam/feature/me/notifications/me_notifications_view.dart';
import 'package:iam/feature/me/settings/binding.dart';
import 'package:iam/feature/me/settings/me_settings_view.dart';

part 'app_routes.dart';

/// 라우트 테이블 — 웹의 `app/**/page.tsx` 파일 라우팅에 대응한다.
///
/// 각 항목의 `binding`이 그 화면의 Controller를 DI에 등록한다.
/// 웹의 route group `(app)`/`(auth)`처럼 **화면 단위 스코프**를 만드는 장치다.
abstract final class AppPages {
  static final List<GetPage> pages = [
    // ── 진입 ─────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.onboarding,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
    ),

    // ── 메인 탭 ──────────────────────────────────────────────
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: AppRoutes.meMeetings,
      page: () => const MeMeetingsView(),
      binding: MeMeetingsBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: AppRoutes.meLikes,
      page: () => const MeLikesView(),
      binding: MeLikesBinding(),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: AppRoutes.me,
      page: () => const MeDashboardView(),
      binding: MeDashboardBinding(),
      transition: Transition.noTransition,
    ),

    // ── 스캔 (탭바 없음 · 전체화면) ──────────────────────────
    GetPage(
      name: AppRoutes.scan,
      page: () => const ScanView(),
      binding: ScanBinding(),
      fullscreenDialog: true,
    ),

    // ── 모임 ─────────────────────────────────────────────────
    // ⚠️ 순서 주의: 리터럴 경로(`/event/new`)를 파라미터 경로(`/event/:slug`)보다
    //    먼저 등록한다. 뒤에 두면 `new`가 slug로 잡힌다.
    GetPage(
      name: AppRoutes.eventNew,
      page: () => const EventNewView(),
      binding: EventNewBinding(),
    ),
    // 하위 경로(edit/manage/people/checkin/poster)도 `/event/:slug`보다 먼저 둔다.
    GetPage(
      name: AppRoutes.eventEdit,
      page: () => const EventEditView(),
      binding: EventEditBinding(),
    ),
    GetPage(
      name: AppRoutes.eventManage,
      page: () => const EventManageView(),
      binding: EventManageBinding(),
    ),
    GetPage(
      name: AppRoutes.eventPeopleDetail,
      page: () => const EventPeopleDetailView(),
      binding: EventPeopleDetailBinding(),
    ),
    GetPage(
      name: AppRoutes.eventPeople,
      page: () => const EventPeopleView(),
      binding: EventPeopleBinding(),
    ),
    GetPage(
      name: AppRoutes.eventCheckinHost,
      page: () => const EventCheckinHostView(),
      binding: EventCheckinHostBinding(),
    ),
    GetPage(
      name: AppRoutes.eventCheckin,
      page: () => const EventCheckinView(),
      binding: EventCheckinBinding(),
    ),
    GetPage(
      name: AppRoutes.eventPoster,
      page: () => const EventPosterView(),
      binding: EventPosterBinding(),
    ),
    GetPage(
      name: AppRoutes.eventDetail,
      page: () => const EventDetailView(),
      binding: EventDetailBinding(),
    ),

    // ── 마이 하위 ────────────────────────────────────────────
    GetPage(
      name: AppRoutes.meProfileCareer,
      page: () => const MeProfileCareerView(),
      binding: MeProfileCareerBinding(),
    ),
    GetPage(
      name: AppRoutes.meProfileRecord,
      page: () => const MeProfileRecordView(),
      binding: MeProfileRecordBinding(),
    ),
    GetPage(
      name: AppRoutes.meProfileLink,
      page: () => const MeProfileLinkView(),
      binding: MeProfileLinkBinding(),
    ),
    GetPage(
      name: AppRoutes.meProfile,
      page: () => const MeProfileView(),
      binding: MeProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.meCardsEdit,
      page: () => const MeCardsEditView(),
      binding: MeCardsEditBinding(),
    ),
    GetPage(
      name: AppRoutes.meCards,
      page: () => const MeCardsView(),
      binding: MeCardsBinding(),
    ),
    GetPage(
      name: AppRoutes.meNotifications,
      page: () => const MeNotificationsView(),
      binding: MeNotificationsBinding(),
    ),
    GetPage(
      name: AppRoutes.meSettings,
      page: () => const MeSettingsView(),
      binding: MeSettingsBinding(),
    ),
  ];
}
