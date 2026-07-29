import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/notification_service.dart';
import 'package:iam/service/push_router.dart';

/// FCM 토큰 수명주기 소유자.
///
/// 앱에서 Firebase 를 아는 유일한 곳이다. 다른 코드는 아래 세 메서드만 안다.
///
/// **`syncToken()` 과 `requestPermissionAndRegister()` 를 나눈 이유**
/// 재로그인한 유저에게 권한 팝업을 다시 띄우면 안 되지만, 토큰 자체는 매번
/// 등록돼야 한다. FCM 토큰은 앱 재설치·데이터 삭제·장기 미사용으로 바뀐다.
class PushService extends GetxService {
  /// AndroidManifest 의 `default_notification_channel_id` 와 같은 값이어야 한다.
  /// 다르면 백그라운드(OS 가 그림)와 포그라운드(우리가 그림) 알림이 서로 다른
  /// 채널로 가서 사용자가 소리·중요도를 따로 꺼야 하는 상태가 된다.
  static const _channelId = 'iam_default';

  PushService(this._api, this._notifications);

  final ApiClient _api;
  final NotificationService _notifications;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _refreshSub;
  StreamSubscription<RemoteMessage>? _messageSub;
  StreamSubscription<RemoteMessage>? _openedSub;

  /// 서버에 등록해둔 토큰. 로그아웃 시 이 값으로 DELETE 한다.
  String? _registered;

  /// 로컬 알림 id. 겹치면 이전 알림을 덮어써서 하나만 남는다.
  int _localId = 0;

  @override
  void onInit() {
    super.onInit();
    // 토큰은 예고 없이 재발급된다. 갱신되면 서버 것도 바꿔줘야
    // 이전 토큰으로 가던 푸시가 끊기지 않는다.
    _refreshSub = _fcm.onTokenRefresh.listen(_register);
    _messageSub = FirebaseMessaging.onMessage.listen(_showForeground);
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(
      (m) => _openRoute(m.data),
    );
    unawaited(_initLocalNotifications());
  }

  @override
  void onClose() {
    _refreshSub?.cancel();
    _messageSub?.cancel();
    _openedSub?.cancel();
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

  // ── 포그라운드 표시 ─────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null) return;
        _openRoute(jsonDecode(payload) as Map<String, dynamic>);
      },
    );

    // 채널은 앱 설치 후 한 번만 만들어지고, 이후 중요도 변경은 무시된다.
    // (사용자가 직접 바꾼 설정을 앱이 덮어쓰지 못하게 하는 Android 정책)
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            '알림',
            description: '모임 리마인더 · 명함 교환 등 IAM 알림',
            importance: Importance.high,
          ),
        );
  }

  /// 앱이 떠 있는 동안 도착한 푸시.
  ///
  /// Android 는 이 경우 시스템 배너를 자동으로 띄우지 않는다. 직접 그리고,
  /// 벨 배지가 같이 오르도록 알림 목록도 다시 불러온다.
  void _showForeground(RemoteMessage message) {
    unawaited(_notifications.load());

    final notification = message.notification;
    if (notification == null) return;

    _local.show(
      id: _localId++,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          '알림',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      // 탭했을 때 어디로 갈지는 data 에 들어 있다. payload 는 String 만
      // 받으므로 JSON 으로 실어 보낸다.
      payload: jsonEncode(message.data),
    );
  }

  // ── 탭 → 화면 이동 ──────────────────────────────────────────

  void _openRoute(Map<String, dynamic> data) {
    // 비로그인 상태의 딥링크는 버린다 — RouteGuard 가 막고, 로그인 후
    // 원래 목적지로 복원하는 기능은 아직 없다.
    if (!Storage.hasSession) return;
    Get.toNamed(routeForPush(data));
  }

  /// 앱이 **완전히 종료된** 상태에서 푸시를 탭해 실행된 경우의 진입점.
  ///
  /// ⚠️ 반드시 스플래시가 목적지 라우팅(`Get.offAllNamed`)을 **끝낸 뒤**에
  ///    불러야 한다. 먼저 부르면 뒤이은 offAllNamed 가 딥링크 목적지를
  ///    지워버린다. 이게 이 기능에서 가장 실수하기 쉬운 지점이다.
  ///
  /// `offAllNamed` 가 아니라 `toNamed` 로 쌓는 이유는, 뒤로가기로 홈에
  /// 돌아올 수 있어야 하기 때문이다(`_openRoute` 참고).
  Future<void> handleInitialMessage() async {
    try {
      final message = await _fcm.getInitialMessage();
      if (message == null) return;
      _openRoute(message.data);
    } catch (_) {
      // 딥링크 실패는 삼킨다 — 이 시점에 유저는 이미 홈에 도착해 있어서
      // 화면이 비지 않는다. Play 서비스 부재 등으로 죽을 이유가 없다.
    }
  }
}
