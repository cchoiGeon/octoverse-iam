# FCM 푸시 알림 (Android) — 설계

- 작성일: 2026-07-29
- 범위: **Android 전용**. iOS는 이번 범위에서 제외한다(APNs 키·유료 개발자 계정·실기기 미보유).
- 서버 요청사항은 별도 문서: [`docs/server-requirements-fcm.md`](../../server-requirements-fcm.md)

---

## 1. 현황

인앱 알림 **피드**는 이미 있다. 없는 것은 **푸시** 전부다.

| 이미 있는 것 | 위치 |
|---|---|
| 알림 목록 조회 + 로컬 읽음 관리 | `lib/service/notification_service.dart` |
| 알림 타입 9종 + 라벨 | `lib/data/enums/social_enums.dart` |
| 벨 배지 · 알림 아이템 UI | `lib/common/widgets/ds/navigation/` |
| `GET /notifications` | `lib/core/network/api_client.dart` |

| 없는 것 |
|---|
| `firebase_core` · `firebase_messaging` · `flutter_local_notifications` |
| `google-services.json`, gradle 플러그인 배선 |
| **서버의 디바이스 토큰 등록 엔드포인트** |
| 권한 요청 · 토큰 수명주기 · 수신 처리 · 딥링크 |

---

## 2. 전체 흐름

```
[앱 부팅]  Firebase.initializeApp()
           + top-level 백그라운드 수신 핸들러 등록
     │
[세션 확립]  권한이 이미 있으면 → getToken() → POST /users/me/devices
     │       (스플래시 부팅 후 · 로그인 성공 직후)
     │
[온보딩 완료]  OS 권한 팝업 → 승인 시 위와 동일하게 등록
     │
[토큰 갱신]  onTokenRefresh 스트림 → 같은 엔드포인트로 재등록
     │
[로그아웃]  DELETE /users/me/devices/{token} → deleteToken()

[수신]
  백그라운드 · 종료  → OS가 트레이에 직접 표시 (앱 Dart 코드 안 탐)
  포그라운드         → onMessage → flutter_local_notifications 배너
                                 + NotificationService.load()
  알림 탭            → data payload의 type/slug로 딥링크
```

### 서버 페이로드 계약

`notification` + `data` 를 **둘 다** 보낸다. 근거와 전체 규격은 서버 요청 문서 §2 참조.

```json
{
  "notification": { "title": "...", "body": "..." },
  "data": { "notification_id": "...", "type": "reminder_24h", "channel_slug": "ai-meetup" }
}
```

### 딥링크 매핑

| `type` | 이동 경로 |
|---|---|
| `participation_ack`, `reminder_24h`, `reminder_1h`, `channel_updated`, `channel_cancelled` | `AppRoutes.eventDetailOf(slug)` |
| `card_exchange_requested`, `card_exchange_accepted`, `card_exchange_cancelled` | `AppRoutes.meCards` |
| `welcome` | `AppRoutes.meNotifications` |
| 알 수 없는 type · `channel_slug` 누락 | `AppRoutes.meNotifications` (폴백) |

미래에 서버가 새 타입을 추가해도 앱이 크래시하지 않고 알림함으로 폴백해야 한다.

---

## 3. 앱 구성요소

### 3.1 `lib/service/push_service.dart` (신규 · `GetxService`)

FCM 관련 부수효과를 전부 소유하는 유일한 지점. 다른 코드는 이 서비스의 메서드 3개만 안다.

| 메서드 | 동작 | 호출 지점 |
|---|---|---|
| `syncToken()` | 권한이 **이미 granted**면 `getToken()` → `POST /users/me/devices`. 아니면 no-op | `SplashController`(로그인 상태일 때), `LoginController` 로그인 성공 후 |
| `requestPermissionAndRegister()` | OS 권한 팝업 → 승인 시 `syncToken()`과 동일 등록. 거부 시 조용히 넘어감 | `OnboardingController` 제출 성공 후, `Get.offAllNamed(home)` 직전 |
| `unregister()` | `DELETE /users/me/devices/{token}` → `FirebaseMessaging.deleteToken()` | `AuthService.signOutLocal()` |

**`syncToken()`과 `requestPermissionAndRegister()`를 나눈 이유**: 재로그인 유저에게
권한 팝업을 다시 띄우면 안 되지만, 토큰 자체는 매번 갱신·등록돼야 한다. FCM 토큰은
앱 재설치·앱 데이터 삭제·장기 미사용으로 바뀐다.

서비스 초기화(`onInit`)에서 배선하는 것:
- `FirebaseMessaging.onTokenRefresh` 구독 → 서버 재등록
- `FirebaseMessaging.onMessage` 구독 → 로컬 배너 + `NotificationService.load()`
- `FirebaseMessaging.onMessageOpenedApp` 구독 → 딥링크

의존성: `ApiClient`, `AuthService`, `NotificationService`. `main.dart`에서
`Get.put(..., permanent: true)`로 등록하며, **`NotificationService` 다음**에 등록한다.

### 3.2 `lib/service/push_router.dart` (신규 · 순수 함수)

```dart
/// FCM data payload → 이동할 라우트. 알 수 없는 입력이면 알림함으로 폴백.
String routeForPush(Map<String, dynamic> data);
```

`RemoteMessage`에 의존하지 않는 순수 함수로 분리한다. 알림 타입이 늘 때마다 손댈
유일한 지점이고, Firebase 없이 단위 테스트할 수 있어야 하기 때문이다.

### 3.3 기존 파일 수정

| 파일 | 변경 |
|---|---|
| `lib/core/network/apis.dart` | `devices` = `/users/me/devices`, `device` = `/users/me/devices/{token}` |
| `lib/core/network/api_client.dart` | `registerDevice(@Body DeviceRegisterRequest)`, `unregisterDevice(@Path token)` → build_runner 재실행 |
| `lib/data/models/social_model.dart` | `DeviceRegisterRequest { token, platform }` (`FieldRename.snake`) |
| `lib/main.dart` | `Firebase.initializeApp()`, top-level `@pragma('vm:entry-point')` 백그라운드 핸들러, `Get.put(PushService(...))` |
| `lib/feature/splash/splash_controller.dart` | 라우팅 완료 **후** `getInitialMessage()` 처리 (§3.4) |
| `lib/feature/onboarding/onboarding_controller.dart` | `Get.offAllNamed(home)` 직전에 `requestPermissionAndRegister()` |
| `lib/feature/login/login_controller.dart` | 로그인 성공 후 `syncToken()` (await 하지 않음 — 로그인 흐름을 막지 않는다) |
| `lib/service/auth_service.dart` | `signOutLocal()`에서 `unregister()` (best-effort, 실패해도 로컬 세션은 지운다) |
| `lib/service/services.dart` | `export 'push_service.dart';` |

### 3.4 ⚠️ 콜드 스타트 딥링크 타이밍

앱이 완전히 종료된 상태에서 푸시를 탭하면 `getInitialMessage()`에 메시지가 담긴다.
이걸 `main()`이나 `PushService.onInit()`에서 즉시 처리하면, 뒤이어 실행되는
`SplashController._boot()`의 `Get.offAllNamed(home)`가 딥링크 목적지를 **덮어쓴다**.

따라서 `SplashController._boot()`가 목적지(`login` / `onboarding` / `home`) 라우팅을
끝낸 **뒤에** 초기 메시지를 확인하고, 있으면 그 위에 `Get.toNamed()`으로 얹는다.
`offAllNamed`가 아니라 `toNamed`인 이유는 뒤로가기로 홈에 돌아올 수 있어야 하기 때문이다.

로그인이 안 된 상태에서 푸시를 탭한 경우는 딥링크를 **버린다**. `/event/:slug`는
`RouteGuard`가 막고, 로그인 후 원래 목적지로 복원하는 기능은 지금 없다.
이 규칙은 콜드 스타트(`getInitialMessage`)와 백그라운드 복귀(`onMessageOpenedApp`)
**양쪽 모두**에 적용한다 — 두 경로는 `routeForPush()`와 같은 이동 로직을 공유한다.

---

## 4. Android 설정

### 4.1 콘솔 작업 (사람이 해야 함)

1. **서버가 쓰는 Firebase 프로젝트 ID 확인** — 앱과 서버가 같은 프로젝트여야 한다.
   다르면 발송이 에러 없이 조용히 실패한다.
2. 그 프로젝트에 Android 앱 추가 — 패키지명 `kr.octoverse.iam`
3. `google-services.json` 다운로드 → `android/app/`에 배치

### 4.2 코드 작업

- `pubspec.yaml` — `firebase_core`, `firebase_messaging`, `flutter_local_notifications`
- `android/settings.gradle.kts` — `com.google.gms.google-services` 플러그인 선언
  (버전은 §4.4에 따라 실제 빌드로 확정한다 — 지금 특정 버전을 못 박지 않는다)
- `android/app/build.gradle.kts` — 같은 플러그인 `apply`
- `AndroidManifest.xml` — `POST_NOTIFICATIONS` 권한 +
  `com.google.firebase.messaging.default_notification_channel_id` 메타데이터.
  같은 id의 채널을 `flutter_local_notifications`로 앱 시작 시 생성한다.
  (채널이 없으면 백그라운드 알림이 기본 채널로 떨어져 포그라운드 배너와 설정이 갈린다)
- `minSdk` 확인 — `firebase_messaging`이 요구하는 하한을 밑돌면 상향

**FlutterFire CLI는 쓰지 않는다.** Android 전용이므로 `google-services.json` 하나로
충분하고, `firebase_options.dart`를 생성·유지할 이유가 없다. iOS를 붙일 때 재검토한다.

### 4.3 `google-services.json`은 커밋한다

이 파일의 API 키는 **클라이언트 식별자**이지 비밀이 아니다(발송 권한을 가진 서버 키와
다르다). 커밋하지 않으면 다른 개발자·CI 빌드가 전부 깨진다.
저장소 밖에 둔 `kakao.properties`와는 성격이 다르다.

### 4.4 리스크 — AGP 9.0.1 / Kotlin 2.3.20

이 프로젝트는 AGP 9.0.1, Kotlin 2.3.20을 쓴다. 상당히 최신이라
`com.google.gms.google-services` 플러그인 및 Firebase Android SDK와 버전 충돌이
날 가능성이 있다. **1순위 리스크**로 두고, 구현은 gradle 배선 + 빈 앱 빌드 성공을
먼저 확인한 뒤 Dart 코드로 넘어간다.

충돌 시 대응 순서: ① google-services 플러그인 버전 조정 → ② Firebase BoM 버전 조정
→ ③ AGP 하향(최후수단, 다른 플러그인에 영향).

---

## 5. 에러 · 엣지 케이스

| 상황 | 동작 |
|---|---|
| 권한 거부 | 조용히 넘어간다. 토스트·다이얼로그로 재촉하지 않는다. 앱은 정상 동작하고 인앱 알림 피드는 그대로 쓴다 |
| 토큰 등록 API 실패 | 삼킨다(로그만). 다음 앱 실행의 `syncToken()`이 재시도한다. 푸시는 보조 기능이라 화면을 막지 않는다 — `NotificationService`의 기존 방침과 동일 |
| `getToken()` 실패 (Play 서비스 없음 등) | 위와 동일하게 삼킨다 |
| 로그아웃 시 `unregister()` 실패 | 로컬 세션 정리는 **반드시** 진행한다. 서버 토큰이 남으면 서버가 무효 토큰 정리로 걷어낸다 |
| 알 수 없는 `type` | 알림함으로 폴백. 크래시 금지 |
| `channel_slug` 누락 | 알림함으로 폴백 |
| 포그라운드 수신 | 로컬 배너 + `NotificationService.load()`로 벨 배지 갱신 |

---

## 6. 검증

### 자동
- `test/service/push_router_test.dart` — `routeForPush()` 매핑. 9개 타입 전부 +
  `channel_slug` 누락 + 알 수 없는 type + 빈 map

### 수동 (Firebase 콘솔 → Cloud Messaging → 테스트 메시지, 토큰 직접 입력)

확인할 상태:
1. **포그라운드** — 로컬 배너가 뜨고 벨 배지가 오르는가
2. **백그라운드** — 트레이에 뜨고, 탭하면 해당 모임 상세로 가는가
3. **완전 종료** — 트레이에 뜨고, 탭하면 스플래시를 거쳐 모임 상세로 가는가 (§3.4)
4. **권한 거부 상태** — 앱이 정상 동작하는가
5. **로그아웃 후** — 같은 기기로 푸시가 더 이상 오지 않는가

---

## 7. 이번 범위 밖

- **iOS** — APNs 키(.p8), 유료 Apple 개발자 계정, 실기기 확보 후 별도 진행
- **푸시 on/off 설정 토글** — 서버 `settings`에 `push_notification_enabled`가 필요
- **알림 읽음 서버 동기화** — 서버에 읽음 API가 생기면 `NotificationService`의
  로컬 머지를 걷어낸다
- **로그인 후 딥링크 복원** — 비로그인 상태에서 탭한 푸시의 목적지를 기억했다가
  로그인 후 이동시키는 기능
