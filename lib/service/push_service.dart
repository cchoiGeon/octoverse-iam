import 'dart:async';
import 'dart:convert';

import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/service/notification_service.dart';
import 'package:iam/service/push_router.dart';

/// 로컬 알림 id 를 Android 가 받아주는 범위로 접는다.
///
/// `flutter_local_notifications` 는 id 가 **32비트 정수**에 들어가지 않으면
/// `show()` 자체를 거부한다. epoch ms(1.7e12)를 그대로 넘기면 배너가 단 한 번도
/// 뜨지 않는데, 이 파일은 실패를 삼키도록 되어 있어서 **아무 증상 없이 조용히**
/// 안 뜬다. 실제로 그렇게 한 번 놓친 적이 있어서 순수 함수로 떼어내 테스트한다.
///
/// 상한을 2^31-1 이 아니라 2^30 으로 잡은 이유는, 시드 이후 `+1` 이 반복돼도
/// 경계를 넘지 않도록 여유를 두기 위해서다.
int notificationId(int seed) => seed.abs() % (1 << 30);

/// FCM 토큰 수명주기 소유자.
///
/// 앱에서 Firebase 를 아는 유일한 곳이다. 다른 코드는 아래 세 메서드만 안다.
///
/// **`syncToken()` 과 `requestPermissionAndRegister()` 를 나눈 이유**
/// 재로그인한 유저에게 권한 팝업을 다시 띄우면 안 되지만, 토큰 자체는 매번
/// 등록돼야 한다. FCM 토큰은 앱 재설치·데이터 삭제·장기 미사용으로 바뀐다.
class PushService extends GetxService with WidgetsBindingObserver {
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

  /// `unregister()` 진행 중 표시.
  ///
  /// `onBeforeSignOut` 훅이 도는 동안(= `Storage.hasSession`이 아직 true인
  /// 동안) `onTokenRefresh`가 새 토큰을 쏘면, 그 토큰이 `_register`의
  /// `hasSession` 가드를 그대로 통과해 방금 로그아웃한 계정의 Bearer로 다시
  /// 등록돼버린다. `deleteToken()` 자체도 재발급을 유발할 수 있는 호출이라
  /// 이 창 "안"에 있다. 로그아웃이 끝날 때까지 등록을 막아야 한다.
  bool _signingOut = false;

  /// 로컬 알림 id. 겹치면 이전 알림을 덮어써서 하나만 남는다.
  /// 0부터 시작하면 새 세션의 배너가 지난 실행에서 트레이에 남아 있던
  /// 알림과 id가 겹쳐 그걸 덮어써버릴 수 있다. 시계값으로 시작해 피한다.
  ///
  /// ⚠️ epoch ms 를 그대로 쓰면 안 된다 — `flutter_local_notifications` 는
  ///    id 가 **32비트 정수**에 들어가야 하고, epoch ms(1.7e12)는 이를 넘어
  ///    `show()` 가 통째로 실패한다. `notificationId()` 가 접어 넣는다.
  int _localId = notificationId(DateTime.now().millisecondsSinceEpoch);

  /// OS 알림 권한 보유 여부. 설정 화면이 이 값을 그린다.
  ///
  /// 권한은 앱 밖(OS 설정)에서도 바뀌므로 이 값 하나를 진실로 두고
  /// `resumed` 마다 다시 읽는다 — 설정에서 켜고 돌아오면 바로 반영된다.
  final RxBool isAuthorized = false.obs;

  /// `_initLocalNotifications()`의 진행 상태.
  ///
  /// `onInit`에서 fire-and-forget으로 시작하기 때문에, `initialize()`가
  /// 끝나기 전에 푸시가 도착하면 `_showForeground`가 아직 준비 안 된
  /// 플러그인의 `show()`를 부를 수 있다. 이 Future를 들고 있다가
  /// `_showForeground`에서 먼저 기다린다.
  Future<void>? _localReady;

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
    _localReady = _initLocalNotifications();
    WidgetsBinding.instance.addObserver(this);
    unawaited(refreshAuthorization());
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshSub?.cancel();
    _messageSub?.cancel();
    _openedSub?.cancel();
    super.onClose();
  }

  /// 백그라운드에 있는 동안 도착한 푸시를 복귀 시점에 배지로 반영한다.
  ///
  /// `FirebaseMessaging.onMessage` 는 **포그라운드 전용**이다. 앱이 내려가 있는
  /// 동안 온 알림은 OS 가 트레이에 그리고 앱은 듣지 못하므로, 돌아왔을 때
  /// 한 번 당겨오지 않으면 배너는 봤는데 벨 배지는 0인 상태가 된다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) return;
    unawaited(_notifications.load());
    unawaited(_syncAuthorizationOnResume());
  }

  /// 권한은 앱 밖(OS 설정)에서도 바뀐다. 복귀할 때마다 다시 읽어 설정 화면이
  /// 맞는 값을 그리게 한다.
  ///
  /// 등록은 **권한이 없다가 생긴 순간에만** 한다. 복귀 때마다 무조건
  /// `syncToken()` 을 부르면 포그라운드 전환마다 POST /users/me/devices 가
  /// 나간다 — `_register` 에는 같은 토큰을 거르는 가드가 없다.
  Future<void> _syncAuthorizationOnResume() async {
    final was = isAuthorized.value;
    final now = await refreshAuthorization();
    if (now && !was) await _issueAndRegister();
  }

  /// 권한이 **이미** 있으면 토큰을 서버에 등록한다. 없으면 아무것도 하지 않는다.
  /// 스플래시 부팅·로그인 성공 직후에 부른다.
  Future<void> syncToken() async {
    if (!await refreshAuthorization()) return;
    await _issueAndRegister();
  }

  /// OS 권한 팝업을 띄우고, 승인되면 등록한다.
  /// 거부는 조용히 넘어간다 — 재촉하지 않는다.
  Future<void> requestPermissionAndRegister() async {
    await enable();
  }

  /// 현재 OS 알림 권한 상태를 다시 읽어 [isAuthorized] 에 반영한다.
  Future<bool> refreshAuthorization() async {
    final settings = await _fcm.getNotificationSettings();
    final ok = settings.authorizationStatus == AuthorizationStatus.authorized;
    isAuthorized.value = ok;
    return ok;
  }

  /// 권한을 요청하고, 승인되면 토큰까지 등록한다. 승인 여부를 돌려준다.
  ///
  /// ⚠️ 이미 영구 거절한 유저에게는 **팝업이 뜨지 않고** 곧바로 denied 가
  ///    돌아온다. 호출한 쪽은 false 를 받으면 [openOsNotificationSettings] 로
  ///    안내해야 한다 — 아니면 눌러도 아무 일이 없는 버튼이 된다.
  Future<bool> enable() async {
    final settings = await _fcm.requestPermission();
    final ok = settings.authorizationStatus == AuthorizationStatus.authorized;
    isAuthorized.value = ok;
    if (ok) await _issueAndRegister();
    return ok;
  }

  /// OS 의 이 앱 알림 설정 화면을 연다.
  ///
  /// 끄는 경로이기도 하다 — 서버 `settings` 에 `push_notification_enabled` 가
  /// 없어서 앱 안에서 끌 방법이 없다(README '남은 빚').
  Future<void> openOsNotificationSettings() =>
      AppSettings.openAppSettings(type: AppSettingsType.notification);

  /// 로그아웃 — 서버에서 이 기기를 떼고 로컬 토큰도 버린다.
  ///
  /// ⚠️ `Storage.clearSession()` **전에** 불려야 DELETE 에 Bearer 가 실린다.
  ///    `AuthService.onBeforeSignOut` 이 그 순서를 보장한다.
  Future<void> unregister() async {
    // finally 로 반드시 풀어준다 — 중간에 던져도 다음 로그인의 등록이
    // 영영 막히면 안 된다.
    _signingOut = true;
    try {
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
    } finally {
      _signingOut = false;
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
    // ⚠️ 로그아웃 진행 중이면 부르지 않는다. unregister() 가 도는 동안은
    //    Storage.hasSession 이 아직 true 라 아래 가드만으로는 못 막는다 —
    //    onTokenRefresh 가 이 창에서 새 토큰을 쏘면 방금 로그아웃한
    //    계정으로 재등록될 수 있다.
    if (_signingOut) return;
    // ⚠️ 세션이 없으면 부르지 않는다. 401 이 _AuthInterceptor 를 타면
    //    세션 만료로 처리돼 보고 있던 화면에서 로그인으로 튕긴다.
    if (!Storage.hasSession) return;
    // 같은 토큰을 다시 올릴 이유가 없다. 복귀·재조회 경로가 여럿이라
    // 가드가 없으면 같은 값으로 POST 가 반복된다.
    if (_registered == token) return;
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
  Future<void> _showForeground(RemoteMessage message) async {
    // 배지 갱신은 배너 표시와 무관하게 진행한다 — 아래가 실패하거나
    // 늦어져도 벨 배지는 제때 올라야 한다.
    unawaited(_notifications.load());

    final notification = message.notification;
    if (notification == null) return;

    try {
      // onInit 은 초기화를 기다리지 않고 바로 리턴한다. initialize() 가
      // 끝나기 전에 푸시가 도착하면 플러그인이 아직 준비 안 된 상태라
      // show() 가 예외를 던진다.
      await _localReady;
      await _local.show(
        id: _localId = notificationId(_localId + 1),
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
    } catch (_) {
      // 이 파일의 방침대로 삼킨다 — 배너 하나 못 띄운다고 화면을 막지 않는다.
      // 벨 배지는 위에서 이미 갱신을 시작했으므로 사용자는 알림함에서 확인할 수 있다.
    }
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
      if (message != null) {
        _openRoute(message.data);
        return;
      }

      // 포그라운드 배너는 FCM 이 아니라 flutter_local_notifications 가
      // 그린다. 그 배너가 트레이에 남아 있는 채로 앱이 완전히 종료됐다가
      // 그 배너를 탭해 실행되면, onDidReceiveNotificationResponse 도
      // 안 불리고(플러그인이 아직 리스너를 못 붙인 시점) getInitialMessage()
      // 도 null 이다(OS 가 이 알림을 FCM 을 거쳐 그린 게 아니라서 FCM 은
      // 이 실행을 모른다). 로컬 플러그인 쪽 "이 알림으로 실행됐는가"를
      // 대신 물어봐야 딥링크를 못 잃는다.
      final launch = await _local.getNotificationAppLaunchDetails();
      if (launch == null || !launch.didNotificationLaunchApp) return;
      final payload = launch.notificationResponse?.payload;
      if (payload == null) return;
      _openRoute(jsonDecode(payload) as Map<String, dynamic>);
    } catch (_) {
      // 딥링크 실패는 삼킨다 — 이 시점에 유저는 이미 홈에 도착해 있어서
      // 화면이 비지 않는다. Play 서비스 부재 등으로 죽을 이유가 없다.
    }
  }
}
