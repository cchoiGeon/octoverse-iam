import 'package:flutter/services.dart' show PlatformException;
import 'package:get/get.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'package:iam/common/constants/defines.dart';
import 'package:iam/core/network/api_client.dart';
import 'package:iam/core/network/api_error.dart';
import 'package:iam/data/data_manager.dart';

/// 세션 생애주기 소유자 — `IAM_web/src/lib/services/auth.tsx` 이식.
///
/// 앱 전역에서 "지금 누가 로그인했나"의 단일 원천이다.
/// `main.dart`에서 `Get.put(AuthService(...), permanent: true)`로 등록한다.
///
/// **웹과의 차이**
/// - 웹: 카카오 authorize 리다이렉트 → 서버가 콜백 소유 → HttpOnly 쿠키
/// - 앱: 카카오 네이티브 SDK로 id_token 획득 → `POST /auth/oauth/kakao` → Bearer 토큰
///   계약(REST §1.1)은 같고 토큰을 얻는 경로만 다르다.
class AuthService extends GetxService {
  AuthService(this._api);

  final ApiClient _api;

  /// 로그인한 계정. null = 비로그인.
  final Rxn<Me> me = Rxn<Me>();

  /// 세션 부트스트랩 진행 중 여부. 스플래시가 이 값을 기다린다.
  final RxBool isBooting = true.obs;

  bool get isAuthenticated => me.value != null;

  /// 온보딩 완료 여부. false면 `/onboarding`으로 보낸다.
  bool get hasProfile => me.value?.profile != null;

  String? get myId => me.value?.id;

  /// 이 유저가 해당 모임의 주최자인가. 👑 가드·어포던스에 쓴다.
  bool isOrganizer(String organizerId) => myId != null && myId == organizerId;

  /// 앱 시작 시 1회. 저장된 토큰으로 `/users/me`를 찔러 세션을 확인한다.
  /// 200이면 로그인, 401이면 비로그인(인터셉터가 토큰을 정리한다).
  Future<void> bootstrap() async {
    if (!Storage.hasSession) {
      isBooting.value = false;
      return;
    }
    try {
      me.value = await _api.me();
    } catch (_) {
      await Storage.clearSession();
      me.value = null;
    } finally {
      isBooting.value = false;
    }
  }

  /// 카카오 로그인.
  ///
  /// 카카오톡 앱이 있으면 앱으로, 없으면 카카오 계정(웹뷰)으로 로그인한다.
  /// 받은 OIDC `id_token`을 서버에 보내 세션을 받는다(REST §1.1).
  ///
  /// ⚠️ `idToken`이 내려오려면 **카카오 콘솔에서 OIDC를 활성화**해야 한다.
  ///    비활성 상태면 null이 와서 아래 예외로 떨어진다.
  Future<LoginResult> loginWithKakao() async {
    final token = await _obtainKakaoToken();
    final idToken = token.idToken;
    if (idToken == null) {
      throw const ApiError(
        'INVALID_PROVIDER_TOKEN',
        '카카오 OIDC가 꺼져 있어 id_token을 받지 못했어요.',
        400,
      );
    }
    return loginWithIdToken(idToken, provider: AuthProvider.kakao);
  }

  Future<OAuthToken> _obtainKakaoToken() async {
    if (!await isKakaoTalkInstalled()) {
      return UserApi.instance.loginWithKakaoAccount();
    }
    try {
      return await UserApi.instance.loginWithKakaoTalk();
    } on PlatformException catch (e) {
      // 사용자가 카카오톡 로그인 화면에서 직접 취소한 경우는 그대로 올린다.
      // 계정 로그인으로 넘기면 취소했는데 또 창이 뜨는 것처럼 보인다.
      if (e.code == 'CANCELED') rethrow;
      // 그 외(카톡 버전 낮음 등)는 계정 로그인으로 폴백.
      return UserApi.instance.loginWithKakaoAccount();
    }
  }

  /// OIDC id_token으로 서버 세션 발급 (REST §1.1).
  Future<LoginResult> loginWithIdToken(
    String idToken, {
    AuthProvider provider = AuthProvider.kakao,
    String? email,
  }) async {
    final res = await _api.oauthLogin(
      provider.path,
      OAuthLoginRequest(idToken: idToken, email: email),
    );
    return _establish(res);
  }

  /// 개발용 로그인 (REST §1.7). 카카오 키가 없을 때 진입 경로.
  /// 같은 email = 같은 유저.
  Future<LoginResult> loginForDev({String email = kDevEmail}) async {
    final res = await _api.testLogin(TestLoginRequest(email: email));
    return _establish(res);
  }

  /// 토큰 저장 + `/me` 재조회 후 온보딩 분기 정보를 돌려준다.
  Future<LoginResult> _establish(OAuthLoginResponse res) async {
    await Storage.saveSession(
      access: res.accessToken,
      refresh: res.refreshToken,
    );
    me.value = await _api.me();
    return LoginResult(
      isNewUser: res.isNewUser,
      hasProfile: res.user.hasProfile,
    );
  }

  /// 약관 동의 · 가입 완료 (REST §1.2).
  /// 이미 가입된 계정이면 `ALREADY_SIGNED_UP` — 호출부가 설정 갱신으로 우회한다.
  Future<void> signup(SignupRequest payload) async {
    await _api.signup(payload);
    me.value = await _api.me();
  }

  /// 프로필 변경 후 `me`를 갱신한다.
  /// 웹의 `qc.invalidateQueries({ queryKey: qk.me() })`에 대응한다.
  Future<void> refreshMe() async {
    if (!Storage.hasSession) return;
    try {
      me.value = await _api.me();
    } on Object catch (e) {
      if (ApiError.from(e).status == 401) await signOutLocal();
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {
      // best-effort — 서버가 실패해도 로컬 세션은 반드시 지운다.
    }
    await signOutLocal();
  }

  Future<void> withdraw() async {
    // 진행 중인 주최 모임이 있으면 서버가 `ACTIVE_ORGANIZER`로 거절한다.
    await _api.withdraw();
    await signOutLocal();
  }

  /// 로컬 세션만 정리. 401 인터셉터도 이 경로를 탄다.
  Future<void> signOutLocal() async {
    await Storage.clearSession();
    me.value = null;
  }
}

/// 로그인 직후 어디로 보낼지 결정하는 데 필요한 정보.
class LoginResult {
  const LoginResult({required this.isNewUser, required this.hasProfile});

  final bool isNewUser;
  final bool hasProfile;

  /// true면 `/onboarding`으로.
  bool get needsOnboarding => isNewUser || !hasProfile;
}
