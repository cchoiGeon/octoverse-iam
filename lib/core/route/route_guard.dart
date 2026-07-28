import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:iam/service/auth_service.dart';

import 'app_pages.dart';

/// 인증 가드 — `IAM_web/src/lib/services/route-guard.tsx`의 `<RequireAuth>` 대응.
///
/// 웹은 컴포넌트로 감쌌지만 GetX는 미들웨어가 라우팅 단계에서 가로챈다.
/// 화면이 마운트되기 전에 판정하므로 웹에 있던 "첫 프레임 깜빡임" 문제가 없다.
///
/// 사용:
/// ```dart
/// GetPage(
///   name: AppRoutes.meProfile,
///   page: () => const MeProfileView(),
///   binding: MeProfileBinding(),
///   middlewares: [AuthGuard()],
/// )
/// ```
///
/// TODO(route): 보호가 필요한 GetPage에 `middlewares: [AuthGuard()]`를 붙인다.
///   공개 라우트는 랜딩(`/login`)과 모임 상세(`/event/:slug`) 둘뿐이다
///   — 웹 `AppShell.isPublic`과 동일하게 맞춘다.
class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthService>();

    if (!auth.isAuthenticated) {
      return const RouteSettings(name: AppRoutes.login);
    }
    // 로그인은 됐는데 온보딩 미완료 → 프로필부터 만들게 한다.
    if (!auth.hasProfile && route != AppRoutes.onboarding) {
      return const RouteSettings(name: AppRoutes.onboarding);
    }
    return null;
  }
}

/// 주최자 전용 가드 — 웹 `<RequireOrganizer>` 대응.
///
/// ⚠️ 미들웨어 단계에서는 아직 모임 정보를 모른다(slug만 있다).
///    그래서 주최자 판정은 **화면 안에서** 채널 로드 후에 한다.
///    이 클래스는 로그인 여부만 보장하고, 주최자 분기는 Controller가 맡는다.
///    (웹도 `channel.organizer.id !== me.id` 비교를 렌더 시점에 한다.)
class OrganizerGuard extends AuthGuard {}
