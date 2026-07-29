import 'dart:async';

import 'package:get/get.dart';

import 'package:iam/common/constants/defines.dart';
import 'package:iam/core/route/app_pages.dart';
import 'package:iam/service/services.dart';

/// 어떤 버튼이 진행 중인지 — 두 버튼을 동시에 못 누르게 한다.
enum LoginBusy { none, kakao, dev }

/// 01 랜딩 · 카카오 로그인.
///
/// 라우트   : AppRoutes.login
/// 웹 대응  : `IAM_web/src/app/(app)/page.tsx`의 `<Landing>`
///
/// 카카오 네이티브 키가 없으면(`kUseTestLogin`) 카카오 버튼도 테스트 로그인으로
/// 폴백한다 — 키 발급 전에도 서버 연동을 확인할 수 있게.
class LoginController extends GetxController {
  LoginController(this._auth, this._toast, this._push);

  final AuthService _auth;
  final ToastService _toast;
  final PushService _push;

  final Rx<LoginBusy> busy = LoginBusy.none.obs;

  bool get isBusy => busy.value != LoginBusy.none;

  /// 카카오 키가 없으면 버튼 라벨·동작을 개발 로그인으로 바꾼다.
  bool get usesTestLogin => kUseTestLogin;

  Future<void> loginWithKakao() async {
    if (isBusy) return;
    busy.value = LoginBusy.kakao;
    await _run(
      () => usesTestLogin ? _auth.loginForDev() : _auth.loginWithKakao(),
    );
  }

  /// "신규 회원으로 둘러보기" — 매번 새 이메일이라 항상 새 계정이 만들어진다.
  Future<void> loginAsNewUser() async {
    if (isBusy) return;
    busy.value = LoginBusy.dev;
    final email = 'new+${DateTime.now().millisecondsSinceEpoch}@iam.app';
    await _run(() => _auth.loginForDev(email: email));
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
