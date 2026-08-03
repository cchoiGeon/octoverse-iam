import 'dart:async';

import 'package:get/get.dart';

import 'package:iam/core/route/app_pages.dart';
import 'package:iam/service/services.dart';

/// 어떤 버튼이 진행 중인지.
enum LoginBusy { none, kakao }

/// 01 랜딩 · 카카오 로그인.
///
/// 라우트   : AppRoutes.login
/// 웹 대응  : `IAM_web/src/app/(app)/page.tsx`의 `<Landing>`
///
/// 진입 경로는 카카오 로그인 하나뿐이다. 개발용 로그인
/// (`POST /auth/test/login`)은 이메일만으로 세션이 나오는 인증 우회라
/// 제거했다 — 클라이언트에서 가려도 엔드포인트는 열려 있으므로,
/// 실제 차단은 서버에서 라우트를 내려야 완료된다.
class LoginController extends GetxController {
  LoginController(this._auth, this._toast, this._push);

  final AuthService _auth;
  final ToastService _toast;
  final PushService _push;

  final Rx<LoginBusy> busy = LoginBusy.none.obs;

  bool get isBusy => busy.value != LoginBusy.none;

  Future<void> loginWithKakao() async {
    if (isBusy) return;
    busy.value = LoginBusy.kakao;
    await _run(_auth.loginWithKakao);
  }

  Future<void> _run(Future<LoginResult> Function() action) async {
    try {
      final result = await action();
      // 이미 권한이 있는 재로그인 유저의 토큰을 갱신한다.
      // 최초 가입자는 온보딩 끝에서 권한 요청과 함께 등록된다.
      unawaited(_push.syncToken());
      // 온보딩 여부로 갈라 보낸다. offAllNamed — 뒤로가기로 랜딩에 못 돌아오게.
      Get.offAllNamed(
        result.needsOnboarding ? AppRoutes.onboarding : AppRoutes.home,
      );
    } catch (e) {
      _toast.showError(e);
    } finally {
      busy.value = LoginBusy.none;
    }
  }
}
