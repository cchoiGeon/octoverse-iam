import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:iam/service/auth_service.dart';

import 'app_pages.dart';

/// 인증 가드 — `IAM_web/src/lib/services/route-guard.tsx`의 `<RequireAuth>` 대응.
///
/// 웹은 컴포넌트로 감쌌지만 GetX는 미들웨어가 라우팅 단계에서 가로챈다.
/// 화면이 마운트되기 전에 판정하므로 웹에 있던 "첫 프레임 깜빡임" 문제가 없다.
///
/// 부착 지점은 `AppPages._guarded` 하나로 모아 두었다. 공개 라우트는 랜딩
/// (`/login`)·모임 상세(`/event/:slug`)와, 세션 확인 전에 뜨는 `/splash`뿐이다
/// — 웹 `AppShell.isPublic`과 같은 기준이다.
///
/// 이 가드가 실제로 일하는 곳은 **푸시 딥링크**다. 일반 흐름에서는 스플래시가
/// 이미 분기를 마쳤지만, 알림을 탭해 보호 화면으로 곧장 들어오는 경로에는
/// 스플래시가 없다.
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

/// 주최자 가드는 미들웨어로 만들 수 없다.
///
/// 이 단계에서는 아직 모임 정보를 모르고 slug만 있어서, 주최자인지 알려면
/// 채널을 불러와야 한다. 그래서 판정은 **화면 안에서** 한다 — 각 Controller가
/// `isOrganizer`를 노출하고 View가 그것으로 갈린다
/// (`event/manage` · `event/checkin_host` · `event/edit` · `event/poster`).
/// 웹도 `<RequireOrganizer>`가 `channel.organizer.id !== me.id`를 렌더 시점에 본다.
