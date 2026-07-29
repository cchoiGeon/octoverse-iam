# FCM 푸시 알림 (Android) 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Android 앱이 FCM 토큰을 서버에 등록하고, 포그라운드·백그라운드·종료 상태에서 푸시를 받아 알맞은 화면으로 이동한다.

**Architecture:** FCM 관련 부수효과를 `PushService`(GetxService) 하나가 전부 소유한다. "어느 알림이 어느 화면으로 가는가"만 `push_router.dart`의 순수 함수로 떼어내 Firebase 없이 단위 테스트한다. 서버가 `notification` 블록을 보내므로 백그라운드 표시는 OS가 전담하고, 앱은 포그라운드 표시와 탭 라우팅만 책임진다.

**Tech Stack:** Flutter 3.44.8 / Dart 3.12.2, GetX, Retrofit + Dio, `firebase_core`, `firebase_messaging`, `flutter_local_notifications`

**설계 스펙:** [`docs/superpowers/specs/2026-07-29-fcm-push-design.md`](../specs/2026-07-29-fcm-push-design.md)
**서버 요청사항:** [`docs/server-requirements-fcm.md`](../../server-requirements-fcm.md)

---

## Global Constraints

- **Android 전용.** iOS 관련 설정 파일·코드를 만들지 않는다.
- **디바이스 API(`registerDevice` / `unregisterDevice`)는 `Storage.hasSession`이 true일 때만 호출한다.** `_AuthInterceptor`(`lib/core/network/dio_configuration.dart`)가 401을 받으면 세션을 지우고 `AuthInterceptorHooks.onSessionExpired`를 쏜다 → 사용자가 보던 화면에서 로그인으로 튕기고, `unregister()`의 경우 훅이 다시 `unregister()`를 불러 무한 루프가 된다.
- **푸시 실패는 전부 삼킨다.** 토큰 발급·등록·해제가 실패해도 토스트를 띄우거나 화면을 막지 않는다. `NotificationService`의 기존 방침과 동일하다.
- **`Get.put(..., permanent: true)`** 로 등록한다. 등록 순서가 곧 의존성 순서다.
- **주석·문서는 한국어.** 기존 코드처럼 "왜"를 적는다. 무엇을 하는지는 코드가 말한다.
- **모델은 `@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)`.** 서버 계약은 snake_case, id는 string이다.
- **코드 생성 명령:** `dart run build_runner build --delete-conflicting-outputs`
- **테스트 파일은 `test/` 바로 아래 평평하게** 둔다 (`test/datetime_utils_test.dart` 등 기존 관례).
- **`ApiClient`의 `@RestApi()`에 baseUrl을 주지 않는다.** 주면 `--dart-define=API_BASE`가 조용히 무시된다 (`api_client.dart` 상단 주석 참고).
- **커밋 메시지는 한국어**, 기존 관례(`feat(scope): ...`, `fix(scope): ...`) 를 따른다.
- 작업 브랜치: `feat/fcm-push`

---

## 사전 준비 (사람이 해야 함 — Task 1 전에 완료되어야 함)

- [ ] 서버팀에 **`docs/server-requirements-fcm.md`** 전달
- [ ] **서버가 쓰는 Firebase 프로젝트 ID 확인.** 앱과 서버가 다른 프로젝트면 발송이 에러 없이 조용히 실패한다
- [ ] 그 프로젝트에 Android 앱 추가 — 패키지명 **`kr.octoverse.iam`**
- [ ] `google-services.json` 다운로드 → **`android/app/google-services.json`** 에 배치

이 파일이 없으면 Task 1의 빌드가 `File google-services.json is missing`으로 실패한다.

---

## File Structure

| 파일 | 책임 |
|---|---|
| `lib/service/push_router.dart` (신규) | FCM data payload → 라우트. 순수 함수, Firebase 무의존 |
| `lib/service/push_service.dart` (신규) | 권한 · 토큰 수명주기 · 수신 · 탭 라우팅. FCM 부수효과의 유일한 소유자 |
| `test/push_router_test.dart` (신규) | 라우팅 매핑 전수 검증 |
| `lib/data/enums/social_enums.dart` | `NotificationTypeParse.tryParse()` 추가 |
| `lib/data/models/social_model.dart` | `DeviceRegisterRequest` 추가 |
| `lib/core/network/apis.dart` | `devices` · `device` 경로 상수 |
| `lib/core/network/api_client.dart` | `registerDevice` · `unregisterDevice` |
| `lib/service/services.dart` | `push_service.dart` export |
| `lib/service/auth_service.dart` | `signOutLocal()`에 로그아웃 훅 |
| `lib/main.dart` | Firebase 초기화 + `PushService` 등록 + 훅 배선 |
| `lib/feature/splash/splash_controller.dart` | `syncToken()` + 콜드 스타트 딥링크 |
| `lib/feature/login/login_controller.dart` | 로그인 성공 후 `syncToken()` |
| `lib/feature/onboarding/onboarding_controller.dart` | 온보딩 완료 후 권한 요청 |
| `android/settings.gradle.kts` · `android/app/build.gradle.kts` | google-services 플러그인 |
| `android/app/src/main/AndroidManifest.xml` | `POST_NOTIFICATIONS` + 기본 알림 채널 |

---

## Task 1: Firebase · Gradle 배선 (빌드 통과가 유일한 목표)

이 프로젝트는 AGP **9.0.1** / Kotlin **2.3.20** 을 쓴다. `com.google.gms.google-services` 플러그인이 이 조합을 못 따라올 수 있는 게 **1순위 리스크**다. Dart 코드를 한 줄도 쓰기 전에 빌드가 통과하는지부터 확인한다.

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/settings.gradle.kts`
- Modify: `android/app/build.gradle.kts:1-6` (plugins 블록)
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `.gitignore:34` (google-services.json 제외 해제)
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: 없음
- Produces: `Firebase.initializeApp()`가 완료된 앱. 이후 모든 태스크가 `FirebaseMessaging.instance`를 쓸 수 있다.

- [ ] **Step 1: 패키지 추가**

```bash
flutter pub add firebase_core firebase_messaging flutter_local_notifications
```

버전은 pub이 Dart 3.12 / Flutter 3.44에 맞춰 해석하게 둔다. 직접 핀하지 않는다.

- [ ] **Step 2: settings.gradle.kts에 플러그인 선언**

`android/settings.gradle.kts`의 `plugins` 블록 마지막에 한 줄 추가:

```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    id("com.google.gms.google-services") version "4.4.4" apply false
}
```

⚠️ `4.4.4`는 출발점이다. 해석에 실패하면
<https://developers.google.com/android/guides/google-services-plugin> 에서
현재 버전을 확인해 올린다.

- [ ] **Step 3: app/build.gradle.kts에 플러그인 적용**

`android/app/build.gradle.kts` 최상단 `plugins` 블록을 아래로 바꾼다.
**순서가 중요하다** — `com.android.application` 다음, `dev.flutter.flutter-gradle-plugin` 앞.

```kotlin
plugins {
    id("com.android.application")
    // google-services 는 android application 플러그인 뒤에 와야 한다.
    // 앞에 두면 android {} 확장이 아직 없어서 설정을 못 읽는다.
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}
```

- [ ] **Step 4: AndroidManifest에 권한과 알림 채널 선언**

`android/app/src/main/AndroidManifest.xml` — 기존 `INTERNET` 권한 아래에 추가:

```xml
    <!-- Android 13+ 는 알림 표시에 런타임 권한이 필요하다.
         온보딩 완료 시점에 PushService 가 요청한다. -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

그리고 `<application>` 안, `flutterEmbedding` meta-data 옆에 추가:

```xml
        <!-- 백그라운드·종료 상태에서 OS 가 알림을 그릴 때 쓸 채널.
             같은 id 의 채널을 PushService 가 앱 시작 시 만든다. 이 값이
             앱이 만드는 채널과 다르면 백그라운드 알림이 기본 채널로 떨어져
             포그라운드 배너와 중요도·소리 설정이 갈린다. -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="iam_default" />
```

- [ ] **Step 5: main.dart에서 Firebase 초기화**

`lib/main.dart` — import 추가:

```dart
import 'package:firebase_core/firebase_core.dart';
```

`main()` 안, `await Storage.init();` **바로 다음**에 추가:

```dart
  // FCM 은 Firebase 앱이 초기화된 뒤에만 쓸 수 있다.
  // android/app/google-services.json 에서 설정을 읽으므로 인자가 없다
  // (Android 전용이라 firebase_options.dart 를 만들지 않는다).
  await Firebase.initializeApp();
```

- [ ] **Step 6: 빌드 검증 — 이 태스크의 관문**

```bash
flutter build apk --debug
```

Expected: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`

실패 시 대응 순서:
1. `com.google.gms.google-services` 버전 조정 (Step 2)
2. Firebase Android SDK 버전 조정 — `android/app/build.gradle.kts`의
   `dependencies`에 `platform("com.google.firebase:firebase-bom:<ver>")` 명시
3. AGP 하향 — 최후수단. `mobile_scanner` 등 다른 플러그인에 영향이 간다

`File google-services.json is missing` 이 나오면 사전 준비가 안 끝난 것이다. 멈추고 알린다.

- [ ] **Step 7: 앱이 실제로 뜨는지 확인**

```bash
flutter run --dart-define=API_BASE=https://dev-api.octoverse.kr/iam/v1
```

Expected: 스플래시 → 로그인 화면. 크래시 없음. 확인 후 종료.

- [ ] **Step 8: .gitignore에서 google-services.json 제외 해제**

`.gitignore:34`의 아래 줄을 **지운다**:

```
android/app/google-services.json
```

이 파일의 API 키는 클라이언트 식별자이지 비밀이 아니다(발송 권한을 가진 서버 키와
다르다). 저장소 밖에 둔 `kakao.properties` 와는 성격이 다르다.
안 지우면 다음 스텝의 `git add` 가 이 파일을 **조용히 건너뛰고**, 그 사실은
다른 사람이 클론했을 때 빌드 실패로만 드러난다.

- [ ] **Step 9: 커밋 — google-services.json이 실제로 담겼는지 확인**

```bash
git add pubspec.yaml pubspec.lock android/ .gitignore lib/main.dart
git status --short
```

Expected: 목록에 `A  android/app/google-services.json` 이 **반드시** 보여야 한다.
안 보이면 Step 8 이 안 된 것이다.

```bash
git commit -m "chore(push): Firebase 초기화 · google-services 플러그인 배선

AGP 9.0.1 / Kotlin 2.3.20 조합에서 빌드가 통과하는지부터 확인했다.
Android 전용이라 FlutterFire CLI 와 firebase_options.dart 는 쓰지 않고
google-services.json 하나로 간다.

google-services.json 은 커밋한다 — 여기 담긴 키는 클라이언트 식별자이지
발송 권한을 가진 서버 키가 아니다. 빼두면 다른 개발자 빌드가 깨진다."
```

---

## Task 2: 딥링크 라우팅 규칙 (TDD)

**Files:**
- Modify: `lib/data/enums/social_enums.dart:6-37` (`NotificationType` 아래)
- Create: `lib/service/push_router.dart`
- Test: `test/push_router_test.dart`

**Interfaces:**
- Consumes: `NotificationType`(`lib/data/enums/social_enums.dart`), `AppRoutes`(`lib/core/route/app_pages.dart`)
- Produces:
  - `String routeForPush(Map<String, dynamic> data)` — 항상 유효한 라우트 문자열을 돌려준다(null 없음)
  - `NotificationTypeParse.tryParse(String? raw) → NotificationType?`

- [ ] **Step 1: 실패하는 테스트 작성**

`test/push_router_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:iam/core/route/app_pages.dart';
import 'package:iam/service/push_router.dart';

/// FCM data payload → 이동할 화면.
///
/// 서버가 보내는 값을 앱이 그대로 믿고 라우팅하는 지점이라, 값이 빠지거나
/// 모르는 타입이 와도 크래시 없이 알림함으로 떨어져야 한다.
void main() {
  group('모임 관련 알림 → 모임 상세', () {
    for (final type in [
      'participation_ack',
      'reminder_24h',
      'reminder_1h',
      'channel_updated',
      'channel_cancelled',
    ]) {
      test('$type 은 slug 로 모임 상세를 연다', () {
        expect(
          routeForPush({'type': type, 'channel_slug': 'ai-meetup'}),
          '/event/ai-meetup',
        );
      });
    }
  });

  group('명함 교환 알림 → 명함함', () {
    for (final type in [
      'card_exchange_requested',
      'card_exchange_accepted',
      'card_exchange_cancelled',
    ]) {
      test('$type 은 명함함을 연다', () {
        expect(routeForPush({'type': type}), AppRoutes.meCards);
      });
    }
  });

  test('welcome 은 알림함을 연다', () {
    expect(routeForPush({'type': 'welcome'}), AppRoutes.meNotifications);
  });

  group('망가진 payload 는 알림함으로 떨어진다', () {
    test('모임 알림인데 channel_slug 가 없으면', () {
      expect(routeForPush({'type': 'reminder_24h'}), AppRoutes.meNotifications);
    });

    test('channel_slug 가 빈 문자열이면', () {
      expect(
        routeForPush({'type': 'reminder_24h', 'channel_slug': '  '}),
        AppRoutes.meNotifications,
      );
    });

    test('서버가 새 타입을 추가해 앱이 모르는 값이 오면', () {
      expect(
        routeForPush({'type': 'someday_new_type'}),
        AppRoutes.meNotifications,
      );
    });

    test('type 자체가 없으면', () {
      expect(routeForPush({}), AppRoutes.meNotifications);
    });
  });
}
```

- [ ] **Step 2: 테스트가 실패하는지 확인**

```bash
flutter test test/push_router_test.dart
```

Expected: 컴파일 실패 — `Target of URI doesn't exist: 'package:iam/service/push_router.dart'`

- [ ] **Step 3: enum 파싱 헬퍼 추가**

`lib/data/enums/social_enums.dart` — `NotificationType` enum 닫는 괄호 **바로 아래**에 추가:

```dart
/// FCM data payload 의 문자열 → enum.
///
/// `@JsonValue` 와 값이 같아야 해서 바로 아래에 둔다 — 떨어뜨려 놓으면 한쪽만
/// 고치고 지나가기 쉽다. json_serializable 의 역직렬화는 모르는 값에 예외를
/// 던지지만, 푸시는 서버가 새 타입을 추가해도 앱이 죽으면 안 되므로 null 을 준다.
extension NotificationTypeParse on NotificationType {
  static NotificationType? tryParse(String? raw) => switch (raw) {
    'welcome' => NotificationType.welcome,
    'participation_ack' => NotificationType.participationAck,
    'reminder_24h' => NotificationType.reminder24h,
    'reminder_1h' => NotificationType.reminder1h,
    'channel_updated' => NotificationType.channelUpdated,
    'channel_cancelled' => NotificationType.channelCancelled,
    'card_exchange_requested' => NotificationType.cardExchangeRequested,
    'card_exchange_accepted' => NotificationType.cardExchangeAccepted,
    'card_exchange_cancelled' => NotificationType.cardExchangeCancelled,
    _ => null,
  };
}
```

- [ ] **Step 4: 라우터 구현**

`lib/service/push_router.dart`:

```dart
import 'package:iam/core/route/app_pages.dart';
import 'package:iam/data/enums/enums.dart';

/// FCM `data` payload → 이동할 라우트.
///
/// `RemoteMessage` 를 받지 않는다. Firebase 없이 테스트할 수 있어야 하고,
/// 알림 타입이 늘 때 손댈 곳을 여기 하나로 묶어두기 위해서다.
///
/// 서버가 보내는 payload 규격은 `docs/server-requirements-fcm.md` §2 참고.
/// 값이 빠지거나 모르는 타입이 와도 **절대 던지지 않는다** — 푸시를 탭했는데
/// 앱이 죽는 것보다 알림함이 열리는 게 낫다.
String routeForPush(Map<String, dynamic> data) {
  final type = NotificationTypeParse.tryParse(data['type'] as String?);
  if (type == null) return AppRoutes.meNotifications;

  final slug = (data['channel_slug'] as String?)?.trim();

  // enum 위의 exhaustive switch — NotificationType 에 값이 추가되면
  // 여기서 컴파일 에러가 나서 라우트 결정을 강제한다.
  return switch (type) {
    NotificationType.participationAck ||
    NotificationType.reminder24h ||
    NotificationType.reminder1h ||
    NotificationType.channelUpdated ||
    NotificationType.channelCancelled =>
      (slug == null || slug.isEmpty)
          ? AppRoutes.meNotifications
          : AppRoutes.eventDetailOf(slug),

    NotificationType.cardExchangeRequested ||
    NotificationType.cardExchangeAccepted ||
    NotificationType.cardExchangeCancelled => AppRoutes.meCards,

    NotificationType.welcome => AppRoutes.meNotifications,
  };
}
```

- [ ] **Step 5: 테스트 통과 확인**

```bash
flutter test test/push_router_test.dart
```

Expected: All tests passed. (13 tests)

- [ ] **Step 6: 정적 분석**

```bash
flutter analyze lib/service/push_router.dart lib/data/enums/social_enums.dart test/push_router_test.dart
```

Expected: `No issues found!`

- [ ] **Step 7: 커밋**

```bash
git add lib/service/push_router.dart lib/data/enums/social_enums.dart test/push_router_test.dart
git commit -m "feat(push): 알림 타입별 딥링크 규칙

서버가 새 알림 타입을 추가해도 앱이 죽지 않게 모르는 값은 알림함으로
떨어뜨린다. enum exhaustive switch 라 우리가 타입을 추가할 때는
반대로 컴파일 에러로 잡힌다."
```

---

## Task 3: 디바이스 토큰 등록 API 계약

**Files:**
- Modify: `lib/core/network/apis.dart` (§8 Notification 블록 아래)
- Modify: `lib/data/models/social_model.dart` (파일 끝)
- Modify: `lib/core/network/api_client.dart` (`notifications()` 아래)
- Test: `test/device_model_test.dart`

**Interfaces:**
- Consumes: 없음
- Produces:
  - `Apis.devices` = `/users/me/devices`, `Apis.device` = `/users/me/devices/{token}`
  - `DeviceRegisterRequest({required String token, String platform = 'android'})`
  - `ApiClient.registerDevice(DeviceRegisterRequest body) → Future<void>`
  - `ApiClient.unregisterDevice(String token) → Future<void>`

- [ ] **Step 1: 실패하는 테스트 작성**

`test/device_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:iam/data/models/models.dart';

/// 서버 계약은 snake_case 다. 필드명이 어긋나면 등록이 400 으로 조용히
/// 실패하고, 그 결과는 "푸시가 안 온다"로만 나타나 원인 찾기가 괴롭다.
void main() {
  test('토큰 등록 요청은 snake_case 로 직렬화된다', () {
    expect(
      const DeviceRegisterRequest(token: 'abc123').toJson(),
      {'token': 'abc123', 'platform': 'android'},
    );
  });

  test('platform 기본값은 android 다', () {
    expect(const DeviceRegisterRequest(token: 'x').platform, 'android');
  });
}
```

- [ ] **Step 2: 테스트가 실패하는지 확인**

```bash
flutter test test/device_model_test.dart
```

Expected: 컴파일 실패 — `The name 'DeviceRegisterRequest' isn't a class`

- [ ] **Step 3: 경로 상수 추가**

`lib/core/network/apis.dart` — `// ── §8 Notification ──` 블록 바로 아래에:

```dart
  // ── Device (FCM 푸시 토큰) ─────────────────────────────────
  /// 이 기기의 FCM 토큰 등록. 멱등 — 같은 토큰 재전송은 갱신만 한다.
  static const String devices = '/users/me/devices';

  /// 로그아웃 시 해제. 계약은 `docs/server-requirements-fcm.md` §1.
  static const String device = '/users/me/devices/{token}';
```

- [ ] **Step 4: 모델 추가**

`lib/data/models/social_model.dart` 파일 **끝**에 추가:

```dart
// ══════════════════════════════════════════════════════════════
// Device (FCM 푸시 토큰)
// ══════════════════════════════════════════════════════════════

@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class DeviceRegisterRequest {
  const DeviceRegisterRequest({required this.token, this.platform = 'android'});

  /// FCM registration token. 기기·앱 설치 단위로 발급되고 재발급될 수 있다.
  final String token;

  /// 지금은 Android 만 지원한다. iOS 를 붙일 때 'ios' 가 추가된다.
  final String platform;

  factory DeviceRegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$DeviceRegisterRequestFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceRegisterRequestToJson(this);
}
```

- [ ] **Step 5: 코드 생성**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `Succeeded after ...` — `social_model.g.dart`에
`_$DeviceRegisterRequestToJson`이 생긴다.

- [ ] **Step 6: 테스트 통과 확인**

```bash
flutter test test/device_model_test.dart
```

Expected: All tests passed. (2 tests)

- [ ] **Step 7: ApiClient에 엔드포인트 추가**

`lib/core/network/api_client.dart` — `notifications()` 메서드 아래,
`// §... Business Card & Exchange` 구분선 **앞**에:

```dart
  // ══════════════════════════════════════════════════════════
  // Device (FCM 푸시 토큰)
  // ══════════════════════════════════════════════════════════

  /// 이 기기의 FCM 토큰을 등록한다. 멱등이라 로그인·토큰갱신마다 그냥 쏜다.
  ///
  /// ⚠️ 비로그인 상태에서 부르면 안 된다. 401 이 인터셉터를 타면 세션이
  ///    끊긴 것으로 처리돼 사용자가 로그인 화면으로 튕긴다.
  @POST(Apis.devices)
  Future<void> registerDevice(@Body() DeviceRegisterRequest body);

  /// 로그아웃 시 해제. 안 하면 로그아웃한 기기로 계속 푸시가 간다.
  @DELETE(Apis.device)
  Future<void> unregisterDevice(@Path('token') String token);
```

- [ ] **Step 8: 코드 생성 후 분석**

```bash
dart run build_runner build --delete-conflicting-outputs && flutter analyze
```

Expected: `Succeeded` 후 `No issues found!`

- [ ] **Step 9: 커밋**

⚠️ `.g.dart` 는 스테이징하지 않는다. `.gitignore:17-18` 이 `*.g.dart` ·
`*.freezed.dart` 를 제외하고 있고, 이 저장소에 추적되는 생성 파일은 하나도 없다.
받는 사람이 `dart run build_runner build` 를 돌리는 것이 이 프로젝트의 계약이다.

```bash
git add lib/core/network/apis.dart lib/core/network/api_client.dart lib/data/models/social_model.dart test/device_model_test.dart
git commit -m "feat(push): 디바이스 토큰 등록·해제 API 계약

서버에 아직 없는 엔드포인트다. 앱이 요구하는 계약을 먼저 박아두고
docs/server-requirements-fcm.md 로 서버팀에 넘긴다."
```

---

## Task 4: PushService — 권한과 토큰 수명주기

**Files:**
- Create: `lib/service/push_service.dart`
- Modify: `lib/service/services.dart`
- Modify: `lib/service/auth_service.dart` (`signOutLocal()` 및 필드)
- Modify: `lib/main.dart` (`_registerGlobals()`)
- Modify: `lib/feature/splash/splash_controller.dart`
- Modify: `lib/feature/login/login_controller.dart:48-62` (`_run()`)
- Modify: `lib/feature/onboarding/onboarding_controller.dart` (제출 성공 지점)

**Interfaces:**
- Consumes: `ApiClient.registerDevice` · `unregisterDevice`, `DeviceRegisterRequest` (Task 3)
- Produces:
  - `PushService(ApiClient api)` — `GetxService`
  - `Future<void> syncToken()`
  - `Future<void> requestPermissionAndRegister()`
  - `Future<void> unregister()`
  - `AuthService.onBeforeSignOut` — `Future<void> Function()?`

- [ ] **Step 1: PushService 작성**

`lib/service/push_service.dart`:

```dart
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

import 'package:iam/core/network/api_client.dart';
import 'package:iam/data/data_manager.dart';
import 'package:iam/data/models/models.dart';

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
```

- [ ] **Step 2: barrel에 export 추가**

`lib/service/services.dart` — export 목록에 (알파벳 순서 유지):

```dart
export 'push_service.dart';
```

그리고 파일 상단 대응표에 한 줄 추가:

```
/// | (웹에 없음 — 앱 전용) | `PushService` |
```

- [ ] **Step 3: AuthService에 로그아웃 훅 추가**

`lib/service/auth_service.dart` — `final ApiClient _api;` 아래에 필드 추가:

```dart
  /// 로컬 세션을 지우기 **직전**에 불린다. `main.dart` 가 여기에
  /// "FCM 토큰 해제"를 꽂는다.
  ///
  /// 콜백으로 연결하는 이유는 `AuthInterceptorHooks` 와 같다 — AuthService 가
  /// PushService 를 직접 알면 서로를 참조하게 되고, 토큰 해제는 세션이 살아
  /// 있을 때만 가능해서 호출 순서가 계약의 일부가 된다.
  Future<void> Function()? onBeforeSignOut;
```

`signOutLocal()`을 아래로 바꾼다:

```dart
  /// 로컬 세션만 정리. 401 인터셉터도 이 경로를 탄다.
  Future<void> signOutLocal() async {
    // 세션이 살아 있을 때 먼저 훅을 태운다 — 순서가 바뀌면 FCM 토큰 해제
    // 요청에 Bearer 가 안 실려 401 로 떨어진다.
    try {
      await onBeforeSignOut?.call();
    } catch (_) {
      // 훅이 실패해도 로그아웃은 반드시 진행한다.
    }
    await Storage.clearSession();
    me.value = null;
  }
```

- [ ] **Step 4: main.dart에 등록 · 배선**

`lib/main.dart` — `_registerGlobals()` 안, `Get.put(ToastService(), permanent: true);` **앞**에:

```dart
  final push = Get.put(PushService(api), permanent: true);
  // 로그아웃 시 이 기기로 푸시가 계속 가지 않게 토큰을 뗀다.
  auth.onBeforeSignOut = push.unregister;
```

그리고 기존 `AuthInterceptorHooks.onSessionExpired` 핸들러 본문에 한 줄 추가한다:

```dart
  AuthInterceptorHooks.onSessionExpired = () {
    Get.find<NotificationService>().clear();
    // 세션이 끊긴 경로는 signOutLocal() 을 타지 않아 훅이 안 불린다.
    // 여기서는 Storage 가 이미 비었으므로 서버 DELETE 는 건너뛰고
    // FCM 쪽 토큰만 무효화된다(unregister() 내부의 hasSession 가드).
    unawaited(push.unregister());
    Get.offAllNamed(AppRoutes.login);
  };
```

`lib/main.dart` 상단에 `import 'dart:async';` 를 추가한다.

- [ ] **Step 5: 스플래시에서 토큰 동기화**

`lib/feature/splash/splash_controller.dart` — 상단에 `import 'dart:async';` 추가.
생성자와 필드를 `PushService`를 받도록 바꾼다:

```dart
class SplashController extends GetxController {
  SplashController(this._auth, this._reference, this._push);

  final AuthService _auth;
  final ReferenceService _reference;
  final PushService _push;
```

`_boot()`의 `if (!_auth.hasProfile)` 분기 **앞**에 추가:

```dart
    // 권한이 이미 있으면 토큰을 서버에 다시 등록한다(토큰은 재발급된다).
    // await 하지 않는다 — 스플래시가 네트워크를 기다릴 이유가 없다.
    unawaited(_push.syncToken());
```

`lib/feature/splash/binding.dart`의 `dependencies()` 를 아래로 바꾼다:

```dart
    Get.put<SplashController>(
      SplashController(
        Get.find<AuthService>(),
        Get.find<ReferenceService>(),
        Get.find<PushService>(),
      ),
    );
```

- [ ] **Step 6: 로그인 성공 후 토큰 동기화**

`lib/feature/login/login_controller.dart` — 상단에 `import 'dart:async';` 추가.
생성자를 `LoginController(this._auth, this._toast, this._push);` 로 바꾸고
`final PushService _push;` 필드를 추가한다.

`_run()`의 `final result = await action();` **다음 줄**에:

```dart
      // 이미 권한이 있는 재로그인 유저의 토큰을 갱신한다.
      // 최초 가입자는 온보딩 끝에서 권한 요청과 함께 등록된다.
      unawaited(_push.syncToken());
```

`lib/feature/login/binding.dart`의 `dependencies()` 를 아래로 바꾼다:

```dart
    Get.lazyPut<LoginController>(
      () => LoginController(
        Get.find<AuthService>(),
        Get.find<ToastService>(),
        Get.find<PushService>(),
      ),
    );
```

- [ ] **Step 7: 온보딩 완료 시 권한 요청**

`lib/feature/onboarding/onboarding_controller.dart` — 생성자를
`OnboardingController(this._api, this._auth, this._reference, this._toast, this._push);`
로 바꾸고 `final PushService _push;` 필드를 추가한다.

`lib/feature/onboarding/binding.dart` 의 `dependencies()` 를 아래로 바꾼다:

```dart
    Get.lazyPut<OnboardingController>(
      () => OnboardingController(
        Get.find<ApiClient>(),
        Get.find<AuthService>(),
        Get.find<ReferenceService>(),
        Get.find<ToastService>(),
        Get.find<PushService>(),
      ),
    );
```

그리고 컨트롤러의 `_toast.success('가입이 완료됐어요. 환영합니다!');` 와
`Get.offAllNamed(AppRoutes.home);` **사이**에:

```dart
      // 여기가 알림 권한을 물어보기 가장 좋은 시점이다 — 방금 프로필을 만든
      // 사람에게 "모임 리마인더를 받겠냐"는 맥락이 서 있다.
      // 거부해도 그냥 넘어간다(내부에서 삼킨다).
      await _push.requestPermissionAndRegister();
```

- [ ] **Step 8: 분석 · 전체 테스트**

```bash
flutter analyze && flutter test
```

Expected: `No issues found!` + All tests passed.

- [ ] **Step 9: 기기에서 토큰 등록 확인**

```bash
flutter run --dart-define=API_BASE=https://dev-api.octoverse.kr/iam/v1
```

새 계정으로 온보딩을 끝까지 진행한다.
Expected: 마지막 스텝 후 OS 알림 권한 팝업이 뜬다.
`POST /users/me/devices` 요청이 PrettyDioLogger 로그에 보인다.
(서버에 엔드포인트가 아직 없으면 404 가 뜨는 게 정상이다 — 요청이 나갔다는 것만 확인한다.)

- [ ] **Step 10: 커밋**

```bash
git add lib/service/ lib/main.dart lib/feature/splash/ lib/feature/login/ lib/feature/onboarding/
git commit -m "feat(push): FCM 권한 요청과 토큰 수명주기

권한은 온보딩 끝에서 한 번만 묻고, 토큰 등록은 부팅·로그인·갱신마다 한다.
디바이스 API 는 Storage.hasSession 뒤에서만 부른다 — 비로그인 401 이
인터셉터를 타면 보고 있던 화면에서 로그인으로 튕기기 때문이다."
```

---

## Task 5: 포그라운드 수신 — 시스템 배너

Android 는 앱이 떠 있는 동안 시스템 배너를 자동으로 띄워주지 않는다.
`flutter_local_notifications` 로 직접 그린다. 채널 id 는 Task 1 에서 매니페스트에
박은 `iam_default` 와 **반드시 같아야** 백그라운드 알림과 설정이 갈리지 않는다.

**Files:**
- Modify: `lib/service/push_service.dart`

**Interfaces:**
- Consumes: `PushService` (Task 4), `routeForPush` (Task 2), `NotificationService.load()`
- Produces: `PushService(ApiClient api, NotificationService notifications)` — 생성자 시그니처가 바뀐다

- [ ] **Step 1: import와 상수 추가**

`lib/service/push_service.dart` 상단 import 에 추가:

```dart
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:iam/service/notification_service.dart';
import 'package:iam/service/push_router.dart';
```

클래스 안 필드 위에 추가:

```dart
  /// AndroidManifest 의 `default_notification_channel_id` 와 같은 값이어야 한다.
  /// 다르면 백그라운드(OS 가 그림)와 포그라운드(우리가 그림) 알림이 서로 다른
  /// 채널로 가서 사용자가 소리·중요도를 따로 꺼야 하는 상태가 된다.
  static const _channelId = 'iam_default';
```

- [ ] **Step 2: 생성자에 NotificationService 추가**

```dart
  PushService(this._api, this._notifications);

  final ApiClient _api;
  final NotificationService _notifications;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _refreshSub;
  StreamSubscription<RemoteMessage>? _messageSub;

  /// 로컬 알림 id. 겹치면 이전 알림을 덮어써서 하나만 남는다.
  int _localId = 0;
```

`lib/main.dart`의 등록도 함께 고친다:

```dart
  final notifications = Get.put(NotificationService(api, auth), permanent: true);
  final push = Get.put(PushService(api, notifications), permanent: true);
```

(기존 `Get.put(NotificationService(api, auth), permanent: true);` 줄을 위처럼 바꾼다.)

- [ ] **Step 3: onInit에 채널 생성과 수신 구독 추가**

`onInit()` 을 아래로 바꾼다:

```dart
  @override
  void onInit() {
    super.onInit();
    _refreshSub = _fcm.onTokenRefresh.listen(_register);
    _messageSub = FirebaseMessaging.onMessage.listen(_showForeground);
    unawaited(_initLocalNotifications());
  }
```

`onClose()` 에 구독 해제를 추가한다:

```dart
  @override
  void onClose() {
    _refreshSub?.cancel();
    _messageSub?.cancel();
    super.onClose();
  }
```

- [ ] **Step 4: 로컬 알림 초기화와 표시 구현**

클래스 끝(private 메서드 구역)에 추가:

```dart
  // ── 포그라운드 표시 ─────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    await _local.initialize(
      const InitializationSettings(
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
      _localId++,
      notification.title,
      notification.body,
      const NotificationDetails(
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
```

- [ ] **Step 5: `_openRoute` 구현**

로컬 알림 탭(이 태스크)과 백그라운드 복귀·콜드 스타트(Task 6)가 **공유하는**
이동 로직이다. Task 6 은 이 메서드를 고치지 않고 호출 지점만 늘린다.

```dart
  // ── 탭 → 화면 이동 ──────────────────────────────────────────

  void _openRoute(Map<String, dynamic> data) {
    // 비로그인 상태의 딥링크는 버린다 — RouteGuard 가 막고, 로그인 후
    // 원래 목적지로 복원하는 기능은 아직 없다.
    if (!Storage.hasSession) return;
    Get.toNamed(routeForPush(data));
  }
```

- [ ] **Step 6: 분석 · 테스트**

```bash
flutter analyze && flutter test
```

Expected: `No issues found!` + All tests passed.

- [ ] **Step 7: 기기에서 포그라운드 수신 확인**

앱을 실행해 로그인 상태로 홈에 둔 채, Firebase 콘솔 →
Cloud Messaging → 캠페인 만들기 → 테스트 메시지에 기기 토큰을 넣어 발송한다.
(토큰은 `flutter run` 로그의 `POST /users/me/devices` 요청 본문에서 복사한다.)

Expected: 앱을 보고 있는 상태에서 시스템 배너가 뜬다. 벨 배지 숫자가 오른다.

- [ ] **Step 8: 커밋**

```bash
git add lib/service/push_service.dart lib/main.dart
git commit -m "feat(push): 포그라운드 푸시를 시스템 배너로 표시

Android 는 앱이 떠 있는 동안 배너를 자동으로 안 띄운다.
채널 id 는 매니페스트의 default_notification_channel_id 와 같은 값이라
백그라운드(OS 가 그림)와 설정이 갈리지 않는다."
```

---

## Task 6: 딥링크 — 백그라운드 복귀와 콜드 스타트

**Files:**
- Modify: `lib/service/push_service.dart`
- Modify: `lib/feature/splash/splash_controller.dart`

**Interfaces:**
- Consumes: `routeForPush` (Task 2), `PushService._openRoute` (Task 5)
- Produces: `Future<void> PushService.handleInitialMessage()`

- [ ] **Step 1: 백그라운드 복귀 탭 구독**

`lib/service/push_service.dart` — 구독 필드 추가:

```dart
  StreamSubscription<RemoteMessage>? _openedSub;
```

`onInit()` 에 한 줄 추가:

```dart
    _openedSub = FirebaseMessaging.onMessageOpenedApp.listen(
      (m) => _openRoute(m.data),
    );
```

`onClose()` 에 `_openedSub?.cancel();` 추가.

- [ ] **Step 2: 콜드 스타트 진입점 추가**

`_openRoute` 아래에 추가:

```dart
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
      // Global Constraints — 푸시 실패는 전부 삼킨다. 여기서 던지면 _boot() 이
      // unawaited 라 처리되지 않은 Future 에러가 된다. 이미 홈에 도착한 뒤라
      // 사용자에게는 영향이 없고, 나중에 크래시 리포터를 붙였을 때 "Play 서비스
      // 없음" 같은 예상된 실패가 크래시로 잡히는 것만 남는다.
    }
  }
```

- [ ] **Step 3: 스플래시에서 라우팅 후 호출**

`lib/feature/splash/splash_controller.dart` — `_boot()` 의 마지막
`Get.offAllNamed(AppRoutes.home);` **다음 줄**에:

```dart
    // 홈 스택이 자리잡은 뒤에 딥링크를 얹는다. 순서가 뒤바뀌면
    // offAllNamed 가 딥링크 목적지를 지운다.
    await _push.handleInitialMessage();
```

`_boot()` 은 이미 `Future<void>` 이므로 시그니처 변경은 없다.

- [ ] **Step 4: 분석 · 테스트**

```bash
flutter analyze && flutter test
```

Expected: `No issues found!` + All tests passed.

- [ ] **Step 5: 기기에서 백그라운드 탭 확인**

앱을 홈 버튼으로 백그라운드에 보낸 뒤, Firebase 콘솔에서
**커스텀 데이터**에 `type=reminder_24h`, `channel_slug=<실제 존재하는 slug>` 를 넣어 발송한다.

Expected: 트레이에 알림이 뜬다. 탭하면 앱이 열리며 해당 모임 상세 화면으로 간다.

- [ ] **Step 6: 기기에서 콜드 스타트 탭 확인**

앱을 최근 앱 목록에서 완전히 스와이프해 종료한 뒤, 같은 방식으로 발송한다.

Expected: 트레이에 알림이 뜬다. 탭하면 스플래시를 거쳐 모임 상세 화면으로 간다.
(홈으로 튕기면 §Step 3 의 호출 순서가 틀린 것이다.)

- [ ] **Step 7: 커밋**

```bash
git add lib/service/push_service.dart lib/feature/splash/splash_controller.dart
git commit -m "feat(push): 알림 탭 딥링크 — 백그라운드 복귀와 콜드 스타트

콜드 스타트는 스플래시가 offAllNamed 를 끝낸 뒤에 처리해야 한다.
먼저 처리하면 뒤이은 offAllNamed 가 딥링크 목적지를 지운다."
```

---

## Task 7: 전체 검증과 문서 갱신

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: Task 1~6 전부
- Produces: 없음

- [ ] **Step 1: 전체 수동 검증 — 5가지 상태**

각 항목을 실제 기기에서 확인하고 결과를 기록한다.
Firebase 콘솔 → Cloud Messaging → 테스트 메시지, 커스텀 데이터에
`type` / `channel_slug` 를 넣어 발송한다.

| # | 상태 | 기대 동작 |
|---|---|---|
| 1 | 포그라운드 | 시스템 배너가 뜬다. 벨 배지 숫자가 오른다 |
| 2 | 백그라운드 | 트레이에 뜬다. 탭하면 모임 상세로 간다 |
| 3 | 완전 종료 | 트레이에 뜬다. 탭하면 스플래시를 거쳐 모임 상세로 간다 |
| 4 | 권한 거부 | 앱이 정상 동작한다. 크래시·토스트 없음 |
| 5 | 로그아웃 후 | 같은 기기로 더 이상 푸시가 오지 않는다 |

4번은 설정 → 앱 → IAM → 알림을 끄고 앱을 재시작해 확인한다.
5번은 로그아웃 직후 발송해 확인한다 (`deleteToken()` 으로 토큰이 무효화됐으므로
콘솔이 `Invalid registration token` 을 응답하는 것이 정상이다).

- [ ] **Step 2: 망가진 payload 방어 확인**

`type` 없이, 그리고 `type=reminder_24h` 인데 `channel_slug` 없이 각각 발송한다.

Expected: 두 경우 모두 탭하면 알림함(`/me/notifications`)이 열린다. 크래시 없음.

- [ ] **Step 3: 전체 테스트 · 분석**

```bash
flutter analyze && flutter test
```

Expected: `No issues found!` + All tests passed.

- [ ] **Step 4: README 갱신**

`README.md:22` 부근의 기능 표에 한 줄 추가한다:

```
| FCM 푸시(Android) · 권한 · 토큰 등록 · 딥링크 | ✅ |
```

그리고 `README.md:239` 부근의 "임시 조치" 표에 한 줄 추가한다:

```
| 푸시 on/off | 서버 `settings` 에 `push_notification_enabled` 가 없어 앱 안에서 끌 방법이 없다. OS 알림 설정으로만 끈다. |
```

- [ ] **Step 5: 커밋**

```bash
git add README.md
git commit -m "docs: FCM 푸시 지원 상태 README 반영"
```

- [ ] **Step 6: 브랜치 정리**

`superpowers:finishing-a-development-branch` 스킬로 병합 여부를 결정한다.

---

## 남은 의존성 (앱 밖)

이 계획을 다 실행해도 **서버에 다음 두 가지가 없으면 푸시는 오지 않는다.**

1. `POST` / `DELETE /users/me/devices` — 없으면 Task 4 Step 9 에서 404 가 뜬다
2. 발송 페이로드의 `data` 필드 — 없으면 딥링크가 전부 알림함으로 떨어진다

Task 1~6 은 서버 없이도 Firebase 콘솔 테스트 메시지로 전부 검증할 수 있다.
서버 작업이 끝나면 Task 7 Step 1 을 실서버 발송으로 한 번 더 돌린다.
