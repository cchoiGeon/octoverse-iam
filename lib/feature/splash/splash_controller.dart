import 'dart:async';

import 'package:get/get.dart';

import 'package:iam/core/route/app_pages.dart';
import 'package:iam/service/services.dart';

/// 부팅 · 세션 확인 후 분기.
///
/// 라우트   : AppRoutes.splash
/// 웹 대응  : 없음 — 웹은 `RequireAuth`(RouteGuard)가 렌더 시점에 판정했다.
///           앱은 진입 화면을 따로 두어 스택을 깔끔하게 만든다.
class SplashController extends GetxController {
  SplashController(this._auth, this._reference, this._push);

  final AuthService _auth;
  final ReferenceService _reference;
  final PushService _push;

  /// 로고가 번쩍이고 사라지지 않도록 보장하는 최소 노출 시간.
  static const _minimumHold = Duration(milliseconds: 600);

  @override
  void onReady() {
    super.onReady();
    // onInit이 아니라 onReady — 첫 프레임이 그려진 뒤에 라우팅해야
    // "빌드 중 네비게이션" 경고 없이 안전하게 이동한다.
    _boot();
  }

  Future<void> _boot() async {
    // 세션 확인과 참조 데이터 로드를 동시에 시작하고, 최소 노출 시간까지 함께 기다린다.
    // bootstrap()들은 내부에서 실패를 삼키므로 여기서 try가 필요 없다.
    await Future.wait([
      _auth.bootstrap(),
      _reference.bootstrap(),
      Future<void>.delayed(_minimumHold),
    ]);

    if (!_auth.isAuthenticated) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }
    // 권한이 이미 있으면 토큰을 서버에 다시 등록한다(토큰은 재발급된다).
    // await 하지 않는다 — 스플래시가 네트워크를 기다릴 이유가 없다.
    unawaited(_push.syncToken());
    // 로그인은 됐지만 온보딩 미완료 → 프로필부터 만들게 한다.
    if (!_auth.hasProfile) {
      Get.offAllNamed(AppRoutes.onboarding);
      return;
    }
    Get.offAllNamed(AppRoutes.home);
    // 홈 스택이 자리잡은 뒤에 딥링크를 얹는다. 순서가 뒤바뀌면
    // offAllNamed 가 딥링크 목적지를 지운다.
    await _push.handleInitialMessage();
  }
}
