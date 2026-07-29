import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/data/data_manager.dart';

/// FCM 토큰 수명주기 소유자.
///
/// 앱에서 Firebase 를 아는 유일한 곳이다. 다른 코드는 아래 세 메서드만 안다.
///
/// **`syncToken()` 과 `requestPermissionAndRegister()` 를 나눈 이유**
/// 재로그인한 유저에게 권한 팝업을 다시 띄우면 안 되지만, 토큰 자체는 매번
/// 등록돼야 한다. FCM 토큰은 앱 재설치·데이터 삭제·장기 미사용으로 바뀐다.
class PushService extends GetxService {
  PushService(this._api);

  final ApiClient _api;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  StreamSubscription<String>? _refreshSub;

  /// 서버에 등록해둔 토큰. 로그아웃 시 이 값으로 DELETE 한다.
  String? _registered;

  @override
  void onInit() {
    super.onInit();
    // 토큰은 예고 없이 재발급된다. 갱신되면 서버 것도 바꿔줘야
    // 이전 토큰으로 가던 푸시가 끊기지 않는다.
    _refreshSub = _fcm.onTokenRefresh.listen(_register);
  }

  @override
  void onClose() {
    _refreshSub?.cancel();
    super.onClose();
  }

  /// 권한이 **이미** 있으면 토큰을 서버에 등록한다. 없으면 아무것도 하지 않는다.
  /// 스플래시 부팅·로그인 성공 직후에 부른다.
  Future<void> syncToken() async {
    final settings = await _fcm.getNotificationSettings();
    if (settings.authorizationStatus != AuthorizationStatus.authorized) return;
    await _issueAndRegister();
  }

  /// OS 권한 팝업을 띄우고, 승인되면 등록한다.
  /// 거부는 조용히 넘어간다 — 재촉하지 않는다.
  Future<void> requestPermissionAndRegister() async {
    final settings = await _fcm.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized) return;
    await _issueAndRegister();
  }

  /// 로그아웃 — 서버에서 이 기기를 떼고 로컬 토큰도 버린다.
  ///
  /// ⚠️ `Storage.clearSession()` **전에** 불려야 DELETE 에 Bearer 가 실린다.
  ///    `AuthService.onBeforeSignOut` 이 그 순서를 보장한다.
  Future<void> unregister() async {
    final token = _registered;
    _registered = null;

    if (token != null && Storage.hasSession) {
      try {
        await _api.unregisterDevice(token);
      } catch (_) {
        // best-effort. 서버에 레코드가 남아도 아래 deleteToken() 이 FCM 쪽에서
        // 토큰을 무효화하므로, 다음 발송이 UNREGISTERED 를 받아 정리된다.
      }
    }

    try {
      await _fcm.deleteToken();
    } catch (_) {
      // Play 서비스 부재 등. 로그아웃 자체를 막을 이유는 없다.
    }
  }

  Future<void> _issueAndRegister() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) await _register(token);
    } catch (_) {
      // Play 서비스 없음 등 — 다음 실행의 syncToken() 이 재시도한다.
    }
  }

  Future<void> _register(String token) async {
    // ⚠️ 세션이 없으면 부르지 않는다. 401 이 _AuthInterceptor 를 타면
    //    세션 만료로 처리돼 보고 있던 화면에서 로그인으로 튕긴다.
    if (!Storage.hasSession) return;
    try {
      await _api.registerDevice(DeviceRegisterRequest(token: token));
      _registered = token;
    } catch (_) {
      // 푸시는 보조 기능 — 실패해도 화면을 막지 않는다.
      // 다음 앱 실행의 syncToken() 이 재시도한다.
    }
  }
}
